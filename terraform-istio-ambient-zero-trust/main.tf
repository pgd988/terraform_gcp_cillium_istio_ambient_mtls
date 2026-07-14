/**
 * Copyright (C) Google Cloud Platform - Istio Ambient Zero-Trust Module
 *
 * Root main module implementation. Orchestrates:
 * 1. Istio control plane namespace provisioning (`istio-system`).
 * 2. `istio-base` Helm chart release (CRD installation).
 * 3. `istiod` Helm chart release (Control Plane in ambient profile).
 * 5. Kubernetes resources child module (`./kubernetes`) for backbone STRICT mTLS (`PeerAuthentication` in istio-system).
 * 6. Multi-cluster child module (`./multicluster`) for East-West Gateway and external CA synchronization via ESO.
 *
 * NOTE: Application namespaces, ServiceAccounts, L7 Waypoints, HTTPRoute rules, and AuthorizationPolicies
 * are managed as GitOps manifests in an external ArgoCD repository (see `./examples/argocd-gitops-manifests/`).
 */

# 1. Create Istio Control Plane Namespace if requested
resource "kubernetes_namespace_v1" "istio_system" {
  count = var.enable && var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = merge(
      local.common_labels,
      {
        "topology.istio.io/network" = var.network
      }
    )
  }
}

# 2. Deploy Istio Base Chart (CRDs) with atomic upgrades and version pinning
resource "helm_release" "istio_base" {
  count = var.enable ? 1 : 0

  name       = "istio-base"
  repository = var.helm_repository
  chart      = "base"
  version    = var.istio_version
  namespace  = var.namespace

  atomic          = var.helm_config.atomic
  cleanup_on_fail = var.helm_config.cleanup_on_fail
  timeout         = var.helm_config.timeout
  max_history     = var.helm_config.max_history
  wait            = var.helm_config.wait
  wait_for_jobs   = var.helm_config.wait_for_jobs
  force_update    = var.helm_config.force_update
  recreate_pods   = var.helm_config.recreate_pods

  values = [
    local.istio_base_values
  ]

  dynamic "set" {
    for_each = var.helm_values_override.base
    content {
      name  = split("=", set.value)[0]
      value = join("=", slice(split("=", set.value), 1, length(split("=", set.value))))
    }
  }

  depends_on = [
    kubernetes_namespace_v1.istio_system
  ]
}

# 3. Deploy Istiod Control Plane Chart (Ambient profile)
resource "helm_release" "istiod" {
  count = var.enable ? 1 : 0

  name       = "istiod"
  repository = var.helm_repository
  chart      = "istiod"
  version    = var.istio_version
  namespace  = var.namespace

  atomic          = var.helm_config.atomic
  cleanup_on_fail = var.helm_config.cleanup_on_fail
  timeout         = var.helm_config.timeout
  max_history     = var.helm_config.max_history
  wait            = var.helm_config.wait
  wait_for_jobs   = var.helm_config.wait_for_jobs
  force_update    = var.helm_config.force_update
  recreate_pods   = var.helm_config.recreate_pods

  values = [
    local.istiod_values
  ]

  dynamic "set" {
    for_each = var.helm_values_override.istiod
    content {
      name  = split("=", set.value)[0]
      value = join("=", slice(split("=", set.value), 1, length(split("=", set.value))))
    }
  }

  depends_on = [
    helm_release.istio_base
  ]
}

# 4. Deploy ztunnel DaemonSet Chart (L4 eBPF / socket redirection on Dataplane V2)
resource "helm_release" "ztunnel" {
  count = var.enable && var.enable_ambient ? 1 : 0

  name       = "ztunnel"
  repository = var.helm_repository
  chart      = "ztunnel"
  version    = var.istio_version
  namespace  = var.namespace

  atomic          = var.helm_config.atomic
  cleanup_on_fail = var.helm_config.cleanup_on_fail
  timeout         = var.helm_config.timeout
  max_history     = var.helm_config.max_history
  wait            = var.helm_config.wait
  wait_for_jobs   = var.helm_config.wait_for_jobs
  force_update    = var.helm_config.force_update
  recreate_pods   = var.helm_config.recreate_pods

  values = [
    local.ztunnel_values
  ]

  dynamic "set" {
    for_each = var.helm_values_override.ztunnel
    content {
      name  = split("=", set.value)[0]
      value = join("=", slice(split("=", set.value), 1, length(split("=", set.value))))
    }
  }

  depends_on = [
    helm_release.istiod
  ]
}

# 5. Invoke Kubernetes Resources Submodule (Backbone STRICT mTLS in istio-system)
module "kubernetes" {
  source = "./kubernetes"
  count  = var.enable ? 1 : 0

  istio_namespace    = var.namespace
  enable_strict_mtls = var.enable_strict_mtls
  trust_domain       = var.trust_domain

  depends_on = [
    helm_release.ztunnel
  ]
}

# 6. Invoke Multi-Cluster Submodule when enable_multicluster = true
module "multicluster" {
  source = "./multicluster"
  count  = var.enable && var.enable_multicluster ? 1 : 0

  cluster_name           = var.cluster_name
  cluster_id             = var.cluster_id
  network                = var.network
  region                 = var.region
  istio_namespace        = var.namespace
  istio_version          = var.istio_version
  chart_repository       = var.helm_repository
  helm_values_override   = var.helm_values_override
  trust_domain           = var.trust_domain
  remote_clusters        = var.remote_clusters
  trust_bundle_secret    = var.trust_bundle_secret
  east_west_gateway_name = var.east_west_gateway_name

  depends_on = [
    helm_release.istiod
  ]
}
