# Retrieve Edge Gateway details
data "vcd_nsxt_edgegateway" "mygw" {
  org  = var.vcd.org
  name = var.networking.edge_gateway
}

# Retrieve native application port profiles for standard services
data "vcd_nsxt_app_port_profile" "http" {
  scope = "SYSTEM"
  name  = "HTTP"
}

data "vcd_nsxt_app_port_profile" "https" {
  scope = "SYSTEM"
  name  = "HTTPS"
}

# Creation for custom API port only
resource "vcd_nsxt_app_port_profile" "api" {
  scope = "SYSTEM"
  name  = "API Port"

  app_port {
    protocol = "TCP"
    port     = ["6443"]
  }
}

# Kubernetes Network Configuration
resource "vcd_network_routed_v2" "kubernetes_net_routed" {
  name            = "vnet-kubernetes" # Correction du nom
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  gateway       = var.networking.networks["kubernetes"].gateway
  prefix_length = var.networking.networks["kubernetes"].prefix
  dns1          = var.networking.networks["kubernetes"].dns_server[0]
  dns2          = var.networking.networks["kubernetes"].dns_server[1]
}

# Firewall Rules
resource "vcd_nsxt_firewall" "main" {
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  rule {
    name        = "kubernetes-to-transit"
    direction   = "IN_OUT"
    ip_protocol = "IPV4"
    action      = "ALLOW"

    source_ids = [vcd_network_routed_v2.kubernetes_net_routed.id]
    destination_ids = [vcd_network_routed_v2.vnet_routed_transit.id]

    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.http.id,  # Profil natif
      data.vcd_nsxt_app_port_profile.https.id, # Profil natif
      vcd_nsxt_app_port_profile.api.id        # Profil personnalisé
    ]
  }
}

# DHCP Relay
resource "vcd_nsxt_edgegateway_dhcp_forwarding" "relay_config" {
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  enabled         = true
  dhcp_servers    = [var.networking.networks["shared"].ns_ips]
}

# vApp Kubernetes 
resource "vcd_vapp" "kubernetes_vapp" {
  name        = "vapp-kubernetes"
  description = "K8s vApp"
  org         = var.vcd.org
}

# Network Attachment
resource "vcd_vapp_org_network" "kubernetes_vapp_org_net" {
  vapp_name        = vcd_vapp.kubernetes_vapp.name
  org_network_name = vcd_network_routed_v2.kubernetes_net_routed.name
}

# VM Helper
resource "vcd_vapp_vm" "kubernetes_helper" {
  count = var.networking.shared.helper.enabled ? 1 : 0

  vapp_name     = vcd_vapp.kubernetes_vapp.name
  name          = "kubernetes-helper"
  org           = var.vcd.org
  catalog_name  = var.services.catalog
  template_name = var.networking.shared.helper.template
  memory        = 8192
  cpus          = 4
  cpu_cores     = 2
  power_on      = true

  network {
    type               = "org"
    name               = vcd_network_routed_v2.kubernetes_net_routed.name
    ip_allocation_mode = "MANUAL"
    ip                 = var.networking.shared.helper.ip
    is_primary         = true
    adapter_type       = "VMXNET3"
  }
}