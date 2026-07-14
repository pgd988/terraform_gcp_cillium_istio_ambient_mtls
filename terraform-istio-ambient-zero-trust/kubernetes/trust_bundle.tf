/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * External Secrets Operator (ESO) integration to synchronize root CA certificates (`cacerts`)
 * from Google Secret Manager (GSM) into the Istio control plane namespace (`istio-system`).
 */

resource "kubernetes_manifest" "cacerts_external_secret" {
  count = var.trust_bundle_secret.enabled ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.trust_bundle_secret.secret_name
      namespace = var.istio_namespace
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "app.kubernetes.io/part-of"    = "istio-ambient-zero-trust"
      }
    }
    spec = {
      refreshInterval = var.trust_bundle_secret.refresh_interval
      secretStoreRef = {
        name = var.trust_bundle_secret.secret_store_name
        kind = var.trust_bundle_secret.secret_store_kind
      }
      target = {
        name           = var.trust_bundle_secret.secret_name
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "ca-cert.pem"
          remoteRef = {
            key      = var.trust_bundle_secret.gsm_secret_id
            property = "ca-cert.pem"
          }
        },
        {
          secretKey = "ca-key.pem"
          remoteRef = {
            key      = var.trust_bundle_secret.gsm_secret_id
            property = "ca-key.pem"
          }
        },
        {
          secretKey = "root-cert.pem"
          remoteRef = {
            key      = var.trust_bundle_secret.gsm_secret_id
            property = "root-cert.pem"
          }
        },
        {
          secretKey = "cert-chain.pem"
          remoteRef = {
            key      = var.trust_bundle_secret.gsm_secret_id
            property = "cert-chain.pem"
          }
        }
      ]
    }
  }

  field_manager {
    force_conflicts = true
  }
}
