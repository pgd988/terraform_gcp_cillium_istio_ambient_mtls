/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * NOTE ON APPLICATION & L7 GITOPS SEPARATION OF DUTIES:
 * This file contains no active Terraform resources.
 *
 * In accordance with GitOps best practices, this Terraform module manages ONLY the basic
 * backbone CNI structure and Istio control plane (istio-base, istiod, ztunnel eBPF DaemonSet,
 * root CA synchronization, and mesh-wide default PeerAuthentication inside istio-system).
 *
 * All particular application/service configurations, namespaces (`istio.io/dataplane-mode=ambient`),
 * ServiceAccount enrollments, L7 Waypoint Gateways (`istio-waypoint`), L7 HTTPRoute rules,
 * and AuthorizationPolicies should be deployed separately via ArgoCD in an application GitOps repository.
 *
 * For complete ready-to-use YAML manifests and ArgoCD structure examples, please see:
 *   ./examples/argocd-gitops-manifests/
 */
