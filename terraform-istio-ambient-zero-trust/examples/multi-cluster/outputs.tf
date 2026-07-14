/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Outputs for the multi-cluster example.
 */

output "east_west_gateway_release" {
  description = "East-West Gateway release name."
  value       = module.istio_ambient_prod_eu.east_west_gateway_release
}

output "multicluster_enabled" {
  description = "Whether multi-cluster is enabled."
  value       = module.istio_ambient_prod_eu.multicluster_enabled
}
