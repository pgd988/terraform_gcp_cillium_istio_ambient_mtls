# Single-Cluster Istio Ambient Mesh Example

This example demonstrates how to consume the `terraform-istio-ambient-zero-trust` module for a single Google Kubernetes Engine (GKE) cluster with Dataplane V2 enabled.

## Features Demonstrated
- **Ambient Profile Deployment**: Deploys `istio-base`, `istiod`, and `ztunnel` via Helm with atomic upgrades and timeout handling.
- **Namespace Enrollment**: Labels `payments`, `wallet`, and `backend` namespaces with `istio.io/dataplane-mode=ambient`.
- **Zero-Trust Security**: Enforces `STRICT` mTLS via `PeerAuthentication` across the entire mesh.
- **Identity-Based Authorization**: Configures an `AuthorizationPolicy` allowing only the `spiffe://cluster.local/ns/payments/sa/frontend` workload to access port `8080` on services in the `backend` namespace.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Validation

After applying, verify `ztunnel` status and namespace labels:
```bash
istioctl proxy-status
istioctl x ztunnel-config workloads
kubectl get peerauthentication -A
kubectl get authorizationpolicy -A
```
