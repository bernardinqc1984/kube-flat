# Retrieve native application port profiles
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

# Custom profiles only for non-standard services
resource "vcd_nsxt_app_port_profile" "haproxyadmin" {
  scope = "SYSTEM"
  name  = "HAProxy admin Port"

  app_port {
    protocol = "TCP"
    port     = "9000"
  }

  description = "HAProxy administration port"
}

resource "vcd_nsxt_app_port_profile" "api" {
  scope = "SYSTEM"
  name  = "API Port"

  app_port {
    protocol = "TCP"
    port     = "6443"
  }

  description = "Kubernetes API port"
}

resource "vcd_nsxt_app_port_profile" "ns_ssh" {
  scope = "SYSTEM"
  name  = "NS SSH Port"

  app_port {
    protocol = "TCP"
    port     = ["8445-8446"]
  }

  description = "Specific SSH ports for NS server access"
}

# Retrieve the Edge Gateway
data "vcd_edgegateway" "mygw" {
  name = var.networking.edge_gateway
  org  = var.vcd.org
  vdc  = var.vcd.vdc
}

# Firewall rules for administrative access
resource "vcd_nsxt_firewall_rule" "rule-haproxyadmin" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "HAProxy admin - Inbound"

  source {
    ip_addresses = var.networking.networks["fw_rules"].allow_ssh_source
  }

  destination {
    ip_addresses = var.vcd.external_network.ip
  }

  app_port_profile_ids = [
    vcd_nsxt_app_port_profile.haproxyadmin.id
  ]

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false

  description = "Allows access to the HAProxy administration interface"
}

resource "vcd_nsxt_firewall_rule" "rule-jumpbox" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "Jumpbox - Inbound"

  source {
    ip_addresses = var.networking.fw_allow_ssh_source
  }

  destination {
    ip_addresses = [var.vcd.external_network_ip]
  }

  app_port_profile_ids = [
    data.vcd_nsxt_app_port_profile.ssh.id
  ]

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false

  description = "Allows SSH access to the Jumpbox server"
}

# Firewall rules for communication between networks
resource "vcd_nsxt_firewall_rule" "rule-transit_kubernetes" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "transit to kubernetes"

  source {
    ip_addresses = [
      var.networking.networks["transit"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_transit.name]
  }

  destination {
    ip_addresses = [
      var.networking.networks["kubernetes"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.kubernetes_net_routed.name]
  }

  app_port_profile_ids = [
    data.vcd_nsxt_app_port_profile.ssh.id,
    data.vcd_nsxt_app_port_profile.http.id,
    data.vcd_nsxt_app_port_profile.https.id,
    vcd_nsxt_app_port_profile.api.id
  ]

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false

  description = "Allows communication between transit and Kubernetes networks"
}

# Firewall rules for external services
resource "vcd_nsxt_firewall_rule" "rule-api" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "API"

  source {
    ip_addresses = var.networking.networks["fw_rules"].allow_ssh_source
  }

  destination {
    ip_addresses = var.vcd.external_network.ip
  }

  app_port_profile_ids = [
    vcd_nsxt_app_port_profile.api.id
  ]

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false

  description = "Allows access to the Kubernetes API"
}

resource "vcd_nsxt_firewall_rule" "rule-lb" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "LB"

  source {
    ip_addresses = ["any"]
  }

  destination {
    ip_addresses = [var.vcd.external_network_ip]
  }

  app_port_profile_ids = [
    data.vcd_nsxt_app_port_profile.http.id,
    data.vcd_nsxt_app_port_profile.https.id,
    vcd_nsxt_app_port_profile.api.id
  ]

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false

  description = "Allows HTTP/HTTPS/API traffic to the load balancer"
}

# NAT rules for services
resource "vcd_nsxt_nat_rule" "outbound_snat_kubernetes" {
  org                = var.vcd.org
  edge_gateway_id    = data.vcd_edgegateway.mygw.id
  name               = "Outbound - Kubernetes"
  rule_type          = "SNAT"
  internal_address   = var.networking.networks["kubernetes"].subnet
  external_address   = var.vcd.external_network.ip
  enabled            = true
  description        = "Outbound - Kubernetes"
}

resource "vcd_nsxt_nat_rule" "outbound_snat_transit" {
  org                = var.vcd.org
  edge_gateway_id    = data.vcd_edgegateway.mygw.id
  name               = "Outbound - transit"
  rule_type          = "SNAT"
  internal_address   = var.networking.networks["transit"].subnet
  external_address   = var.vcd.external_network.ip
  description        = "Outbound - transit"
}

resource "vcd_nsxt_nat_rule" "ssh_dnat_jumpbox" {
  org                = var.vcd.org

  edge_gateway_id    = data.vcd_edgegateway.mygw.id

  name               = "SSH DNAT Jumpbox"
  rule_type          = "DNAT"
  description        = "SSH Jumpbox"

  external_address   = tolist(data.vcd_edgegateway.mygw.external_ip_addresses)[0].primary_ip_address
  internal_address = var.networking.shared.jumpbox_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.ssh.id
  dnat_external_port = data.vcd_nsxt_app_port_profile.ssh.app_port[1].port
  enabled            = true
  logging            = true
}

resource "vcd_nsxt_nat_rule" "http_dnat_lb" {
  org                = var.vcd.org
  edge_gateway_id    = data.vcd_edgegateway.mygw.id
  name               = "HTTP DNAT LB"
  rule_type          = "DNAT"
  description        = "HTTP"
  external_address = tolist(data.vcd_edgegateway.mygw.external_ip_addresses)[0].primary_ip_address
  internal_address = var.networking.lb.vip_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.http.id
  dnat_external_port = data.vcd_nsxt_app_port_profile.http.app_port[0].port
  enabled            = true
  logging            = true
}


resource "vcd_nsxt_nat_rule" "https_dnat_lb" {
  org                = var.vcd.org
  edge_gateway_id    = data.vcd_edgegateway.mygw.id
  name               = "HTTPS DNAT LB"
  rule_type          = "DNAT"
  description        = "HTTPS"
  external_address = tolist(data.vcd_edgegateway.mygw.external_ip_addresses)[0].primary_ip_address
  internal_address = var.networking.lb.vip_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.https.id
  dnat_external_port = data.vcd_nsxt_app_port_profile.https.app_port[0].port
  enabled            = true
  logging            = true
}