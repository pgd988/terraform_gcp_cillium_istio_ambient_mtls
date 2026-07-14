/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Outputs for the single-cluster backbone CNI example.
 */

output "peer_authentication_mode" {
  description = "Mesh-wide mTLS enforcement mode inside istio-system."
  value       = module.istio_ambient.peer_authentication_mode
}

output "spiffe_pattern" {
  description = "SPIFFE workload identity pattern."
  value       = module.istio_ambient.spiffe_identity_pattern
}
