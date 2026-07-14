/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Versions and requirements for the Kubernetes resources sub-module.
 */

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
    }
  }
}
