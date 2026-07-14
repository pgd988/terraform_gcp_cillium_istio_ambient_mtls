# Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
#
# Helm values template for `istiod` (Istio Control Plane) chart configured for Ambient Mode
# and integration with Google Kubernetes Engine (GKE) Dataplane V2.

profile: ambient

meshConfig:
  accessLogFile: "%{ if enable_telemetry }/dev/stdout%{ else }/dev/null%{ endif }"
  accessLogEncoding: JSON
  enableAutoMtls: true
  trustDomain: "${trust_domain}"
  defaultConfig:
    proxyMetadata:
      ISTIO_META_DATAPLANE_MODE: "ambient"
    # GKE Dataplane V2 compatibility: ensure smooth socket discovery and clean termination
    holdApplicationUntilProxyStarts: true

pilot:
  autoscaleEnabled: true
  autoscaleMin: 2
  autoscaleMax: 5
  replicaCount: 2
  rollingMaxSurge: 100%
  rollingMaxUnavailable: 25%

  env:
    PILOT_ENABLE_AMBIENT: "true"
    PILOT_ENABLE_STATUS: "true"
    CA_TRUST_NODE: "true"

  resources:
    requests:
      cpu: 500m
      memory: 2048Mi
    limits:
      cpu: 2000m
      memory: 4096Mi

  nodeSelector:
    kubernetes.io/os: linux

  # Ensure high availability during upgrades
  podDisruptionBudget:
    minAvailable: 1

  # Service account used by istiod to interact with Kubernetes API and watch mesh resources
  serviceAccount:
    create: true
    name: istiod

global:
  istioNamespace: "${istio_namespace}"

# Telemetry and Prometheus integration with Google Cloud Managed Service for Prometheus (GMP)
telemetry:
  v2:
    prometheus:
      enabled: ${enable_prometheus}
    accessLogPolicy:
      enabled: ${enable_telemetry}
