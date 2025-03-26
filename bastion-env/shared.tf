# Create app port profile
resource "vcd_nsxt_app_port_profile" "dns" {
  name  = "DNS-Services"
  scope = "SYSTEM"

  app_port {
    protocol = "TCP"
    port = ["53"]
  }

  app_port {
    protocol = "UDP"
    port = ["53"]
  }
}

resource "vcd_nsxt_app_port_profile" "dhcp" {
  name  = "DHCP-Services"
  scope = "SYSTEM"

  app_port {
    protocol = "UDP"
    port = ["67"]
  }
}

resource "vcd_nsxt_app_port_profile" "ntp" {
  name  = "NTP-Services"
  scope = "SYSTEM"

  app_port {
    protocol = "UDP"
    port = ["123"]
  }
}

resource "vcd_nsxt_app_port_profile" "http" {
  name  = "HTTP-Services"
  scope = "SYSTEM"

  app_port {
    protocol = "TCP"
    port = ["80"]
  }
}

resource "vcd_nsxt_app_port_profile" "http_8080" {
  name  = "HTTP-8080-Custom"
  scope = "SYSTEM"

  app_port {
    protocol = "TCP"
    port = ["8080"]
  }
}

data "vcd_nsxt_edgegateway" "mygw" {
  org = var.vcd.org
  name = var.networking.edge_gateway
}

resource "vcd_network_routed_v2" "vnet_routed_shared" {
  name = "vnet-shared"
  org  = var.vcd.org


  edge_gateway_id = data.vcd_edgegateway.mygw.id

  gateway       = var.networking.networks["shared"].gateway
  prefix_length = var.networking.networks["shared"].prefix
  dns1          = var.networking.networks["shared"].dns_server[0]
  dns2          = var.networking.networks["shared"].dns_server[1]

}

resource "vcd_nsxv_firewall_rule" "rule-shared_kubernetes" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  
  edge_gateway = data.vcd_edgegateway.mygw.id

  name = "Shared to kubernetes"

  source {
    ip_addresses = [
      var.networking.networks["shared"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  destination {
    ip_addresses = [
      var.networking.networks["kubernetes"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.kubernetes_net_routed.name]
  }

  service {
    protocol = "Any"
  }

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false
}

resource "vcd_nsxt_firewall_rule" "rule_kubernetes_to_shared" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "All Networks to Shared"

  source {
    ip_addresses = [
      var.networking.networks["kubernetes"].subnet,
    ]
    gateway_interfaces = [
      vcd_network_routed_v2.kubernetes_net_routed.name,
    ]

  }

  destination {
    ip_addresses = [
      var.networking.networks["shared"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  service {
    protocol = "tcp"
    port     = "53"
  }

  app_port_profile_ids = [
    vcd_nsxt_app_port_profile.dns.id,
    vcd_nsxt_app_port_profile.dhcp.id,
    vcd_nsxt_app_port_profile.ntp.id,
    vcd_nsxt_app_port_profile.http_8080.id
  ]

  action = "ALLOW"
  enable = true
  logging_enabled = false
}


resource "vcd_nsxt_firewall_rule" "rule-transit_to_shared" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "All Networks to Shared"

  source {
    ip_addresses = [
      var.networking.networks["transit"].subnet,
    ]
    gateway_interfaces = [
      vcd_network_routed_v2.vnet_routed_transit.name,
    ]
  }

  destination {
    ip_addresses = [
      var.networking.networks["shared"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  app_port_profile_ids= [
    vcd_nsxt_app_port_profile.dns.id,
    vcd_nsxt_app_port_profile.ntp.id,
    vcd_nsxt_app_port_profile.ntp.id,
    vcd_nsxt_app_port_profile.http.id
  ]

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false
}

resource "vcd_nsxt_firewall_rule" "rule-shared-outbound" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "Shared - Outbound"

  source {
    ip_addresses = [
      var.networking.networks["shared"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  destination {
    gateway_interfaces = ["external"]
  }

  service {
    protocol = "Any"
  }

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false
}

resource "vcd_nsxt_nat_rule" "outbound_snat_shared" {
  org                = var.vcd.org
  edge_gateway_id    = data.vcd_nsxt_edgegateway.mygw.id

  name               = "Outbound - Shared"
  rule_type          = "SNAT"
  description        = "Outbound - Shared"

  internal_address = var.networking.networks["shared"].subnet
  external_address = var.vcd.external_network.ip
  enabled            = true
  logging            = false
}

resource "vcd_nsxv_firewall_rule" "rule-shared_to_transit" {
  org          = var.vcd.org
  
  edge_gateway = var.networking.edge_gateway

  name = "Shared to transit"

  source {
    ip_addresses = [
      var.networking.networks["shared"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  destination {
    ip_addresses = [
      var.networking.networks["transit"].subnet,
    ]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_transit.name]
  }

  service {
    protocol = "Any"
  }

  action          = "ALLOW"
  enabled         = true
  logging_enabled = false
}


resource "vcd_vapp_org_network" "vapp_org_net_shared" {

  vapp_name = vcd_vapp.vapp_shared.name

  # Comment below line to create an isolated vApp network
  org_network_name = vcd_network_routed_v2.vnet_routed_shared.name

  depends_on = [vcd_vapp.vapp_shared]
}

resource "vcd_vapp" "vapp_shared" {
  name        = "vapp-shared"
  description = "Shared vApp"
  org         = var.vcd.org
  vdc         = var.vcd.vdc

  depends_on = [vcd_network_routed_v2.vnet_routed_shared]
}

/*
module "vm_ns" {
  source = "./modules/vm"

  vapp_name = vcd_vapp.vapp_shared.name
  name      = "ns"
  #name      = "ns-${var.vcd_org}"

  network_name = vcd_vapp_org_network.vapp_org_net_shared.org_network_name
  memory       = var.ns_memory
  cpus         = var.ns_cpus
  power_on     = true

  ip         = var.ns_ips
  temp_pass  = var.temp_pass
  initscript = templatefile("${path.module}/files/linux-initscript.sh", {})
}
*/

module "vm_bastion" {
  source = "./modules/vm"

  vapp_name = vcd_vapp.vapp_shared.name
  name = "bastion-vm"


  network_name = vcd_vapp_org_network.vapp_org_net_shared.org_network_name
  memory       = var.jumpbox_memory
  cpus         = var.jumpbox_cpus
  power_on     = true

  ip         = [var.jumpbox_ip]
  temp_pass  = var.temp_pass
  initscript = templatefile("${path.module}/files/linux-initscript.sh", {})
}
