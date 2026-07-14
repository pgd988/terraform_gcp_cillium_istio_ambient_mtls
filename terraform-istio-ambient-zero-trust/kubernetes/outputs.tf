/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Outputs from the Kubernetes backbone resources sub-module (`kubernetes/`).
 */

output "peer_authentication_mode" {
  description = "Mesh default PeerAuthentication mode applied inside istio-system."
  value       = var.enable_strict_mtls ? "STRICT" : "PERMISSIVE"
}
