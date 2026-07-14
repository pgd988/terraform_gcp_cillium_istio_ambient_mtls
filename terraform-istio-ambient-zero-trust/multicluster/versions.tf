/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Versions and provider requirements for the multi-cluster sub-module (`multicluster/`).
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
