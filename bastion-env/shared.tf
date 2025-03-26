# Retrieve native application port profiles for standard services
data "vcd_nsxt_app_port_profile" "dns" {
  scope = "SYSTEM"
  name  = "DNS"
}

data "vcd_nsxt_app_port_profile" "dhcp" {
  scope = "SYSTEM"
  name  = "DHCP"
}

data "vcd_nsxt_app_port_profile" "ntp" {
  scope = "SYSTEM"
  name  = "NTP"
}

data "vcd_nsxt_app_port_profile" "http" {
  scope = "SYSTEM"
  name  = "HTTP"
}

# Custom app port profile for non-standard services (e.g., HTTP on port 8080)
resource "vcd_nsxt_app_port_profile" "http_8080" {
  scope = "SYSTEM"
  name  = "HTTP-8080-Custom"

  app_port {
    protocol = "TCP"
    port     = ["8080"]
  }

  description = "Custom HTTP service on port 8080"
}

# Retrieve Edge Gateway details
data "vcd_nsxt_edgegateway" "mygw" {
  org  = var.vcd.org
  name = var.networking.edge_gateway
}

# Org Routed Network - Shared
resource "vcd_network_routed_v2" "vnet_routed_shared" {
  name = "vnet-shared"
  org  = var.vcd.org

  edge_gateway_id = data.vcd_edgegateway.mygw.id

  gateway       = var.networking.networks["shared"].gateway
  prefix_length = var.networking.networks["shared"].prefix
  dns1          = var.networking.networks["shared"].dns_server[0]
  dns2          = var.networking.networks["shared"].dns_server[1]
}

# Firewall rule: Shared to Kubernetes
resource "vcd_nsxv_firewall_rule" "rule-shared_kubernetes" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = data.vcd_edgegateway.mygw.id

  name = "Shared to Kubernetes"

  source {
    ip_addresses      = [var.networking.networks["shared"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  destination {
    ip_addresses      = [var.networking.networks["kubernetes"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.kubernetes_net_routed.name]
  }

  service {
    protocol = "Any"
  }

  action           = "ALLOW"
  enabled          = true
  logging_enabled  = false

  description = "Allows traffic from Shared network to Kubernetes network"
}

# Firewall rule: Kubernetes to Shared
resource "vcd_nsxt_firewall_rule" "rule_kubernetes_to_shared" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "Kubernetes to Shared"

  source {
    ip_addresses      = [var.networking.networks["kubernetes"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.kubernetes_net_routed.name]
  }

  destination {
    ip_addresses      = [var.networking.networks["shared"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  app_port_profile_ids = [
    data.vcd_nsxt_app_port_profile.dns.id,        # Use native DNS profile
    data.vcd_nsxt_app_port_profile.dhcp.id,      # Use native DHCP profile
    data.vcd_nsxt_app_port_profile.ntp.id,       # Use native NTP profile
    vcd_nsxt_app_port_profile.http_8080.id       # Use custom HTTP-8080 profile
  ]

  action           = "ALLOW"
  enabled          = true
  logging_enabled  = false

  description = "Allows specific traffic from Kubernetes to Shared network"
}

# Firewall rule: Transit to Shared
resource "vcd_nsxt_firewall_rule" "rule-transit_to_shared" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "Transit to Shared"

  source {
    ip_addresses      = [var.networking.networks["transit"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_transit.name]
  }

  destination {
    ip_addresses      = [var.networking.networks["shared"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  app_port_profile_ids = [
    data.vcd_nsxt_app_port_profile.dns.id,        # Use native DNS profile
    data.vcd_nsxt_app_port_profile.ntp.id,       # Use native NTP profile
    data.vcd_nsxt_app_port_profile.http.id       # Use native HTTP profile
  ]

  action           = "ALLOW"
  enabled          = true
  logging_enabled  = false

  description = "Allows specific traffic from Transit to Shared network"
}

# Firewall rule: Shared outbound
resource "vcd_nsxt_firewall_rule" "rule-shared-outbound" {
  org          = var.vcd.org
  vdc          = var.vcd.vdc
  edge_gateway = var.networking.edge_gateway

  name = "Shared - Outbound"

  source {
    ip_addresses      = [var.networking.networks["shared"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  destination {
    gateway_interfaces = ["external"]
  }

  service {
    protocol = "Any"
  }

  action           = "ALLOW"
  enabled          = true
  logging_enabled  = false

  description = "Allows all outbound traffic from Shared network"
}

# NAT rule: Outbound SNAT for Shared network
resource "vcd_nsxt_nat_rule" "outbound_snat_shared" {
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name            = "Outbound - Shared"
  rule_type       = "SNAT"
  description     = "Outbound - Shared"

  internal_address = var.networking.networks["shared"].subnet
  external_address = var.vcd.external_network.ip
  enabled          = true
  logging          = false
}

# Firewall rule: Shared to Transit
resource "vcd_nsxv_firewall_rule" "rule-shared_to_transit" {
  org          = var.vcd.org
  edge_gateway = var.networking.edge_gateway

  name = "Shared to Transit"

  source {
    ip_addresses      = [var.networking.networks["shared"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_shared.name]
  }

  destination {
    ip_addresses      = [var.networking.networks["transit"].subnet]
    gateway_interfaces = [vcd_network_routed_v2.vnet_routed_transit.name]
  }

  service {
    protocol = "Any"
  }

  action           = "ALLOW"
  enabled          = true
  logging_enabled  = false

  description = "Allows traffic from Shared network to Transit network"
}

# Attach routed network to Shared vApp
resource "vcd_vapp_org_network" "vapp_org_net_shared" {
  vapp_name        = vcd_vapp.vapp_shared.name
  org_network_name = vcd_network_routed_v2.vnet_routed_shared.name

  depends_on = [vcd_vapp.vapp_shared]
}

# Create Shared vApp
resource "vcd_vapp" "vapp_shared" {
  name        = "vapp-shared"
  description = "Shared vApp"
  org         = var.vcd.org
  vdc         = var.vcd.vdc

  depends_on = [vcd_network_routed_v2.vnet_routed_shared]
}

# Module: Bastion VM
module "vm_bastion" {
  source = "./modules/vm"

  vapp_name     = vcd_vapp.vapp_shared.name
  name          = "bastion-vm"

  network_name  = vcd_vapp_org_network.vapp_org_net_shared.org_network_name
  memory        = var.jumpbox_memory
  cpus          = var.jumpbox_cpus
  power_on      = true

  ip            = [var.jumpbox_ip]
  temp_pass     = var.temp_pass
  initscript    = templatefile("${path.module}/files/linux-initscript.sh", {})
}
