/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Remote cluster secret registration for cross-cluster endpoint discovery.
 *
 * Each secret labeled `istio/multiCluster=true` informs `istiod` about a peered remote GKE cluster
 * sharing the same trust domain (`var.trust_domain`). `istiod` uses the embedded kubeconfig
 * to discover remote workloads and dynamically configure `ztunnel` routes across the East-West Gateway.
 */

resource "kubernetes_secret_v1" "remote_cluster" {
  for_each = var.remote_clusters

  metadata {
    name      = "istio-remote-secret-${each.key}"
    namespace = var.istio_namespace
    labels = {
      "istio/multiCluster"           = "true"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "istio-ambient-zero-trust"
    }
    annotations = {
      "istio.io/topology-cluster" = each.value.cluster_name
    }
  }

  type = "Opaque"

  data = {
    "${each.value.cluster_name}" = yamlencode({
      apiVersion = "v1"
      kind       = "Config"
      clusters = [
        {
          name = each.value.cluster_name
          cluster = {
            server                   = each.value.api_server_endpoint
            "certificate-authority-data" = each.value.ca_crt_base64
          }
        }
      ]
      contexts = [
        {
          name = each.value.cluster_name
          context = {
            cluster = each.value.cluster_name
            user    = each.value.cluster_name
          }
        }
      ]
      "current-context" = each.value.cluster_name
      users = [
        {
          name = each.value.cluster_name
          user = {
            token = each.value.service_account_token
          }
        }
      ]
    })
  }
}
