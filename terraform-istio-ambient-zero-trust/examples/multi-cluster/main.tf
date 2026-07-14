/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Example: Multi-Cluster Istio Ambient Backbone CNI across GKE Clusters in the same Trust Domain.
 *
 * Demonstrates enabling `enable_multicluster = true` for clusters (`prod-eu` + `prod-us`)
 * sharing a common SPIFFE trust domain (`prod.global.local`), root CA via Google Secret Manager,
 * and East-West Gateway for cross-network mTLS tunneling.
 *
 * NOTE: Application namespaces (`istio.io/dataplane-mode=ambient`), ServiceAccount enrollments,
 * L7 Waypoint Gateways (`istio-waypoint`), L7 HTTPRoutes, and AuthorizationPolicies are
 * deployed separately via ArgoCD in an application GitOps repository.
 * See: ../../examples/argocd-gitops-manifests/
 */

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
    }
  }
}

module "istio_ambient_prod_eu" {
  source = "../../"

  enable        = true
  istio_version = "1.22.1"
  namespace     = "istio-system"

  # Enforce STRICT mTLS across the mesh backbone inside istio-system
  enable_strict_mtls = true

  # Enable multi-cluster East-West mTLS routing
  enable_multicluster = true
  cluster_name        = "gke-prod-eu"
  cluster_id          = "prod-eu"
  network             = "vpc-prod-eu"
  region              = "europe-west1"
  trust_domain        = "prod.global.local"

  # Sync root CA trust bundle from Google Secret Manager using External Secrets Operator
  trust_bundle_secret = {
    enabled           = true
    secret_name       = "cacerts"
    secret_store_name = "gcp-secret-manager"
    secret_store_kind = "ClusterSecretStore"
    gsm_secret_id     = "istio-ca-root"
    refresh_interval  = "1h"
  }

  # Register remote cluster (`prod-us`) endpoints and kubeconfig for cross-cluster routing
  remote_clusters = {
    "prod-us" = {
      cluster_name          = "prod-us"
      api_server_endpoint   = var.remote_prod_us_api_endpoint
      ca_crt_base64         = var.remote_prod_us_ca_base64
      service_account_token = var.remote_prod_us_sa_token
    }
  }
}
