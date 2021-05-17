resource "kubernetes_pod_security_policy" "controller" {
  metadata {
    name = "controller"

    labels = {
      app = "metallb"
    }
  }

  spec {
    required_drop_capabilities = ["ALL"]
    volumes                    = ["configMap", "secret", "emptyDir"]

    se_linux {
      rule = "RunAsAny"
    }

    run_as_user {
      rule = "MustRunAs"

      range {
        min = 1
        max = 65535
      }
    }

    fs_group {
      rule = "MustRunAs"

      range {
        min = 1
        max = 65535
      }
    }

    read_only_root_filesystem = true
  }
}

resource "kubernetes_pod_security_policy" "speaker" {
  metadata {
    name = "speaker"

    labels = {
      app = "metallb"
    }
  }

  spec {
    privileged                 = true
    required_drop_capabilities = ["ALL"]
    allowed_capabilities       = ["NET_ADMIN", "NET_RAW", "SYS_ADMIN"]
    volumes                    = ["configMap", "secret", "emptyDir"]
    host_network               = true

    se_linux {
      rule = "RunAsAny"
    }

    run_as_user {
      rule = "RunAsAny"
    }

    fs_group {
      rule = "RunAsAny"
    }

    read_only_root_filesystem = true
  }
}

resource "kubernetes_service_account" "controller" {
  metadata {
    name      = "controller"
    namespace = "metallb-system"

    labels = {
      app = "metallb"
    }
  }
}

resource "kubernetes_service_account" "speaker" {
  metadata {
    name      = "speaker"
    namespace = "metallb-system"

    labels = {
      app = "metallb"
    }
  }
}

resource "kubernetes_cluster_role" "metallb_system_controller" {
  metadata {
    name = "metallb-system:controller"

    labels = {
      app = "metallb"
    }
  }

  rule {
    verbs      = ["get", "list", "watch", "update"]
    api_groups = [""]
    resources  = ["services"]
  }

  rule {
    verbs      = ["update"]
    api_groups = [""]
    resources  = ["services/status"]
  }

  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }

  rule {
    verbs          = ["use"]
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    resource_names = ["controller"]
  }
}

resource "kubernetes_cluster_role" "metallb_system_speaker" {
  metadata {
    name = "metallb-system:speaker"

    labels = {
      app = "metallb"
    }
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services", "endpoints", "nodes"]
  }

  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }

  rule {
    verbs          = ["use"]
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    resource_names = ["speaker"]
  }
}

resource "kubernetes_role" "config_watcher" {
  metadata {
    name      = "config-watcher"
    namespace = "metallb-system"

    labels = {
      app = "metallb"
    }
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["configmaps"]
  }
}

resource "kubernetes_role" "pod_lister" {
  metadata {
    name      = "pod-lister"
    namespace = "metallb-system"

    labels = {
      app = "metallb"
    }
  }

  rule {
    verbs      = ["list"]
    api_groups = [""]
    resources  = ["pods"]
  }
}

resource "kubernetes_cluster_role_binding" "metallb_system_controller" {
  metadata {
    name = "metallb-system:controller"

    labels = {
      app = "metallb"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "controller"
    namespace = "metallb-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "metallb-system:controller"
  }
}

resource "kubernetes_cluster_role_binding" "metallb_system_speaker" {
  metadata {
    name = "metallb-system:speaker"

    labels = {
      app = "metallb"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "speaker"
    namespace = "metallb-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "metallb-system:speaker"
  }
}

resource "kubernetes_role_binding" "config_watcher" {
  metadata {
    name      = "config-watcher"
    namespace = "metallb-system"

    labels = {
      app = "metallb"
    }
  }

  subject {
    kind = "ServiceAccount"
    name = "controller"
  }

  subject {
    kind = "ServiceAccount"
    name = "speaker"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "config-watcher"
  }
}

resource "kubernetes_role_binding" "pod_lister" {
  metadata {
    name      = "pod-lister"
    namespace = "metallb-system"

    labels = {
      app = "metallb"
    }
  }

  subject {
    kind = "ServiceAccount"
    name = "speaker"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "pod-lister"
  }
}

resource "kubernetes_daemonset" "speaker" {
  metadata {
    name      = "speaker"
    namespace = "metallb-system"

    labels = {
      app = "metallb"

      component = "speaker"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "metallb"

        component = "speaker"
      }
    }

    template {
      metadata {
        labels = {
          app = "metallb"

          component = "speaker"
        }

        annotations = {
          "prometheus.io/port" = "7472"

          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        container {
          name  = "speaker"
          image = "metallb/speaker:v0.9.3"
          args  = ["--port=7472", "--config=config"]

          port {
            name           = "monitoring"
            container_port = 7472
          }

          env {
            name = "METALLB_NODE_NAME"

            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name = "METALLB_HOST"

            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name = "METALLB_ML_BIND_ADDR"

            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name  = "METALLB_ML_LABELS"
            value = "app=metallb,component=speaker"
          }

          env {
            name = "METALLB_ML_NAMESPACE"

            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "METALLB_ML_SECRET_KEY"

            value_from {
              secret_key_ref {
                name = "memberlist"
                key  = "secretkey"
              }
            }
          }

          resources {
            limits {
              memory = "100Mi"
              cpu    = "100m"
            }
          }

          image_pull_policy = "Always"

          security_context {
            capabilities {
              add  = ["NET_ADMIN", "NET_RAW", "SYS_ADMIN"]
              drop = ["ALL"]
            }

            read_only_root_filesystem = true
          }
        }

        termination_grace_period_seconds = 2

        node_selector = {
          "beta.kubernetes.io/os" = "linux"
        }

        service_account_name = "speaker"
        host_network         = true

        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_deployment" "controller" {
  metadata {
    name      = "controller"
    namespace = "metallb-system"

    labels = {
      app = "metallb"

      component = "controller"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "metallb"

        component = "controller"
      }
    }

    template {
      metadata {
        labels = {
          app = "metallb"

          component = "controller"
        }

        annotations = {
          "prometheus.io/port" = "7472"

          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        container {
          name  = "controller"
          image = "metallb/controller:v0.9.3"
          args  = ["--port=7472", "--config=config"]

          port {
            name           = "monitoring"
            container_port = 7472
          }

          resources {
            limits {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

          image_pull_policy = "Always"

          security_context {
            capabilities {
              drop = ["all"]
            }

            read_only_root_filesystem = true
          }
        }

        node_selector = {
          "beta.kubernetes.io/os" = "linux"
        }

        service_account_name = "controller"

        security_context {
          run_as_user     = 65534
          run_as_non_root = true
        }
      }
    }

    revision_history_limit = 3
  }
}

