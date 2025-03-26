locals {
  cluster_domain      = "${var.cluster_name}.${var.base_domain}"
  control_plane_fqdns = [for idx in range(1, var.control_plane_count + 1) : "k8s-cp0${idx}.${local.cluster_domain}"]
  compute_fqdns       = [for idx in range(1, var.compute_count + 1) : "k8s-worker0${idx}.${local.cluster_domain}"]
  no_iginition        = ""
  vcd_host            = replace(replace(var.vcd_url, "https://", ""), "/api", "")
}

data "vcd_network_routed_v2" "net_kubernetes" {
  name = "${KUBERNETES_NET}"
}

data "vcd_network_direct" "net_nfs_storage" {
  name = "${NFS_STORAGE_NET}"
}

resource "vcd_vapp" "kubernetes_vapp" {
  name        = "vapp-${var.cluster_name}"
  description = "Kubernetes vApp"

}

resource "vcd_vapp_org_network" "vapp_org_net_kubernetes" {
  vapp_name = vcd_vapp.kubernetes_vapp.name

  # Comment below line to create an isolated vApp network
  org_network_name = data.vcd_network_routed_v2.net_kubernetes.name

  depends_on = [vcd_vapp.kubernetes_vapp]
}

resource "vcd_vapp_org_network" "vapp_org_net_nfs" {
  vapp_name        = vcd_vapp.kubernetes_vapp.name
  org_network_name = data.vcd_network_direct.net_nfs_storage.name
  depends_on       = [vcd_vapp.kubernetes_vapp]
}

module "control_plane_vm" {
  source = "./controllers"

  network_name     = data.vcd_network_routed_v2.net_kubernetes.name
  vcd_catalog      = var.vcd_catalog
  vcd_vdc          = var.vcd_vdc
  vcd_org          = var.vcd_org
  app_name         = vcd_vapp.kubernetes_vapp.name
  flatcar_template = var.flatcar_template

  cluster_domain = local.cluster_domain
  //base_domain             = var.base_domain
  cluster_name = var.cluster_name
  machine_cidr = var.machine_cidr
  //network_nfs  = data.vcd_network_direct.net_nfs_storage.name

  vm_count  = var.control_plane_count
  num_cpus  = var.control_plane_num_cpus
  memory    = var.control_plane_memory
  disk_size = var.control_disk

  depends_on = [
    vcd_vapp.kubernetes_vapp,
    vcd_vapp_org_network.vapp_org_net_kubernetes,
  ]
  hostnames_ip_addresses = zipmap(
    local.control_plane_fqdns,
    var.control_plane_ip_addresses,
  )
  dns_addresses = var.dns_addresses
  mac           = var.control_plane_mac_address
}

module "compute_vm" {
  source = "./workers"

  network_name     = data.vcd_network_routed_v2.net_kubernetes.name
  vcd_catalog      = var.vcd_catalog
  vcd_vdc          = var.vcd_vdc
  vcd_org          = var.vcd_org
  app_name         = vcd_vapp.kubernetes_vapp.name
  flatcar_template = var.flatcar_template


  cluster_domain = local.cluster_domain
  //base_domain             = var.base_domain
  cluster_name = var.cluster_name
  machine_cidr = var.machine_cidr
  network_nfs  = data.vcd_network_direct.net_nfs_storage.name

  vm_count  = var.compute_count
  num_cpus  = var.compute_num_cpus
  memory    = var.compute_memory
  disk_size = var.compute_disk

  depends_on = [
    module.control_plane_vm,
    vcd_vapp.kubernetes_vapp,
    vcd_vapp_org_network.vapp_org_net_kubernetes,
  ]
  hostnames_ip_addresses = zipmap(
    local.compute_fqdns,
    var.compute_ip_addresses,
  )
  nfs_ip_addresses = zipmap(
    local.compute_fqdns,
    var.nfs_compute_ip_addresses
  )
  dns_addresses = var.dns_addresses
  mac           = var.compute_compute_mac_addresses
}


data "template_file" "startup_vms_script" {
  template = <<EOF
# **********************************************************************************************************************
# This script starts the vms in the cluster after all machines have been provisioned.
# **********************************************************************************************************************
vcd login ${local.vcd_host} ${var.vcd_org} ${var.vcd_user} -p '${var.vcd_pass}' -v ${var.vcd_vdc}
vcd vapp power-on ${vcd_vapp.kubernetes_vapp.name}
vcd logout
EOF
}

resource "local_file" "startup_vms_script" {
  content  = data.template_file.startup_vms_script.rendered
  filename = "${path.cwd}/${var.cluster_name}-start-vms.sh"
  depends_on = [
    module.control_plane_vm,
    module.compute_vm,
  ]
}

resource "null_resource" "start_vapp" {
  triggers = {
    always_run = "$timestamp()"
  }
  depends_on = [
    module.compute_vm,
    module.control_plane_vm,
  ]

  provisioner "local-exec" {
    command = "${path.cwd}/${var.cluster_name}-start-vms.sh"
  }
}
