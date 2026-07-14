/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Variables for the single-cluster example.
 */

variable "istio_version" {
  description = "Istio chart version to deploy."
  type        = string
  default     = "1.22.1"
}
