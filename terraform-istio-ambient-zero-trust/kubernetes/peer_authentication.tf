/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * PeerAuthentication configuration enforcing STRICT mTLS across the mesh backbone.
 *
 * In Istio Ambient mode, ztunnel transparently encapsulates service-to-service traffic inside
 * mTLS tunnels using HBONE (HTTP-Based Overlay Network Environment). Setting the root mesh-wide
 * mode to STRICT inside `istio-system` ensures that unencrypted plaintext requests are rejected by default across all enrolled namespaces.
 *
 * NOTE: Individual application namespace PeerAuthentication policies can also be managed via ArgoCD.
 */

# Root mesh-wide default PeerAuthentication inside istio-system control plane namespace
resource "kubernetes_manifest" "mesh_default_peer_authentication" {
  count = var.enable_strict_mtls ? 1 : 0

  manifest = {
    apiVersion = "security.istio.io/v1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = var.istio_namespace
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/part-of"    = "istio-ambient-zero-trust"
      }
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }

  field_manager {
    force_conflicts = true
  }
}
