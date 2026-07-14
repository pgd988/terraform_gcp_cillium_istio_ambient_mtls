/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Variables for the Kubernetes backbone resources sub-module (`kubernetes/`).
 *
 * NOTE: Application namespaces, ServiceAccounts, L7 Waypoints, HTTPRoute rules,
 * and AuthorizationPolicies are managed separately via ArgoCD GitOps repository.
 */

variable "istio_namespace" {
  description = "The namespace where the Istio control plane is installed."
  type        = string
}

variable "enable_strict_mtls" {
  description = "Whether to enforce STRICT mTLS across the mesh backbone inside istio-system."
  type        = bool
  default     = true
}

variable "trust_domain" {
  description = "The Istio SPIFFE trust domain (`spiffe://<trust_domain>/ns/<ns>/sa/<sa>`)."
  type        = string
  default     = "cluster.local"
}

variable "trust_bundle_secret" {
  description = "Configuration for External Secrets Operator (ESO) integration to sync Istio root CA from Google Secret Manager (GSM)."
  type = object({
    enabled               = optional(bool, false)
    secret_name           = optional(string, "cacerts")
    secret_store_name     = optional(string, "gcp-secret-manager")
    secret_store_kind     = optional(string, "ClusterSecretStore")
    gsm_secret_id         = optional(string, "istio-ca-root")
    refresh_interval      = optional(string, "1h")
  })
  default = {
    enabled           = false
    secret_name       = "cacerts"
    secret_store_name = "gcp-secret-manager"
    secret_store_kind = "ClusterSecretStore"
    gsm_secret_id     = "istio-ca-root"
    refresh_interval  = "1h"
  }
}
