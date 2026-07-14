/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Standalone Fault Injection submodule (`modules/fault-injection`).
 *
 * This module provisions L7 chaos engineering and fault injection policies targeting an
 * Istio Waypoint Gateway (`GatewayClass: istio-waypoint`) in an Ambient Mesh namespace.
 * It injects configurable HTTP status aborts (e.g., HTTP 500) and artificial latency delays
 * via EnvoyFilter and Gateway API HTTPRoute rules.
 */

locals {
  common_labels = merge(
    {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "istio-ambient-fault-injection"
      "istio.io/component"           = "waypoint-fault-injection"
    },
    var.labels
  )

  # Convert match_headers map to HTTPRoute header matching list
  header_matches = [
    for k, v in var.match_headers : {
      type  = "Exact"
      name  = k
      value = v
    }
  ]

  # Determine if abort fault is active
  enable_abort = var.enabled && contains(["ABORT_HTTP_ERROR", "BOTH"], var.fault_injection_type)
  # Determine if delay fault is active
  enable_delay = var.enabled && contains(["LATENCY_DELAY", "BOTH"], var.fault_injection_type)
}

# 1. Istio EnvoyFilter on Waypoint Gateway for exact HTTP Abort / Latency Fault Injection
# In Istio Ambient Mode, Waypoint Gateways run standard Envoy proxies. Attaching an EnvoyFilter
# directly to the Waypoint Gateway deployment enables deterministic L7 chaos injection.
resource "kubernetes_manifest" "waypoint_fault_injection_filter" {
  count = var.enabled ? 1 : 0

  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "EnvoyFilter"
    metadata = {
      name      = "${var.name}-filter"
      namespace = var.namespace
      labels    = local.common_labels
    }
    spec = {
      # Target the specific Waypoint Gateway deployment in this namespace
      workloadSelector = {
        labels = {
          "gateway.networking.k8s.io/gateway-name" = var.waypoint_name
        }
      }
      configPatches = [
        {
          applyTo = "HTTP_FILTER"
          match = {
            context = "GATEWAY"
            listener = {
              filterChain = {
                filter = {
                  name = "envoy.filters.network.http_connection_manager"
                }
              }
            }
          }
          patch = {
            operation = "INSERT_BEFORE"
            value = {
              name = "envoy.filters.http.fault"
              typed_config = {
                "@type" = "type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault"
                abort = local.enable_abort ? {
                  http_status = var.abort_http_status
                  percentage = {
                    numerator   = round(var.abort_percentage * 100)
                    denominator = "TEN_THOUSAND"
                  }
                } : null
                delay = local.enable_delay ? {
                  fixed_delay = var.delay_duration
                  percentage = {
                    numerator   = round(var.delay_percentage * 100)
                    denominator = "TEN_THOUSAND"
                  }
                } : null
              }
            }
          }
        }
      ]
    }
  }

  field_manager {
    force_conflicts = true
  }
}

# 2. Gateway API HTTPRoute with chaos test header matches and backend routing
resource "kubernetes_manifest" "fault_injection_http_route" {
  count = var.enabled ? 1 : 0

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "${var.name}-route"
      namespace = var.namespace
      labels    = local.common_labels
    }
    spec = {
      parentRefs = [
        {
          name      = var.waypoint_name
          namespace = var.namespace
        }
      ]
      hostnames = var.target_hostnames
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = var.match_path_prefix
              }
              headers = length(local.header_matches) > 0 ? local.header_matches : null
            }
          ]
          timeouts = {
            request = "10s"
          }
          backendRefs = [
            {
              name   = var.backend_service_name
              port   = var.backend_service_port
              weight = 100
            }
          ]
        }
      ]
    }
  }

  field_manager {
    force_conflicts = true
  }
}
