# HomeLabBuild

### GoDaddy Dynamic DNS Script
   ```apt-get update
   apt-get install curl
   chmod 700 godaddyddns.sh
   #Install script into CRONTAB
   crontab -l | { cat; echo "*/15 * * * * /root/godaddyddns.sh"; } | crontab -
   
   Test Script ./godaddyddns.sh:
   root@CICD:~# ./godaddyddns.sh 
   2019-11-27 01:15:55 - Current External IP is 121.213.211.149, GoDaddy DNS IP is 121.213.211.149
   ```

### CICD Pipeline Infra
- Drone Install
- Github Integration

# IaC Section Below

Objective of the Lab is to do as much as possible as Infrastructure as Code (IaC). This includes all VM hosts, K8s cluster, F5, and additional services.

## Ubuntu VM Hosts

### VM build + Kubernetes Infra via Terraform



## VyOS Mgmt Router (Network Mgmt Interfaces)

#git clone https://github.com/JLCode-tech/VyosHome
#1. Run the deployment: `ansible-playbook -i inventory.ini vyossite.yml`

migrate to terraform

## Install F5
    - mgmt IP off VyOS





## Stacks to be installed (Kubernetes Prefered)

### K8s installs

