# Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
#
# Helm values template for `ztunnel` (Zero-Trust L4 Secure Tunnel DaemonSet).
# Configured specifically for coexistence with GKE Dataplane V2 (Cilium eBPF).

profile: ambient

# ztunnel runs on every node as a DaemonSet to intercept L4 traffic via eBPF/socket redirection
replicaCount: 1 # DaemonSet runs exactly 1 pod per matching node

env:
  ISTIO_META_CLUSTER_ID: "${cluster_id}"
  ISTIO_META_NETWORK: "${network}"
  XDS_ADDRESS: "istiod.${istio_namespace}.svc:15012"
  CA_ADDR: "istiod.${istio_namespace}.svc:15012"

# Pod settings required for eBPF / CNI coexistence on GKE Dataplane V2
podAnnotations:
  prometheus.io/scrape: "${enable_prometheus ? "true" : "false"}"
  prometheus.io/port: "15020"
  prometheus.io/path: "/stats/prometheus"

# GKE Dataplane V2 node selector & tolerations to ensure ztunnel schedules on all data pods
nodeSelector:
  kubernetes.io/os: linux

tolerations:
  - operator: Exists
    effect: NoSchedule
  - operator: Exists
    effect: NoExecute

resources:
  requests:
    cpu: 500m
    memory: 1024Mi
  limits:
    cpu: 2000m
    memory: 2048Mi

# Security context required for L4 socket interception and network namespace manipulation
securityContext:
  privileged: true
  capabilities:
    add:
      - NET_ADMIN
      - SYS_ADMIN
      - NET_RAW
      - SETPCAP

serviceAccount:
  create: true
  name: ztunnel

global:
  istioNamespace: "${istio_namespace}"
  meshID: "mesh-${cluster_id}"
  multiCluster:
    clusterName: "${cluster_id}"
  network: "${network}"
