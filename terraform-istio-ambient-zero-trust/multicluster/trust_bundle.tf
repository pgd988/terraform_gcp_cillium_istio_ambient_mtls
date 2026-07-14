/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Certificate management and trust bundle synchronization using External Secrets Operator (ESO)
 * and Google Secret Manager (GSM).
 *
 * MULTI-CLUSTER CA & CERTIFICATE ROTATION PROCESS:
 * 1. Root CA generation & storage: The shared root CA (`istio-ca-root`) is generated once and stored
 *    securely in Google Secret Manager (GSM) with automatic IAM auditing and versioning.
 * 2. ExternalSecret Synchronization: The External Secrets Operator (assumed already installed on GKE)
 *    periodically polls (`refreshInterval: 1h`) GSM using Workload Identity (`ClusterSecretStore`).
 * 3. Secret Provisioning: ESO creates or updates the Kubernetes Secret (`cacerts`) inside `istio-system`
 *    containing `ca-cert.pem`, `ca-key.pem`, `root-cert.pem`, and `cert-chain.pem`.
 * 4. Automatic Control Plane Reload: `istiod` watches the `cacerts` secret mount via inotify. When rotated,
 *    `istiod` immediately updates its intermediate signing CA without requiring pod restarts.
 * 5. Data Plane SDS Propagation: `istiod` pushes rotated workload SPIFFE certificates via Secret Discovery Service
 *    (SDS) to all `ztunnel` instances across the cluster. Active mTLS tunnels seamlessly transition during
 *    handshakes without dropping L4 eBPF sockets.
 */

resource "kubernetes_manifest" "istio_ca_external_secret" {
  count = var.trust_bundle_secret.enabled ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "istio-ca-external-secret"
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
        name           = var.trust_bundle_secret.secret_name # e.g., "cacerts"
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
