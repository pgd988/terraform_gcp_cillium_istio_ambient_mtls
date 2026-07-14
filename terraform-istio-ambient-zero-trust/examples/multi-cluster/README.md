# Multi-Cluster Istio Ambient Mesh Example

This example demonstrates enabling `enable_multicluster = true` on the `terraform-istio-ambient-zero-trust` module to peer multiple GKE clusters (`prod-eu` + `prod-us`) across different VPC networks (`vpc-prod-eu` and `vpc-prod-us`) that intentionally share a common SPIFFE trust domain (`prod.global.local`).

## Features Demonstrated
- **Shared CA Synchronization**: Uses External Secrets Operator (ESO) to pull `istio-ca-root` from Google Secret Manager into the `cacerts` Kubernetes Secret.
- **East-West Gateway**: Deploys a dedicated `istio-eastwestgateway` LoadBalancer Service listening on port `15443` (`AUTO_PASSTHROUGH` SNI-DNAT mode) for secure cross-network mTLS tunnels.
- **Remote Cluster Discovery**: Registers a Kubernetes Secret labeled `istio/multiCluster=true` allowing `istiod` to discover remote workloads across clusters.

## Usage

Define your remote cluster credentials (`terraform.tfvars` or environment variables):
```hcl
remote_prod_us_api_endpoint = "https://34.123.45.67"
remote_prod_us_ca_base64    = "LS0tLS1CRUdJ..."
remote_prod_us_sa_token     = "eyJhbGciOi..."
```

Run Terraform:
```bash
terraform init
terraform plan
terraform apply
```

## Validation

Verify East-West Gateway load balancer IP and multi-cluster routing:
```bash
istioctl proxy-status
istioctl remote-clusters
kubectl get svc -n istio-system istio-eastwestgateway
```
