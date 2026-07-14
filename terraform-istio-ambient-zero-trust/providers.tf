/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Provider configurations and requirements.
 *
 * NOTE ON TERRAFORM MODULE BEST PRACTICES:
 * This reusable module inherits provider configurations (`helm`, `kubernetes`, `google`)
 * from the calling root module (e.g., your platform repository or GKE cluster provisioner).
 *
 * Do NOT hardcode provider blocks with static credentials inside this reusable module.
 * The calling configuration should configure providers using GKE Workload Identity or
 * short-lived OAuth tokens retrieved via `google_client_config` and `google_container_cluster`.
 *
 * Example caller configuration:
 *
 * provider "kubernetes" {
 *   host                   = "https://${google_container_cluster.primary.endpoint}"
 *   cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
 *   token                  = data.google_client_config.default.access_token
 * }
 *
 * provider "helm" {
 *   kubernetes {
 *     host                   = "https://${google_container_cluster.primary.endpoint}"
 *     cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
 *     token                  = data.google_client_config.default.access_token
 *   }
 * }
 */
