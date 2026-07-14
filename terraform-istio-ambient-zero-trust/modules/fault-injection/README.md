# Standalone L7 Fault Injection Module (`modules/fault-injection`)

This dedicated Terraform submodule provisions **L7 Chaos Engineering & Fault Injection policies** targeting an Istio Waypoint Gateway (`GatewayClass: istio-waypoint`) in an **Istio Ambient Zero-Trust Mesh** on Google Kubernetes Engine (GKE).

## 1. Architectural Separation of Duties

To adhere to enterprise **Platform Engineering vs. Application GitOps separation of duties**, fault injection and application testing capabilities are decoupled from the root **CNI Backbone module (`terraform-istio-ambient-zero-trust`)**:
- **Root CNI Backbone (`/`)**: Manages *only* the mesh control plane (`istiod`), node-level L4 `ztunnel` eBPF DaemonSets, Google Secret Manager root CA synchronization, and mesh-wide `STRICT` mTLS `PeerAuthentication`.
- **Fault Injection Submodule (`modules/fault-injection`)**: Can be invoked separately in staging, QA, or chaos testing pipelines to inject artificial HTTP abort errors (e.g., `500 Internal Server Error`) or latency delays (`e.g., 3s`) via EnvoyFilter and Gateway API `HTTPRoute` rules without altering the core mesh backbone.

---

## 2. Usage Example

```hcl
module "payments_chaos_testing" {
  source = "git::https://github.com/org/terraform-istio-ambient-zero-trust.git//modules/fault-injection?ref=v1.0.0"

  enabled              = true
  name                 = "payments-fault-test"
  namespace            = "payments"
  waypoint_name        = "waypoint" # Target Waypoint Gateway (`parentRefs`)
  target_hostnames     = ["payments.payments.svc.cluster.local"]
  match_path_prefix    = "/checkout/test"
  match_headers        = { "x-chaos-test" = "enabled" }

  fault_injection_type = "BOTH"     # ABORT_HTTP_ERROR, LATENCY_DELAY, or BOTH
  abort_http_status    = 500
  abort_percentage     = 15.0       # Abort 15% of requests matching header/path
  delay_duration       = "2s"
  delay_percentage     = 25.0       # Delay 25% of requests matching header/path

  backend_service_name = "payments-service"
  backend_service_port = 8080
}
```

---

## 3. Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :---: |
| `enabled` | Whether to create the L7 fault injection resources. | `bool` | `true` | no |
| `name` | Name of the fault injection HTTPRoute or configuration. | `string` | `"l7-fault-injection"` | no |
| `namespace` | Target application namespace where the L7 Waypoint and workloads reside. | `string` | n/a | yes |
| `waypoint_name` | Name of the parent Waypoint Gateway (`parentRefs.name`) intercepting L7 traffic. | `string` | `"waypoint"` | no |
| `target_hostnames` | List of target hostnames intercepted by this policy. | `list(string)` | n/a | yes |
| `match_path_prefix` | Path prefix to match for applying fault injection. | `string` | `"/"` | no |
| `match_headers` | Optional map of exact HTTP request headers required to trigger fault injection. | `map(string)` | `{}` | no |
| `fault_injection_type` | Type of fault to inject: `ABORT_HTTP_ERROR`, `LATENCY_DELAY`, or `BOTH`. | `string` | `"ABORT_HTTP_ERROR"` | no |
| `abort_http_status` | HTTP status code to return when `ABORT_HTTP_ERROR` or `BOTH` is triggered. | `number` | `500` | no |
| `abort_percentage` | Percentage of matching requests (0.0 to 100.0) receiving the HTTP abort error. | `number` | `10.0` | no |
| `delay_duration` | Fixed delay duration string (`5s`, `500ms`) when `LATENCY_DELAY` or `BOTH` is triggered. | `string` | `"3s"` | no |
| `delay_percentage` | Percentage of matching requests (0.0 to 100.0) experiencing the latency delay. | `number` | `20.0` | no |
| `backend_service_name` | Name of target backend service where non-aborted/delayed traffic is routed. | `string` | n/a | yes |
| `backend_service_port` | Port number of target backend service. | `number` | `8080` | no |

---

## 4. Outputs

| Name | Description |
| :--- | :--- |
| `envoy_filter_name` | The name of the created EnvoyFilter attaching fault injection to the Waypoint Gateway. |
| `http_route_name` | The name of the created Gateway API HTTPRoute governing the fault injection routing rules. |
| `fault_type_applied` | The configured fault injection mode (`ABORT_HTTP_ERROR`, `LATENCY_DELAY`, or `BOTH`). |
