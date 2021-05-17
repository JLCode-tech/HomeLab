#===============================================================================
# vSphere Resources
#===============================================================================

resource "null_resource" "previous" {}

resource "time_sleep" "wait_2_mins" {
  depends_on = [null_resource.previous]

  create_duration = "120s"
}


# Create a vSphere VM in the folder #
resource "vsphere_virtual_machine" "k8snode" {

  depends_on = [
    time_sleep.wait_2_mins
  ]

  # Node Count #

  count = var.vsphere_k8_nodes

  # VM placement #
  name             = "${var.vsphere_vm_name_k8n1}${count.index + 1}"
  #host_system_id   = data.vsphere_host.host.id
  #host_system_id  = data.vsphere_host.host.[${count.index}].id
  host_system_id  = data.vsphere_host.host.*.id[count.index + 1]
  resource_pool_id = data.vsphere_resource_pool.target-resource-pool.id
  #datastore_id     = data.vsphere_datastore.datastore.id
  datastore_id  = data.vsphere_datastore.datastore.*.id[count.index + 1]
  folder           = var.vsphere_vm_folder
  tags             = [data.vsphere_tag.tag.id]

    # VM resources #
  num_cpus = var.vsphere_vcpu_number
  memory   = var.vsphere_memory_size

  # Guest OS #
  guest_id = data.vsphere_virtual_machine.template.guest_id

  # VM storage #
  disk {
    label            = "${var.vsphere_vm_name_k8n1}${count.index + 1}.vmdk"
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
        host_name = "${var.vsphere_vm_name_k8n1}${count.index + 1}"
        domain    = var.vsphere_domain
        time_zone = var.vsphere_time_zone
      }

      network_interface {
        ipv4_address = "${var.vsphere_ipv4_address_k8n1_network}${"${var.vsphere_ipv4_address_k8n1_host}" + count.index}"
        ipv4_netmask = var.vsphere_ipv4_netmask
      }

      ipv4_gateway    = var.vsphere_ipv4_gateway
      dns_server_list = ["${var.vsphere_dns_servers}"]
      dns_suffix_list = ["${var.vsphere_domain}"]
    }
  }
}