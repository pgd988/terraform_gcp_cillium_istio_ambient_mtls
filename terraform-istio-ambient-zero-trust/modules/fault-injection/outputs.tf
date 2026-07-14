/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Outputs for the Fault Injection submodule (`modules/fault-injection`).
 */

output "envoy_filter_name" {
  description = "The name of the created EnvoyFilter attaching fault injection to the Waypoint Gateway."
  value       = try(kubernetes_manifest.waypoint_fault_injection_filter[0].manifest.metadata.name, null)
}

output "http_route_name" {
  description = "The name of the created Gateway API HTTPRoute governing the fault injection routing rules."
  value       = try(kubernetes_manifest.fault_injection_http_route[0].manifest.metadata.name, null)
}

output "fault_type_applied" {
  description = "The configured fault injection mode (`ABORT_HTTP_ERROR`, `LATENCY_DELAY`, or `BOTH`)."
  value       = var.enabled ? var.fault_injection_type : "disabled"
}
