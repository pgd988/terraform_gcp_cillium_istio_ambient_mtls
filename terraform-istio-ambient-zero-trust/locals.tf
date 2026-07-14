/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Local values and computed expressions for Istio Ambient configuration on GKE.
 */

locals {
  # Standard SPIFFE identity formatting pattern for ServiceAccounts in this trust domain
  spiffe_identity_pattern = "spiffe://${var.trust_domain}/ns/%s/sa/%s"

  # Standard common tags/labels applied across resources managed by this module
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "istio-ambient-zero-trust"
    "istio.io/rev"                 = "default"
  }

  # Dataplane V2 / Cilium eBPF compatibility metadata
  # Dataplane V2 uses Cilium underneath. ztunnel runs in ambient mode and redirects traffic
  # via eBPF/CNI sockets. We ensure exact environment and metadata flags are passed.
  dataplane_metadata = {
    ISTIO_META_DATAPLANE_MODE   = "ambient"
    PILOT_ENABLE_AMBIENT        = "true"
    PILOT_ENABLE_ZTUNNEL_SOCKET = "true"
  }

  # Rendered Helm values from templates
  istio_base_values = templatefile("${path.module}/helm/istio-base-values.yaml.tpl", {
    istio_namespace = var.namespace
    enable_ambient  = var.enable_ambient
  })

  istiod_values = templatefile("${path.module}/helm/istiod-values.yaml.tpl", {
    istio_namespace   = var.namespace
    trust_domain      = var.trust_domain
    enable_ambient    = var.enable_ambient
    enable_telemetry  = var.enable_telemetry
    enable_prometheus = var.enable_prometheus
  })

  ztunnel_values = templatefile("${path.module}/helm/ztunnel-values.yaml.tpl", {
    istio_namespace   = var.namespace
    trust_domain      = var.trust_domain
    enable_telemetry  = var.enable_telemetry
    enable_prometheus = var.enable_prometheus
  })
}
