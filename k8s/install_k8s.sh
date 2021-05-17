#MASTER INSTALL
#sudo kubeadm init --config=kubeadm-config.yaml
#mkdir -p $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Get Kubectl CONFIG for export to local machine
#cat $HOME/.kube/config
#export KUBECONFIG=/mnt/c/Users/lucia/Documents/git_working/terraform_k3s_lab/proxmox-tf/prod/kubeconfig

#HELM Install - https://helm.sh/docs/intro/install/
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#HELM Repos to Add Install
helm repo add portainer https://portainer.github.io/k8s/
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add influxdata https://helm.influxdata.com/
helm repo add elastic https://helm.elastic.co
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo add cilium https://helm.cilium.io/
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/metallb/metallb-namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/metallb/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/metallb/metallbconfigmap.yaml

#--- Network Install ---------------------------------------------------------------------------------------
#Cilium Install
#kubectl create -f cilium.yaml
#Verify pods start up correctly
#kubectl -n kube-system get pods --watch

helm install cilium cilium/cilium --version 1.8.2 \
   --namespace kube-system \
   --set global.nodeinit.enabled=true \
   --set global.kubeProxyReplacement=partial \
   --set global.hostServices.enabled=false \
   --set global.externalIPs.enabled=true \
   --set global.nodePort.enabled=true \
   --set global.hostPort.enabled=true \
   --set global.pullPolicy=IfNotPresent \
   --set config.ipam=kubernetes \
   --set global.hubble.enabled=true \
   --set global.hubble.listenAddress=":4244" \
   --set global.hubble.relay.enabled=true \
   --set global.hubble.ui.enabled=true \
   --set global.hubble.enabled=true \
   --set global.hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}" \
   --set global.prometheus.enabled=true \
   --set global.operatorPrometheus.enabled=true

sudo kubectl edit svc hubble-ui -n kube-system
    - LoadBalancer

#--- Storage Longhorn ---------------------------------------------------------------------------------------
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/longhorn/001-longhorn.yaml
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/longhorn/002-storageclass.yaml
kubectl -n longhorn-system get services
#Uninstall
#kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml

#--- Portainer Install ---------------------------------------------------------------------------------------
#Portainer Install
### ---- Check LB IP and Port allocated  ---------------------------------------------------
#kubectl -n portainer get services
kubectl create namespace portainer
helm install -n portainer portainer portainer/portainer --set service.type=LoadBalancer

# --- InfluxDB ------
kubectl create namespace monitoring
helm install influx influxdata/influxdb --namespace monitoring --set persistence.enabled=true,persistence.size=10Gi --set persistence.storageClass="longhorn"

#--- Hubble Install ---------------------------------------------------------------------------------------
#Hubble Install
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/hubble/hubble.yaml
#kubectl -n kube-system get services

# K8s Infra monitoring stack --------------------------------------------------------------------------
# ---- Prometheus -----------
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/prometheus-grafana/prometheus/001-namespace.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/prometheus-grafana/prometheus/002-promdeploy.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/prometheus-grafana/prometheus/003-promconfig.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/prometheus-grafana/prometheus/004-nodeexport.yaml
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/prometheus-grafana/prometheus/005-statemetrics.yaml
helm install prometheus stable/prometheus --namespace monitoring --set alertmanager.persistentVolume.storageClass="longhorn" --set server.persistentVolume.storageClass="longhorn"
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/prometheus-grafana/promgraf.yaml

# ---- Grafana -----------
#kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/prometheus-grafana/grafana/001-grafana.yaml
helm install grafana grafana/grafana --namespace monitoring --set persistence.storageClassName="longhorn" --set persistence.enabled=true --set adminPassword='Mongo!123' --values grafanavalues.yaml --set service.type=LoadBalancer
### ---- Check LB IP and Port allocated  ---------------------------------------------------
kubectl -n monitoring get services

# ---- Speedtest--------
helm install speedtest k8s-at-home/speedtest -n monitoring --set config.influxdb.host="influx-influxdb.monitoring" --set config.delay="10800" --set debug="true"
#kubectl logs -f --namespace monitoring $(kubectl get pods --namespace monitoring -l app=speedtest -o jsonpath='{ .items[0].metadata.name }')

# EFK monitoring stack --------------------------------------------------------------------------
kubectl apply -f efk-logging/elastic.yaml
kubectl apply -f efk-logging/kibana.yaml
kubectl apply -f efk-logging/fluentd.yaml

# ELk Logging Stack -----------------------------------------------------------------------------
# ElasticSearch Install
kubectl create namespace elk-logging
helm install elasticsearch --version 7.8.0 elastic/elasticsearch -n elk-logging --set minimumMasterNodes="1" --set replicas="2" --values https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/efk-logging/elastic_values.yaml
# Logstash Install
helm install logstash elastic/logstash -n elk-logging --set replicas="2" --values https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/efk-logging/logstash_values.yaml
#Kibana
#helm install kibana elastic/kibana -n elk-logging --set replicas="2" --set elasticsearchHosts="http://elasticsearch.elk-logging:9200" --values https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/efk-logging/kibana_values.yaml
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/efk-logging/kibana.yaml

#--- Volterra Install ---------------------------------------------------------------------------------------
kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/volterra/001-volterra.yaml
kubectl delete -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/volterra/001-volterra.yaml
kubectl -n ves-system get services

