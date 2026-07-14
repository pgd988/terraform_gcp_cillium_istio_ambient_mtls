# Production-Grade Istio Ambient Mesh Zero-Trust Terraform Module for Google Kubernetes Engine (GKE)

This repository provides a HashiCorp-certified, production-ready, and modular Terraform implementation for deploying **Istio Ambient Mesh** as an optional, composable zero-trust security architecture on **Google Kubernetes Engine (GKE)**.

The module is specifically designed to interoperate seamlessly with GKE's modern platform capabilities, including **GKE Dataplane V2** (Cilium eBPF), **VPC-native networking**, **Workload Identity**, **Google Secret Manager (GSM)**, **External Secrets Operator (ESO)**, and **Google Cloud Managed Service for Prometheus (GMP)**.

---

## 1. Architecture Diagram

The following diagram illustrates how Istio Ambient Mode (`ztunnel` L4 eBPF redirection + optional `istio-waypoint` L7 proxies) integrates with GKE Dataplane V2 and external Google Cloud platform services across single or multi-cluster environments:

```mermaid
graph TD
    subgraph GCP["Google Cloud Platform Layer"]
        GSM["Google Secret Manager (GSM)<br>Root CA Trust Store"]
        GMP["Google Cloud Managed Prometheus (GMP)<br>15020 & 15090 Scraping"]
        WI["GKE Workload Identity<br>IAM Role Bindings"]
    end

    subgraph ClusterA["GKE Standard Cluster A (e.g., prod-eu / Dataplane V2 / Cilium eBPF)"]
        subgraph ControlPlane["Namespace: istio-system"]
            ESO["External Secrets Operator (ESO)<br>ClusterSecretStore"]
            IstioBase["istio-base Chart<br>Ambient CRDs"]
            Istiod["istiod Chart (Control Plane)<br>Profile: ambient / XDS & SDS"]
            CASecret["cacerts Secret<br>Synced via ESO from GSM"]
            EWG["East-West Gateway Service<br>LoadBalancer (15443 SNI-DNAT)"]
        end

        subgraph DataPlane["eBPF Socket Redirection Layer"]
            ZtunnelA["ztunnel DaemonSet Pods<br>HostNetwork / CAP_NET_ADMIN / eBPF Socket Redirection"]
        end

        subgraph WorkloadNS["Enrolled Namespace: payments (istio.io/dataplane-mode: ambient)"]
            AppPayments["Frontend Pod<br>SA: frontend"]
            AppWallet["Wallet Pod<br>SA: wallet"]
            AuthZ["AuthorizationPolicy<br>SPIFFE Principal Verification"]
            PeerAuth["PeerAuthentication<br>Mode: STRICT mTLS"]
        end
    end

    subgraph ClusterB["GKE Standard Cluster B (e.g., prod-us / Dataplane V2 / Cilium eBPF)"]
        subgraph ClusterBNS["Namespace: backend (istio.io/dataplane-mode: ambient)"]
            AppBackend["Backend Service Pod<br>SA: backend"]
            WaypointB["Optional Waypoint Proxy<br>Gateway API (L7 Routing / JWT)"]
        end
        ZtunnelB["ztunnel DaemonSet Pods<br>Cluster B"]
        EWGB["East-West Gateway Service<br>Cluster B LoadBalancer"]
    end

    %% Sync flows
    GSM -->|Polls Root CA every 1h| ESO
    ESO -->|Creates / Updates| CASecret
    CASecret -->|inotify SDS Reload| Istiod
    Istiod -->|SDS Workload mTLS Certs| ZtunnelA
    Istiod -->|XDS HBONE Routes| ZtunnelA
    WI -->|ServiceAccount IAM Mapping| Istiod

    %% Traffic flows
    AppPayments -->|Plaintext Socket Intercepted by eBPF| ZtunnelA
    ZtunnelA -->|HBONE / mTLS / SPIFFE ID Encapsulation| ZtunnelA
    ZtunnelA -->|Cross-Network HBONE mTLS Tunnel (15443)| EWG
    EWG -->|SNI Passthrough over VPC| EWGB
    EWGB -->|XDS Routing| ZtunnelB
    ZtunnelB -->|L7 Authorization Check| WaypointB
    WaypointB -->|Verified L4 Socket Delivery| AppBackend

    %% Telemetry
    ZtunnelA -.->|Prometheus Metrics Scraping| GMP
    Istiod -.->|Control Plane Metrics| GMP
```

