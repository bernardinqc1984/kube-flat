# Configuration Edge Gateway NSX-T
data "vcd_nsxt_edgegateway" "mygw" {
  org  = var.vcd.org
  name = var.networking.edge_gateway
}

# Profils de ports natifs
data "vcd_nsxt_app_port_profile" "http" { 
  scope = "SYSTEM" 
  name  = "HTTP" 
}

data "vcd_nsxt_app_port_profile" "https" { 
  scope = "SYSTEM" 
  name  = "HTTPS" 
}

data "vcd_nsxt_app_port_profile" "ssh" { 
  scope = "SYSTEM" 
  name  = "SSH" 
}

# Profils personnalisés
resource "vcd_nsxt_app_port_profile" "haproxyadmin" {
  scope = "SYSTEM"
  name  = "HAProxy admin Port"
  app_port { 
    protocol = "TCP" 
    port     = ["9000"] 
  }
}

resource "vcd_nsxt_app_port_profile" "api" {
  scope = "SYSTEM"
  name  = "API Port"
  app_port { 
    protocol = "TCP" 
    port     = ["6443"] 
  }
}

# Firewall consolidé avec paramètres complets
resource "vcd_nsxt_firewall" "main" {
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  rule {
    name             = "haproxy-admin-inbound"
    direction        = "IN"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false

    source_ids        = vcd.networking.networks["fw_rules"].allow_ssh_source
    destination_ids   = [var.vcd.external_network.ip]
    app_port_profile_ids = [vcd_nsxt_app_port_profile.haproxyadmin.id]
  }

  rule {
    name             = "jumpbox-ssh-inbound"
    direction        = "IN"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false

    source_ids        = var.networking.fw_rules.allow_ssh_source
    destination_ids   = [var.vcd.external_network.ip]
    app_port_profile_ids = [data.vcd_nsxt_app_port_profile.ssh.id]
  }

  rule {
    name             = "transit-to-kubernetes"
    direction        = "IN_OUT"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false

    source_ids       = [vcd_network_routed_v2.vnet_routed_transit.id]
    destination_ids  = [vcd_network_routed_v2.kubernetes_net_routed.id]
    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.ssh.id,
      data.vcd_nsxt_app_port_profile.http.id,
      data.vcd_nsxt_app_port_profile.https.id,
      vcd_nsxt_app_port_profile.api.id
    ]
  }

  rule {
    name             = "api-external-access"
    direction        = "IN"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false

    source_ids        = var.networking.networks["fw_rules"].allow_ssh_source
    destination_ids   = [var.vcd.external_network.ip]
    app_port_profile_ids = [vcd_nsxt_app_port_profile.api.id]
  }

  rule {
    name             = "lb-traffic"
    direction        = "IN"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false

    source_ids        = ["any"]
    destination_ids   = [var.vcd.external_network.ip]
    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.http.id,
      data.vcd_nsxt_app_port_profile.https.id,
      vcd_nsxt_app_port_profile.api.id
    ]
  }
}

# NAT Rules 
resource "vcd_nsxt_nat_rule" "snat_kubernetes" {
  org                = var.vcd.org
  edge_gateway_id    = data.vcd_nsxt_edgegateway.mygw.id
  name               = "Outbound - Kubernetes"
  rule_type          = "SNAT"
  description        = "Outbound - Kubernetes"
  internal_address   = var.networking.networks["kubernetes"].subnet
  external_address   = var.vcd.external_network.ip
  enabled            = true
}

resource "vcd_nsxt_nat_rule" "ssh_dnat_jumpbox" {
  org                = var.vcd.org
  edge_gateway_id    = data.vcd_nsxt_edgegateway.mygw.id
  name               = "SSH DNAT Jumpbox"
  rule_type          = "DNAT"
  description        = "SSH Jumpbox"
  external_address   = data.vcd_nsxt_edgegateway.mygw.primary_ip
  internal_address   = var.networking.shared.jumpbox_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.ssh.id
  dnat_external_port = "22"
  enabled            = true
  logging            = true
}