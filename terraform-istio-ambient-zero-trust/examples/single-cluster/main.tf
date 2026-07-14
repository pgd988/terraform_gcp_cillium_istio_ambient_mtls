/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Example: Single-Cluster Istio Ambient Zero-Trust Backbone CNI on GKE Dataplane V2.
 *
 * Demonstrates how to consume the reusable `terraform-istio-ambient-zero-trust` module
 * to provision the basic backbone CNI structure (Istio control plane and ztunnel eBPF DaemonSet).
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

module "istio_ambient" {
  source = "../../"

  enable        = true
  istio_version = var.istio_version
  namespace     = "istio-system"

  # Enforce STRICT mTLS across the mesh backbone inside istio-system
  enable_strict_mtls = true

  # Single cluster deployment (`enable_multicluster = false`)
  enable_multicluster = false
}
