/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Istio East-West Gateway configuration for multi-cluster Ambient Mesh.
 *
 * Architecture:
 * Cluster A: application -> ztunnel -> East-West Gateway (mTLS over HBONE) -> East-West Gateway -> ztunnel -> Application (Cluster B)
 *
 * The East-West Gateway is exposed via a Kubernetes LoadBalancer Service and routes cross-network
 * mTLS traffic using SNI-DNAT (`AUTO_PASSTHROUGH` mode on port 15443).
 */

# 1. Deploy East-West Gateway Helm chart
resource "helm_release" "east_west_gateway" {
  name       = var.east_west_gateway_name
  repository = var.chart_repository
  chart      = "gateway"
  version    = var.istio_version
  namespace  = var.istio_namespace

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  values = [
    yamlencode({
      service = {
        type = "LoadBalancer"
        ports = [
          {
            name       = "status-port"
            port       = 15021
            targetPort = 15021
          },
          {
            name       = "tls"
            port       = 15443
            targetPort = 15443
          },
          {
            name       = "tls-istiod"
            port       = 15012
            targetPort = 15012
          },
          {
            name       = "tls-webhook"
            port       = 15017
            targetPort = 15017
          }
        ]
      }
      networkGateway = var.network
      env = {
        ISTIO_META_ROUTER_MODE              = "sni-dnat"
        ISTIO_META_REQUESTED_NETWORK_VIEW   = var.network
        ISTIO_META_CLUSTER_ID               = var.cluster_id
      }
      labels = {
        istio                          = var.east_west_gateway_name
        topology.istio.io/network      = var.network
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/part-of"    = "istio-ambient-zero-trust"
      }
    })
  ]
}

# 2. Configure Gateway resource for cross-network SNI passthrough routing
resource "kubernetes_manifest" "cross_network_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"
    metadata = {
      name      = "cross-network-gateway"
      namespace = var.istio_namespace
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/part-of"    = "istio-ambient-zero-trust"
      }
    }
    spec = {
      selector = {
        istio = var.east_west_gateway_name
      }
      servers = [
        {
          port = {
            number   = 15443
            name     = "tls"
            protocol = "TLS"
          }
          tls = {
            mode = "AUTO_PASSTHROUGH"
          }
          hosts = [
            "*.local"
          ]
        }
      ]
    }
  }

  field_manager {
    force_conflicts = true
  }

  depends_on = [
    helm_release.east_west_gateway
  ]
}
