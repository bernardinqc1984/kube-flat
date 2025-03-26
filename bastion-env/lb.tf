resource "vcd_network_routed_v2" "vnet_routed_transit" {
  org  = var.vcd.org

  name = "vnet-transit"

  edge_gateway_id = data.vcd_edgegateway.mygw.id

  gateway       = var.networking.networks["transit"].gateway
  prefix_length = var.networking.networks["transit"].prefix
  dns1          = var.networking.networks["transit"].dns_server[0]
  dns2          = var.networking.networks["transit"].dns_server[1]
}


resource "vcd_vapp_org_network" "vapp_org_vnet_transit" {

  vapp_name = vcd_vapp.vapp_lb.name

  # Comment below line to create an isolated vApp network
  org_network_name = vcd_network_routed_v2.vnet_routed_transit.name

  depends_on = [vcd_vapp.vapp_lb]

  reboot_vapp_on_removal = true
}

resource "vcd_vapp" "vapp_lb" {
  name        = "vapp-lb"
  description = "LB vApp"
  org         = var.vcd.org
  vdc         = var.vcd.vdc

  depends_on = [vcd_network_routed_v2.vnet_routed_transit]
}

module "vm_lb" {
  source = "./modules/vm"

  vapp_name = vcd_vapp.vapp_lb.name
  name      = "lb"

  network_name = vcd_vapp_org_network.vapp_org_vnet_transit.org_network_name
  memory       = var.lb_memory
  cpus         = var.lb_cpus
  power_on     = true

  ip         = var.service.lb.is_primary ? var.service.lb.vip_ip : var.service.lb.ips[0]
  temp_pass  = var.temp_pass
  initscript = templatefile("${path.module}/files/linux-initscript.sh", {})
}
