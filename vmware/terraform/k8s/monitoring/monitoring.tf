provider "kubernetes" {}

provider "helm" {
  kubernetes {}
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts" 
  chart      = "prometheus"
  namespace = "monitoring"

  set {
    name  = "alertmanager.persistentVolume.storageClass"
    value = "longhorn"
  }

  set {
    name  = "server.persistentVolume.storageClass"
    value = "longhorn"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

}

resource "helm_release" "influx" {
  name       = "influx"
  repository = "https://influxdata.github.io/helm-charts" 
  chart      = "influxdb"
  namespace = "monitoring"

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  set {
    name  = "persistence.storageClass"
    value = "longhorn"
  }
}

resource "helm_release" "speedtest" {
  name       = "speedtest"
  repository = "https://k8s-at-home.com/charts/" 
  chart      = "speedtest"
  namespace = "monitoring"

  set {
    name  = "config.influxdb.host"
    value = "influx-influxdb.monitoring"
  }

  set {
    name  = "config.delay"
    value = "10800"
  }

  set {
    name  = "debug"
    value = "true"
  }
}

resource "helm_release" "unifi-poller" {
  name       = "unifi-poller"
  repository = "https://k8s-at-home.com/charts/" 
  chart      = "unifi-poller"
  namespace = "monitoring"

  set {
    name  = "config.prometheus.disable"
    value = "false"
  }

  set {
    name  = "config.influxdb.url"
    value = "http://influx-influxdb.monitoring:8086"
  }

  set {
    name  = "config.influxdb.disable"
    value = "false"
  }

  set {
    name  = "config.unifi.defaults.user"
    value = "jarrodlucia1974"
  }

  set {
    name  = "config.unifi.defaults.pass"
    value = "Mongo!123"
  }

  set {
    name  = "config.unifi.defaults.url"
    value = "https://192.168.1.32:8443"
  }

  set {
    name = "config.unifi.defaults.save_dpi"
    value = "true"
  }

}