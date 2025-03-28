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

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  gateway       = var.networking.networks["shared"].gateway
  prefix_length = var.networking.networks["shared"].prefix
  dns1          = var.networking.networks["shared"].dns_server[0]
  dns2          = var.networking.networks["shared"].dns_server[1]
}

# NSX-T Firewall Rules
resource "vcd_nsxt_firewall" "main" {
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  # Rule 1: Shared to Kubernetes
  rule {
    name             = "Shared to Kubernetes"
    direction        = "IN_OUT"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false
  source_ids = [var.networking.networks["shared"].subnet]

  destination_ids = [var.networking.networks["kubernetes"].subnet]
  app_port_profile_ids = [
    data.vcd_nsxt_app_port_profile.dns.id,
    data.vcd_nsxt_app_port_profile.dhcp.id,
    data.vcd_nsxt_app_port_profile.ntp.id,
    data.vcd_nsxt_app_port_profile.http.id,
    vcd_nsxt_app_port_profile.http_8080.id
  ]
  }

  # Rule 2: Kubernetes to Shared
  rule {
    name             = "Kubernetes to Shared"
    direction        = "IN_OUT"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false
    source_ids    = [var.networking.networks["kubernetes"].subnet]
    destination_ids = [var.networking.networks["shared"].subnet]
    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.dns.id,
      data.vcd_nsxt_app_port_profile.dhcp.id,
      data.vcd_nsxt_app_port_profile.ntp.id,
      vcd_nsxt_app_port_profile.http_8080.id
    ]
  }

  # Rule 3: Transit to Shared
  rule {
    name             = "Transit to Shared"
    direction        = "IN_OUT"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false
    source_ids    = [var.networking.networks["transit"].subnet]
    destination_ids = [var.networking.networks["shared"].subnet]
    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.dns.id,
      data.vcd_nsxt_app_port_profile.ntp.id,
      data.vcd_nsxt_app_port_profile.http.id
    ]
  }

  # Rule 4: Shared Outbound
  rule {
    name             = "Shared - Outbound"
    direction        = "OUT"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false
    source_ids    = [var.networking.networks["shared"].subnet]
    destination_ids = ["0.0.0.0/0"]
  }

  # Rule 5: Shared to Transit
  rule {
    name             = "Shared to Transit"
    direction        = "IN_OUT"
    ip_protocol      = "IPV4"
    action           = "ALLOW"
    enabled          = true
    logging          = false
    source_ids    = [var.networking.networks["shared"].subnet]
    destination_ids = [var.networking.networks["transit"].subnet]
  }
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

# Attach routed network to Shared vApp
resource "vcd_vapp_org_network" "vapp_org_net_shared" {
  vapp_name        = vcd_vapp.vapp_shared.name
  org_network_name = vcd_network_routed_v2.vnet_routed_shared.name
}

# Create Shared vApp
resource "vcd_vapp" "vapp_shared" {
  name        = "vapp-shared"
  description = "Shared vApp"
  org         = var.vcd.org
  vdc         = var.vcd.vdc
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