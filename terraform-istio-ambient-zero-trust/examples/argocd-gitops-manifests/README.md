# ArgoCD GitOps Application Manifests Example (`istio-ambient-gitops`)

In accordance with modern platform engineering and GitOps separation of duties:
1. **Infrastructure Repository (`terraform-istio-ambient-zero-trust`)**: Manages ONLY the **basic backbone CNI structure** and Istio Control Plane (`istio-base`, `istiod`, `ztunnel` eBPF/CNI DaemonSet, root CA / Secret Manager synchronization, and mesh-wide default `PeerAuthentication` inside `istio-system`).
2. **ArgoCD GitOps Repository (`this directory`)**: Manages **application-level microservice configurations**, including `Namespace` Ambient mode enrollments (`istio.io/dataplane-mode: ambient`), ServiceAccounts, L7 `Waypoint` Gateways (`istio-waypoint`), `HTTPRoute` L7 traffic routing rules, and `AuthorizationPolicy` zero-trust access rules.

---

## Folder Structure

```text
examples/argocd-gitops-manifests/
├── 01-namespace-ambient-enrollment.yaml # Enrolls business namespaces into Ambient eBPF data plane
├── 02-waypoint-gateway.yaml             # Deploys Gateway API L7 Waypoint proxies (`istio-waypoint`)
├── 03-waypoint-enrollment.yaml          # Enrolls Namespaces or ServiceAccounts to use Waypoint
├── 04-l7-http-route.yaml                # Defines L7 HTTPRoute rules (path routing, timeouts, retries)
├── 05-authorization-policy.yaml         # Enforces SPIFFE workload identity access policies (`ALLOW`/`DENY`)
└── 06-l7-fault-injection.yaml           # Demonstrates L7 Chaos Engineering & Fault Injection on Waypoint
```

---

## 1. How ArgoCD Synchronizes with the Backbone CNI

Once Terraform has provisioned the `ztunnel` eBPF DaemonSet across the GKE Dataplane V2 nodes, any application pod deployed into a namespace labeled with `istio.io/dataplane-mode: ambient` will **immediately and transparently** have its TCP sockets intercepted and encapsulated inside **HBONE mTLS tunnels**.

ArgoCD monitors your application GitOps repository and applies these manifests in order:

1. **Namespace Creation & Enrollment** (`01-namespace-ambient-enrollment.yaml`)
   - Applies the label `istio.io/dataplane-mode: ambient` on target namespaces (e.g., `payments`, `backend`).
   - > [!WARNING]
   > Do **NOT** apply `istio-injection=enabled`. Ambient mode uses eBPF/CNI redirection and does not require Envoy sidecar injection.

2. **Waypoint Gateway Provisioning** (`02-waypoint-gateway.yaml` & `03-waypoint-enrollment.yaml`)
   - When L7 processing (retries, timeouts, HTTP header routing, JWT validation) is needed, ArgoCD deploys a `Gateway` resource with `gatewayClassName: istio-waypoint`.
   - Attaches `istio.io/use-waypoint: <gateway-name>` either at the `Namespace` level or on a specific `ServiceAccount`.

3. **L7 HTTPRoute Traffic Policies** (`04-l7-http-route.yaml`)
   - Applies Kubernetes Gateway API `HTTPRoute` objects attached (`parentRefs`) to the Waypoint Gateway to execute L7 routing.

4. **Zero-Trust SPIFFE Access Control** (`05-authorization-policy.yaml`)
   - Enforces cryptographic `AuthorizationPolicy` manifests matching the caller's verified SPIFFE identity (`spiffe://<trust_domain>/ns/<namespace>/sa/<service_account>`).
