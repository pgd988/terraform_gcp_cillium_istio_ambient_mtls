# Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
#
# Helm values template for `istio-base` chart.
# Installs custom resource definitions (CRDs) required for Ambient mesh.

global:
  istioNamespace: ${istio_namespace}

# Ensure Ambient CRDs (WorkloadGroup, WorkloadEntry, PeerAuthentication, AuthorizationPolicy, Waypoint/Gateway API) are provisioned
base:
  enableCRDTemplates: true
  validateCRDs: true
