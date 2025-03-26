# Create app port profile
resource "vcd_nsxt_app_port_profile" "http" {
  scope = "SYSTEM"
  name = "HTTP-Services"

  app_port {
    protocol = "TCP"
    port     = "80"
  }
}

resource "vcd_nsxt_app_port_profile" "https" {
  scope = "SYSTEM"
  name = "HTTPS-Services"

  app_port {
    protocol = "TCP"
    port     = "443"
  }
}

resource "vcd_nsxt_app_port_profile" "api" {
  scope = "SYSTEM"
  name = "API Port"

  app_port {
    protocol = "TCP"
    port     = "6443"
  }
}

# Org Routed Network - App
resource "vcd_network_routed_v2" "kubernetes_net_routed" {
  name = "vnet-kubernttes"
  org  = var.vcd.org

  edge_gateway_id = data.vcd_edgegateway.mygw.id

  gateway       = var.networking.networks["kubernetes"].gateway
  prefix_length = var.networking.networks["kubernetes"].prefix
  dns1          = var.networking.networks["kubernetes"].dns_server[0]
  dns2          = var.networking.networks["kubernetes"].dns_server[1]
}

resource "vcd_nsxt_firewall_rule" "rule-kubernetes-to-transit" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "kubernetes to transit"

  source {
    ip_addresses = [
      var.networking.networks["kubernetes"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.kubernetes_net_routed.name]
  }

  destination {
    ip_addresses = [
      var.networking["transit"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_transit.name]
  }

  app_port_profile_ids = [
    vcd_nsxt_app_port_profile.http.id,
    vcd_nsxt_app_port_profile.https.id,
    vcd_nsxt_app_port_profile.api.id
  ]
  
  action = "ALLOW"
  enable = true
  logging_enabled = false
}

data "vcd_nsxt_edgegateway" "mygw" {
  org = var.vcd.org
  name = var.networking.edge_gateway
}

resource "vcd_nsxt_edgegateway_dhcp_forwarding" "relay_config" {
  edge_gateway_id = data.vcd_edgegateway.mygw.id
  enabled = true

  dhcp_servers = [
    var.networking.networks["shared"].ns_ips,
  ]
}

resource "vcd_vapp" "kubernetes_vapp" {
  name        = "vapp-kubernetes"
  description = "K8s vApp"
  org         = var.vcd.org
  #depends_on = [data.vcd_network_routed_v2.kubernetes_net_routed]
  depends_on = [vcd_network_routed_v2.kubernetes_net_routed]
}

resource "vcd_vapp_org_network" "kubernetes_vapp_org_net" {

  vapp_name = vcd_vapp.kubernetes_vapp.name

  # Comment below line to create an isolated vApp network
  org_network_name = vcd_network_routed_v2.kubernetes_net_routed.name

  depends_on = [vcd_vapp.kubernetes_vapp]
}


resource "vcd_vapp_vm" "kubernetes_helper" {
  vapp_name = vcd_vapp.kubernetes_vapp.name
  name      = "kubernetes-helper"
  count     = var.networking.shared.helper.enabled ? 1 : 0
  org          = var.vcd.org

  catalog_name  = var.services.catalog
  template_name = var.networking.shared.helper.template
  os_type       = "centos7_64Guest"
  memory        = 8192
  cpus          = 4
  cpu_cores     = 2

  power_on         = true
  hardware_version = "vmx-19"
  computer_name    = "helper"

  network {
    type               = "org"
    name               = vcd_network_routed_v2.kubernetes_net_routed.name
    ip_allocation_mode = "MANUAL"
    ip                 = var.networking.shared.helper.ip
    is_primary         = true
    adapter_type       = "VMXNET3"
  }

  depends_on = [vcd_network_routed_v2.kubernetes_net_routed]

}
