/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Variables for the multi-cluster sub-module (`multicluster/`).
 */

variable "cluster_name" {
  description = "Name of the local GKE cluster."
  type        = string
}

variable "cluster_id" {
  description = "Unique identifier of the local GKE cluster (`ISTIO_META_CLUSTER_ID`)."
  type        = string
}

variable "network" {
  description = "VPC network name where the local cluster resides (`ISTIO_META_NETWORK`)."
  type        = string
}

variable "region" {
  description = "GCP region of the local cluster."
  type        = string
}

variable "istio_namespace" {
  description = "The namespace where the Istio control plane is installed."
  type        = string
}

variable "istio_version" {
  description = "Istio chart version to deploy for East-West Gateway."
  type        = string
}

variable "chart_repository" {
  description = "Official Istio Helm repository URL."
  type        = string
}

variable "helm_values_override" {
  description = "Map of custom values overrides."
  type        = any
  default     = {}
}

variable "trust_domain" {
  description = "Shared SPIFFE trust domain (`spiffe://<trust_domain>/ns/...`)."
  type        = string
}

variable "remote_clusters" {
  description = "Map of remote clusters to peer for cross-cluster endpoint discovery."
  type = map(object({
    cluster_name          = string
    api_server_endpoint   = string
    ca_crt_base64         = string
    service_account_token = string
  }))
  default = {}
}

variable "trust_bundle_secret" {
  description = "Configuration for External Secrets Operator (ESO) + Google Secret Manager (GSM) integration."
  type = object({
    enabled           = optional(bool, false)
    secret_name       = optional(string, "cacerts")
    secret_store_name = optional(string, "gcp-secret-manager")
    secret_store_kind = optional(string, "ClusterSecretStore")
    gsm_secret_id     = optional(string, "istio-ca-root")
    refresh_interval  = optional(string, "1h")
  })
}

variable "east_west_gateway_name" {
  description = "Name of the East-West Gateway deployment."
  type        = string
}
