provider "kubernetes" {}

provider "helm" {
  kubernetes {}
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts" 
  chart      = "grafana"
  namespace = "monitoring"

  set {
    name  = "persistence.storageClassName"
    value = "longhorn"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "adminPassword"
    value = "Mongo!123"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  values = [
    "${file("grafanavalues.yaml")}"
  ]

}