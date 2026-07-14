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
