/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Outputs from the multi-cluster sub-module (`multicluster/`).
 */

output "east_west_gateway_release" {
  description = "Name of the East-West Gateway Helm release."
  value       = helm_release.east_west_gateway.name
}

output "remote_clusters_configured" {
  description = "List of remote cluster names successfully registered with `istio/multiCluster=true` secrets."
  value       = keys(kubernetes_secret_v1.remote_cluster)
}

output "trust_bundle_secret_status" {
  description = "Whether the ExternalSecret (`istio-ca-external-secret`) for CA synchronization from GSM is enabled."
  value       = var.trust_bundle_secret.enabled
}
