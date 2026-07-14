/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Input variables for configuring Istio Ambient Mesh on GKE Dataplane V2.
 */

variable "enable" {
  description = "Master toggle to enable or disable the Istio Ambient Zero-Trust module."
  type        = bool
  default     = true
}

variable "istio_version" {
  description = "The Istio Helm chart and components version to deploy (e.g., '1.22.1'). Must support Ambient profile."
  type        = string
  default     = "1.22.1"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.]+)?$", var.istio_version))
    error_message = "The istio_version must be a valid semantic version string (e.g., '1.22.1')."
  }
}

variable "namespace" {
  description = "The Kubernetes namespace where the Istio control plane (istiod, ztunnel) is installed."
  type        = string
  default     = "istio-system"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "The namespace must be a valid Kubernetes namespace name."
  }
}

variable "create_namespace" {
  description = "Whether the module should create the Kubernetes namespace specified in `var.namespace`."
  type        = bool
  default     = true
}

variable "enable_ambient" {
  description = "Toggle to explicitly enable Istio Ambient profile and eBPF/L4 redirection optimizations on Dataplane V2."
  type        = bool
  default     = true
}

variable "enable_strict_mtls" {
  description = "Whether to enforce STRICT mTLS across the mesh backbone by creating the root PeerAuthentication resource in istio-system."
  type        = bool
  default     = true
}

variable "enable_telemetry" {
  description = "Toggle to enable Istio access logs and OpenTelemetry/Prometheus metrics generation across istiod and ztunnel."
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Toggle to integrate Istio metrics with Google Cloud Managed Service for Prometheus (GMP) via ServiceMonitor / PodMonitoring resources."
  type        = bool
  default     = true
}

variable "helm_repository" {
  description = "The official Istio Helm repository URL used to fetch `istio-base`, `istiod`, and `ztunnel` charts."
  type        = string
  default     = "https://istio-release.storage.googleapis.com/charts"
}

variable "helm_values_override" {
  description = "Map of custom Helm values overrides for istio-base, istiod, and ztunnel releases. Example: `{ istiod = [ \"pilot.resources.requests.cpu=500m\" ] }`."
  type = object({
    base    = optional(list(string), [])
    istiod  = optional(list(string), [])
    ztunnel = optional(list(string), [])
  })
  default = {
    base    = []
    istiod  = []
    ztunnel = []
  }
}

variable "helm_config" {
  description = "Operational configurations for Helm releases including atomic upgrades, timeout, version pinning, and rollback capabilities."
  type = object({
    timeout                  = optional(number, 600)
    atomic                   = optional(bool, true)
    cleanup_on_fail          = optional(bool, true)
    max_history              = optional(number, 10)
    wait                     = optional(bool, true)
    wait_for_jobs            = optional(bool, true)
    force_update             = optional(bool, false)
    recreate_pods            = optional(bool, false)
    repository_key_file      = optional(string, null)
    repository_cert_file     = optional(string, null)
    repository_ca_file       = optional(string, null)
    repository_username      = optional(string, null)
    repository_password      = optional(string, null)
  })
  default = {
    timeout         = 600
    atomic          = true
    cleanup_on_fail = true
    max_history     = 10
    wait            = true
    wait_for_jobs   = true
    force_update    = false
    recreate_pods   = false
  }
}

variable "trust_domain" {
  description = "The Istio SPIFFE trust domain (`spiffe://<trust_domain>/ns/<ns>/sa/<sa>`)."
  type        = string
  default     = "cluster.local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.trust_domain))
    error_message = "The trust_domain must be a valid DNS-like identifier without URI prefixes."
  }
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