---

## 2. Deployment Workflow

### Prerequisites
1. **GKE Standard Cluster**: Provisioned with Dataplane V2 (`enable_dataplane_v2 = true`) and VPC-native networking (`ip_allocation_policy` enabled).
2. **Workload Identity Enabled**: The cluster must have `workload_identity_config` bound to your GCP project (`<project-id>.svc.id.goog`).
3. **External Secrets Operator (ESO)**: Pre-installed in the cluster to manage certificate rotation (`helm install external-secrets external-secrets/external-secrets`).
4. **Google Secret Manager (GSM)**: A secret named `istio-ca-root` containing keys (`ca-cert.pem`, `ca-key.pem`, `root-cert.pem`, `cert-chain.pem`) accessible via Workload Identity.
5. **Google Cloud Managed Service for Prometheus**: Enabled (`monitoring_config.managed_prometheus.enabled = true`).

### Module Application Workflow
To consume this module inside your platform repository:

```hcl
module "istio_ambient" {
  source = "git::https://github.com/org/terraform-istio-ambient-zero-trust.git?ref=v1.0.0"

  enable             = true
  istio_version      = "1.22.1"
  namespace          = "istio-system"
  enable_ambient     = true
  enable_strict_mtls = true

  ambient_namespaces = [
    "payments",
    "wallet",
    "backend"
  ]

  # Optional multi-cluster East-West peering
  enable_multicluster = false
}
```

Run Terraform deployment:
```bash
terraform init
terraform plan -out=ambient.tfplan
terraform apply ambient.tfplan
```

---

## 3. Security Model Explanation

### Ambient Zero-Trust Separation of Powers (L4 vs. L7)
In standard Istio sidecar architectures (`istio-injection=enabled`), every application pod runs a dedicated Envoy proxy sidecar container. This doubles resource consumption and requires application pod restarts whenever the mesh proxy is upgraded.

**Istio Ambient Mode** cleanly separates L4 zero-trust encryption from L7 application routing:

1. **L4 Zero-Trust (`ztunnel`)**:
   - Deployed as a secure, privileged node-level `DaemonSet` (`ztunnel`) on every node.
   - Using GKE Dataplane V2 (Cilium eBPF/CNI socket redirection), when an application pod initiates a TCP connection, `ztunnel` transparently intercepts the socket at the Linux kernel level.
   - `ztunnel` encapsulates the traffic into **HBONE (HTTP-Based Overlay Network Environment)** tunnels wrapped in **STRICT mTLS**.
   - Every connection is authenticated using cryptographic **SPIFFE workload identities**.
   - Because `ztunnel` operates outside application pods, updating or restarting `ztunnel` does not restart or disrupt application workloads.

2. **L7 Waypoint Proxies (`istio-waypoint`)**:
   - Optional L7 Envoy proxies deployed dynamically per namespace or per ServiceAccount using the **Kubernetes Gateway API (`GatewayClass: istio-waypoint`)**.
   - When an application requires L7 features (e.g., HTTP path routing, header-based routing, JWT token validation, or retry/timeout policies), `ztunnel` automatically routes the L4 tunnel through the designated Waypoint proxy before delivering it to the destination pod.

### Default Deny Baseline
The module enforces a **Default Deny All** security posture:
- Whenever `enable_strict_mtls = true` is active, root `PeerAuthentication` enforces `STRICT` mode (`security.istio.io/v1`).
- If no custom `authorization_policies` are supplied, the module generates a `default-deny-all` `AuthorizationPolicy` across every enrolled namespace.
- No service can communicate with another service until an explicit `ALLOW` policy matching the source ServiceAccount's SPIFFE ID is applied.

---

## 4. mTLS Certificate Lifecycle & Rotation

### Zero-Downtime Certificate Rotation Architecture
The module eliminates static, hardcoded CA certificates stored in Terraform state or Git repositories by integrating **Google Secret Manager (GSM)** with the **External Secrets Operator (ESO)**:

