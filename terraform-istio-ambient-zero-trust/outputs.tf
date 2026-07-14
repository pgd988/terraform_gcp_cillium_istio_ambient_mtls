/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Output values from the root Istio Ambient module.
 */

output "istio_version" {
  description = "The Istio Helm chart and components version deployed across the cluster."
  value       = var.istio_version
}

output "istio_namespace" {
  description = "The Kubernetes namespace hosting the Istio control plane (istiod, ztunnel)."
  value       = var.namespace
}

output "ztunnel_release_status" {
  description = "Status of the deployed ztunnel L4 eBPF/socket redirection DaemonSet Helm release."
  value       = try(helm_release.ztunnel[0].status, "disabled")
}

output "istiod_release_status" {
  description = "Status of the deployed istiod Control Plane Helm release."
  value       = try(helm_release.istiod[0].status, "disabled")
}

output "spiffe_identity_pattern" {
  description = "Template pattern showing how SPIFFE identities are constructed for workload ServiceAccounts (`spiffe://<trust_domain>/ns/<ns>/sa/<sa>`)."
  value       = local.spiffe_identity_pattern
}

output "multicluster_enabled" {
  description = "Boolean indicating whether multi-cluster East-West mTLS routing is active."
  value       = var.enable_multicluster
}

output "east_west_gateway_release" {
  description = "Name of the East-West Gateway Helm release if multi-cluster mode is enabled."
  value       = try(module.multicluster[0].east_west_gateway_release, null)
}

output "peer_authentication_mode" {
  description = "The mesh-wide PeerAuthentication mTLS enforcement mode (`STRICT` or `PERMISSIVE`) inside istio-system."
  value       = try(module.kubernetes[0].peer_authentication_mode, "disabled")
}
