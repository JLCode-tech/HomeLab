variable "vsphere_user" {
  description = "vSphere user name"
}
variable "vsphere_password" {
  description = "vSphere password"
}
variable "vsphere_vcenter" {
  description = "vCenter server FQDN or IP"
}
variable "vsphere_unverified_ssl" {
  description = "Is the vCenter using a self signed certificate (true/false)"
}
variable "public_key" {
  description = "Public key for SSH into master"
}

# VM specifications

variable "vsphere_datacenter" {
  description = "In which datacenter the VM will be deployed"
}
variable "vsphere_vm_name" {
  description = "What is the name of the VM"
}
variable "vsphere_vm_template" {
  description = "Where is the VM template located"
}
variable "vsphere_vm_folder" {
  description = "In which folder the VM will be store"
}
variable "vsphere_vm_resource_pool" {
  description = "Choose your Resource Pool to use as a folder"
}
variable "resource_pool_designator" {
  description = "The name or path for the resource pool in which to create the resources"
}
variable "vsphere_cluster" {
  description = "In which cluster the VM will be deployed"
}
variable "vsphere_host" {
    description = "ESXI Host to deploy VM and services onto"
}
variable "vsphere_vcpu_number" {
  description = "How many vCPU will be assigned to the VM (default: 1)"
  default     = "2"
}
variable "vsphere_memory_size" {
  description = "How much RAM will be assigned to the VM (default: 1024)"
  default     = "2048"
}
variable "vsphere_datastore" {
  description = "What is the name of the VM datastore"
}
variable "vsphere_port_group" {
  description = "In which port group the VM NIC will be configured (default: VM Network)"
}
variable "vsphere_ipv4_address" {
  description = "What is the IPv4 address of the VM"
}
variable "vsphere_ipv4_netmask" {
  description = "What is the IPv4 netmask of the VM (default: 24)"
  default     = "24"
}
variable "vsphere_k8pod_network" {
  description = "POD Network and Subnet Mask for K8 Configruation Script"
  
}
variable "vsphere_ipv4_gateway" {
  description = "What is the IPv4 gateway of the VM"
}
variable "vsphere_dns_servers" {
  description = "What are the DNS servers of the VM (default: 8.8.8.8)"
  default     = "8.8.8.8"
}
variable "vsphere_domain" {
  description = "What is the domain of the VM"
}
variable "vsphere_time_zone" {
  description = "What is the timezone of the VM (default: UTC)"
  default     = "UTC"
}
variable "vsphere_vm_password" {
  description = "Root password for the VM Template"
}
variable "vsphere_k8_nodes" {
  description = "Number of K8 Nodes"
}
variable "vsphere_vm_name_k8n1" {
  description = "K8 Node VM Name"
}
variable "vsphere_ipv4_address_k8n1_network" {
  description = "K8 Node 1 IP"
}
variable "vsphere_ipv4_address_k8n1_host" {
  description = "K8 Node 1 Host"
}
variable "vsphere_ipv4_address_k8node_host" {
  description = "K8 Node VM Host Placement"
}
variable "vsphere_tag_category" {
  description = "vSphere Tag Catagory Details"
}
variable "vsphere_tag_name" {
  description = "vSphere Tag Details"
}
variable "vsphere_k8_version" {
  description = "Kubernetes Version to Install"
  default     = "1.18.3"
}
variable "esxi_hosts" {
  default = [
    "192.168.1.250",
    "192.168.1.241",
    "192.168.1.242",
  ]
}
variable "esxi_hosts_datastores" {
  default = [
    "mando_datastore1",
    "cara_datastore",
    "yoda_datastore",
  ]
}