1. **Root CA Storage**: The organization's root CA trust bundle is stored inside Google Secret Manager (`istio-ca-root`). Access is restricted via IAM to the cluster's Workload Identity ServiceAccount (`external-secrets-operator`).
2. **Automated Polling**: The module deploys an `ExternalSecret` custom resource (`external-secrets.io/v1beta1`) inside `istio-system` configured with `refreshInterval: 1h`.
3. **Secret Synchronization**: ESO periodically pulls the latest `ca-cert.pem`, `ca-key.pem`, `root-cert.pem`, and `cert-chain.pem` from GSM and writes them into the Kubernetes Secret `cacerts` inside `istio-system`.
4. **Control Plane Reloading**: `istiod` monitors the `cacerts` secret filesystem mount using Linux `inotify`. Whenever ESO rotates the secret, `istiod` reloads the intermediate CA signing keys dynamically in memory without restarting any `istiod` pods.
5. **Workload Certificate SDS Issuance**: `istiod` pushes updated, short-lived SPIFFE workload certificates (default TTL: 24 hours) to all `ztunnel` DaemonSet instances across the cluster via the **Secret Discovery Service (SDS)**.
6. **Seamless Tunnel Transition**: `ztunnel` automatically negotiates new mTLS handshakes for subsequent connections using the rotated certificates without interrupting active L4 eBPF sockets.

---

## 5. Application Namespace Onboarding & ArgoCD GitOps

In accordance with platform engineering separation of duties:
- **Terraform Module (`this repository`)**: Manages ONLY the **basic backbone CNI structure** and Istio Control Plane (`istio-base`, `istiod`, `ztunnel` eBPF/CNI DaemonSet, root CA / Secret Manager synchronization, and mesh-wide default `PeerAuthentication` inside `istio-system`).
- **ArgoCD GitOps Repository (`your application repository`)**: Manages **application-level microservice configurations**, including `Namespace` Ambient mode enrollments (`istio.io/dataplane-mode: ambient`), ServiceAccounts, L7 `Waypoint` Gateways (`istio-waypoint`), `HTTPRoute` L7 traffic routing rules, and `AuthorizationPolicy` zero-trust access rules.

### Enrolling a Namespace via ArgoCD
To enroll a new application namespace into the zero-trust Ambient Mesh without modifying Terraform state, create a Kubernetes `Namespace` manifest with the `istio.io/dataplane-mode: ambient` label inside your ArgoCD repository:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: orders
  labels:
    # Enrolls namespace into Istio Ambient eBPF/ztunnel L4 socket redirection
    istio.io/dataplane-mode: ambient
