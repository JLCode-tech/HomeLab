#===============================================================================
# vSphere Resources
#===============================================================================

# Create a vSphere VM in the folder #
resource "vsphere_virtual_machine" "k8sleader" {
  # VM placement #
  name             = var.vsphere_vm_name
  #host_system_id   = data.vsphere_host.host.id
  host_system_id  = data.vsphere_host.host.0.id
  resource_pool_id = data.vsphere_resource_pool.target-resource-pool.id
  datastore_id     = data.vsphere_datastore.datastore.0.id
  folder           = var.vsphere_vm_folder
  tags             = [data.vsphere_tag.tag.id]

  # VM resources #
  num_cpus = var.vsphere_vcpu_number
  memory   = var.vsphere_memory_size

  # Guest OS #
  guest_id = data.vsphere_virtual_machine.template.guest_id

  # VM storage #
  disk {
    label            = "${var.vsphere_vm_name}.vmdk"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
  }

  # VM networking #
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  # Customization of the VM #
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vsphere_vm_name
        domain    = var.vsphere_domain
        time_zone = var.vsphere_time_zone
      }

      network_interface {
        ipv4_address = var.vsphere_ipv4_address
        ipv4_netmask = var.vsphere_ipv4_netmask
      }

      ipv4_gateway    = var.vsphere_ipv4_gateway
      dns_server_list = ["${var.vsphere_dns_servers}"]
      dns_suffix_list = ["${var.vsphere_domain}"]
    }
  }

    #Provision All installs and services
    provisioner "remote-exec" {
        inline = [
        "mkdir /root/.ssh",
        "touch /root/.ssh/authorized_keys",
        "echo ${var.public_key} >> /root/.ssh/authorized_keys",
        "chown root:root -R /root/.ssh",
        "chmod 700 /root/.ssh",
        "chmod 600 /root/.ssh/authorized_keys",
        "kubeadm init --pod-network-cidr=${var.vsphere_k8pod_network} --apiserver-advertise-address=${vsphere_virtual_machine.k8sleader.default_ip_address}",
        "mkdir -p $HOME/.kube",
        "cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
        "chown $(id -u):$(id -g) $HOME/.kube/config",
        "kubectl taint nodes --all node-role.kubernetes.io/master-",
        "kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/metallb/metallb-namespace.yaml",
        "kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/metallb/metallb.yaml",
        "kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey=\"$(openssl rand -base64 128)\"",
        "kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/HomeLab/main/k8s/metallb/metallbconfigmap.yaml"   
        ]
        connection {
            type     = "ssh"
            user     = "root"
            password = var.vsphere_vm_password
            host    = vsphere_virtual_machine.k8sleader.default_ip_address
        }        
    }   
}