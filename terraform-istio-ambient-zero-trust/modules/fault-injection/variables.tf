/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Variables for the dedicated L7 Fault Injection submodule (`modules/fault-injection`).
 */

variable "enabled" {
  description = "Whether to create the L7 fault injection resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the fault injection HTTPRoute or configuration."
  type        = string
  default     = "l7-fault-injection"
}

variable "namespace" {
  description = "The target application namespace where the L7 Waypoint and workloads reside."
  type        = string
}

variable "waypoint_name" {
  description = "Name of the parent Waypoint Gateway (`parentRefs.name`) intercepting L7 traffic for this namespace or workload."
  type        = string
  default     = "waypoint"
}

variable "target_hostnames" {
  description = "List of target hostnames intercepted by this L7 fault injection policy (e.g., `payments.payments.svc.cluster.local`)."
  type        = list(string)
}

variable "match_path_prefix" {
  description = "Path prefix to match for applying fault injection (e.g., `/checkout` or `/api/v1`)."
  type        = string
  default     = "/"
}

variable "match_headers" {
  description = "Optional map of exact HTTP request headers required to trigger fault injection (e.g., `{ x-chaos-test = \"enabled\" }`)."
  type        = map(string)
  default     = {}
}

variable "fault_injection_type" {
  description = "The type of fault to inject: `ABORT_HTTP_ERROR` (inject HTTP status code), `LATENCY_DELAY` (inject artificial request delay), or `BOTH`."
  type        = string
  default     = "ABORT_HTTP_ERROR"

  validation {
    condition     = contains(["ABORT_HTTP_ERROR", "LATENCY_DELAY", "BOTH"], var.fault_injection_type)
    error_message = "fault_injection_type must be one of: ABORT_HTTP_ERROR, LATENCY_DELAY, or BOTH."
  }
}

variable "abort_http_status" {
  description = "The HTTP status code to return when ABORT_HTTP_ERROR or BOTH is triggered."
  type        = number
  default     = 500
}

variable "abort_percentage" {
  description = "Percentage of matching requests (0.0 to 100.0) that should receive the injected HTTP abort error."
  type        = number
  default     = 10.0
}

variable "delay_duration" {
  description = "The fixed delay duration string to inject (e.g., `5s` or `500ms`) when LATENCY_DELAY or BOTH is triggered."
  type        = string
  default     = "3s"
}

variable "delay_percentage" {
  description = "Percentage of matching requests (0.0 to 100.0) that should experience the artificial latency delay."
  type        = number
  default     = 20.0
}

variable "backend_service_name" {
  description = "Name of the target backend service where non-aborted or delayed traffic is routed."
  type        = string
}

variable "backend_service_port" {
  description = "Port number of the target backend service."
  type        = number
  default     = 8080
}

variable "labels" {
  description = "Additional labels to apply to the generated Kubernetes resources."
  type        = map(string)
  default     = {}
}