```

> [!WARNING]
> Do **NOT** apply `istio-injection=enabled` on namespaces enrolled in Ambient mode (`istio.io/dataplane-mode: ambient`). If both labels are applied, Istio will attempt to inject Envoy sidecar proxies alongside `ztunnel` socket redirection, leading to network loops or Dataplane V2 port conflicts.

---

## 6. L7 Traffic Routing & Waypoint Configuration via ArgoCD

While `ztunnel` provides high-performance L4 zero-trust mTLS encryption across the mesh, certain workloads require L7 traffic interception (HTTP path-based routing, header matching, retries, timeouts, fault injection, and JWT validation). Rather than managing dynamic application routes in infrastructure Terraform, these are managed via Kubernetes Gateway API manifests in your ArgoCD GitOps repository.

### Ready-to-Use ArgoCD Manifest Examples
We have provided comprehensive, production-ready YAML manifests demonstrating exact structures for:
1. **Namespace Ambient Enrollment** (`01-namespace-ambient-enrollment.yaml`)
2. **Waypoint Gateway Deployments** (`02-waypoint-gateway.yaml`)
3. **Waypoint Enrollments on Namespaces & ServiceAccounts** (`03-waypoint-enrollment.yaml`)
4. **L7 HTTPRoute Traffic Routing & Retries** (`04-l7-http-route.yaml`)
5. **Zero-Trust SPIFFE AuthorizationPolicies** (`05-authorization-policy.yaml`)

Please review and copy directly from our dedicated GitOps examples folder:
👉 **[`./examples/argocd-gitops-manifests/`](file:///Users/pgd988/den/chrono_repos/tmp/terraform_gcp_cillium_istio_ambient_mtls/terraform-istio-ambient-zero-trust/examples/argocd-gitops-manifests/README.md)**

---

## 7. Multi-Cluster Setup Procedure

Multi-cluster Ambient Mesh (`enable_multicluster = true`) is an advanced capability that enables zero-trust mTLS service-to-service communication across independent GKE clusters residing in different VPC networks or GCP regions.

### Architectural Maturity Recommendation
As illustrated in our examples, **keep multi-cluster disabled by default (`enable_multicluster = false`)** for standalone or non-peered clusters. Only enable `enable_multicluster = true` for clusters that are intentionally part of the same shared **Trust Domain** (e.g., `prod.global.local` shared across `prod-eu` and `prod-us`).

### Setup Steps for Cluster A (`prod-eu`) and Cluster B (`prod-us`)

1. **Synchronize Trust Domain & Root CA**:
   Ensure both clusters configure identical `trust_domain = "prod.global.local"` and point their `trust_bundle_secret` to the exact same Google Secret Manager root CA ID (`istio-ca-root`).

2. **Assign Unique Cluster IDs and Networks**:
   Each cluster must declare a distinct `cluster_id` and `network`:
   - Cluster A: `cluster_id = "prod-eu"`, `network = "vpc-prod-eu"`
   - Cluster B: `cluster_id = "prod-us"`, `network = "vpc-prod-us"`

3. **Deploy East-West Gateways**:
   Set `enable_multicluster = true`. The module automatically deploys the `istio-eastwestgateway` LoadBalancer Service and applies the `cross-network-gateway` passthrough `Gateway` resource listening on port `15443` with `AUTO_PASSTHROUGH` TLS mode.

4. **Exchange Endpoint Secrets**:
   Extract the API server endpoint and CA certificate from each cluster, and pass them into the peer's `remote_clusters` variable map:
   ```hcl
   remote_clusters = {
     "prod-us" = {
       cluster_name          = "prod-us"
       api_server_endpoint   = "https://34.123.45.67"
       ca_crt_base64         = "LS0tLS1CRUdJ..."
       service_account_token = "eyJhbGciOi..."
     }
   }
   ```
   The module registers Kubernetes Secrets labeled `istio/multiCluster=true` inside `istio-system`. `istiod` uses this kubeconfig to discover remote pods and configure `ztunnel` to tunnel cross-cluster requests over SNI-DNAT via the East-West Gateway.

---

## 7. Disaster Recovery Considerations

### Control Plane Failure Resiliency
- If all `istiod` control plane pods fail or become temporarily unavailable during a GKE node pool crash, **active L4 eBPF data plane traffic (`ztunnel`) continues flowing without interruption**.
- `ztunnel` instances cache all active XDS routing tables and valid workload mTLS certificates in local memory. Existing connections and newly initiated connections between known pods remain fully encrypted and functional until certificates reach their natural TTL expiration.

### Data Plane Resiliency & Rollback Strategies
- `ztunnel` is scheduled as a `DaemonSet` on every Linux node using `nodeSelector` and `tolerations` (`operator: Exists`). If a `ztunnel` pod crashes on a node, Dataplane V2 / Cilium CNI immediately drops connections initiated on that node until `ztunnel` recovers (normally within 3–5 seconds via kubelet restart).
- **Automated Rollbacks**: All Helm releases (`istio-base`, `istiod`, `ztunnel`) are configured with `atomic = true` and `cleanup_on_fail = true`. If a bad chart release or misconfigured override causes readiness probes to fail within the configurable timeout (`var.helm_config.timeout`, default 600s), Terraform automatically rolls back the Kubernetes resources to the last successful release state without human intervention.

---

## 8. Upgrade Procedure

### Zero-Downtime Atomic Helm Upgrades
To upgrade Istio Ambient Mesh from one minor version to another (e.g., `1.22.1` -> `1.23.0`):

1. **Update `istio_version` Variable**:
   In your root platform environment file (`main.tf` or `.tfvars`), update the version:
   ```hcl
   istio_version = "1.23.0"
   ```

2. **Execute Terraform Plan**:
   Review the exact diffs across CRDs, `istiod`, and `ztunnel`:
   ```bash
   terraform plan
   ```

3. **Apply Upgrades in Dependency Order**:
   The module enforces strict dependency chaining (`istio-base` -> `istiod` -> `ztunnel` -> `kubernetes` manifests). When you run:
   ```bash
   terraform apply
   ```
   - `istio-base` updates all CRDs atomically first.
   - `istiod` performs a rolling upgrade (`rollingMaxSurge: 100%`, `podDisruptionBudget: minAvailable 1`) to ensure control plane continuity.
   - `ztunnel` performs a rolling update node-by-node across the `DaemonSet`. As `ztunnel` restarts on a node, open sockets briefly re-handshake without dropping cluster-wide availability.

---

## 9. Troubleshooting

### Common GKE Dataplane V2 / CNI Coexistence Issues

| Symptom | Root Cause | Resolution |
| :--- | :--- | :--- |
| **`ztunnel` pods stuck in `CrashLoopBackOff` or reporting permission errors opening netns** | Missing Linux capabilities or non-host network context. | Ensure `ztunnel-values.yaml.tpl` maintains `securityContext.privileged: true` and capabilities `NET_ADMIN`, `SYS_ADMIN`, `NET_RAW` so `ztunnel` can inspect and redirect socket file descriptors alongside Cilium eBPF. |
| **Application pods in ambient namespace cannot reach external internet (DNS timeouts)** | `ztunnel` intercepting UDP DNS (`:53`) or missing external pass-through rule. | Verify `istiod` `meshConfig` allows `OUTBOUND_TRAFFIC_POLICY: ALLOW_ANY` or ensure proper `AuthorizationPolicy` egress rules exist. Check `ztunnel` logs for `istio.io/dataplane-mode=ambient` CNI redirection errors. |
| **Cross-cluster mTLS handshake failures (`503 UC` / SSL errors)** | Mismatched `trust_domain` or East-West Gateway port 15443 blocked by GKE VPC firewall. | Verify both clusters share the same `trust_domain` (`cluster.local` vs custom DNS). Check GCP VPC firewall rules to confirm port `15443` (`TCP`) is allowed across East-West Gateway load balancers. |

---

## 10. Validation Commands & Connectivity Tests

> [!IMPORTANT]
> The commands below are provided strictly for **post-deployment verification** by platform engineers or CI/CD pipelines.

### Control Plane & ztunnel Diagnostics
```bash
# Check control plane synchronization status across all ztunnel DaemonSet pods
istioctl proxy-status

