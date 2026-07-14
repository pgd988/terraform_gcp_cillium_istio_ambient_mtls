/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Variables for the multi-cluster example.
 */

variable "remote_prod_us_api_endpoint" {
  description = "API server endpoint of remote prod-us cluster."
  type        = string
  default     = "https://34.123.45.67"
}

variable "remote_prod_us_ca_base64" {
  description = "Base64 encoded CA certificate of remote prod-us cluster."
  type        = string
  default     = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg=="
}

variable "remote_prod_us_sa_token" {
  description = "ServiceAccount bearer token with cluster reader permissions on remote prod-us cluster."
  type        = string
  sensitive   = true
  default     = "eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.example..."
}