# Dump active XDS workload configurations and mTLS state currently tracked by ztunnel
istioctl x ztunnel-config workloads

# Verify all ztunnel DaemonSet pods are running and healthy on every node
kubectl get ztunnel -n istio-system

# Inspect all mesh-wide and namespace-level PeerAuthentication mTLS enforcement policies
kubectl get peerauthentication -A

# Inspect all active identity-based AuthorizationPolicies across all namespaces
kubectl get authorizationpolicy -A
```

### Connectivity Verification Tests

#### 1. Service-to-Service mTLS Validation (Within Namespace)
Deploy two test pods (`curl-client` and `httpbin`) into the `payments` ambient namespace and verify mTLS encapsulation:
```bash
# Test HTTP GET from payments/curl-client to payments/httpbin
kubectl exec -n payments -c curl curl-client -- curl -s -I -w "%{http_code}\n" http://httpbin.payments.svc.cluster.local:8000/headers

# Inspect ztunnel access logs on the host node to verify HBONE mTLS encryption was applied
kubectl logs -n istio-system -l app=ztunnel --tail=50 | grep "payments/httpbin"
```

#### 2. Cross-Namespace SPIFFE Identity Validation
Test strict identity verification by executing requests between enrolled namespaces (`payments` -> `backend`) vs un-enrolled namespaces (`default` -> `backend`):
```bash
# Authorized cross-namespace request from payments (SA: frontend) to backend (SA: backend)
kubectl exec -n payments -c curl frontend-pod -- curl -s -o /dev/null -w "%{http_code}\n" http://backend.backend.svc.cluster.local:8080/healthz
# Expected Output: 200

# Unauthorized request from un-enrolled default namespace (should be blocked by default-deny / PeerAuth)
kubectl run -i --rm --restart=Never test-unauthorized --image=curlimages/curl -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 http://backend.backend.svc.cluster.local:8080/healthz
# Expected Output: 000 (Connection refused/dropped by ztunnel due to lack of valid SPIFFE HBONE tunnel)
```

#### 3. Cross-Cluster East-West Validation
Verify cross-cluster mTLS tunneling from `Cluster A` (`prod-eu`) to `Cluster B` (`prod-us`):
```bash
# Execute request from prod-eu frontend pod to prod-us database/backend service
kubectl exec --context=gke_prod-eu -n payments -c curl frontend-pod -- curl -s -o /dev/null -w "%{http_code}\n" http://backend.backend.svc.prod.global.local:8080/status

# Verify East-West Gateway traffic metrics across port 15443 on Cluster B
kubectl logs --context=gke_prod-us -n istio-system -l istio=istio-eastwestgateway --tail=50 | grep ":15443"
```
