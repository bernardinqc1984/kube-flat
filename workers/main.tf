resource "vcd_vapp_vm" "vm" {
  name  = element(split(".", keys(var.hostnames_ip_addresses)[count.index]), 0)
  count = var.vm_count
  computer_name  = element(split(".", keys(var.hostnames_ip_addresses)[count.index]), 0)

  cpus             = var.num_cpus
  cpu_cores         = var.compute_cpu_core
  memory           = var.memory
  vdc              = var.vcd_vdc
  org              = var.vcd_org
  hardware_version = "vmx-19"
  catalog_name     = var.vcd_catalog
  template_name    = var.flatcar_template
  power_on         = false
  //vapp_template_id        = data.vcd_catalog_vapp_template.flatcar_template.id
  vapp_name     = var.app_name
  //os_type         = "coreos64Guest"


  network {
    type               = "org"
    name               = var.network_name
    ip_allocation_mode = "DHCP"
    mac                = var.mac[count.index]
    is_primary         = true
  }
  
  network {
    type               = "org"
    name               = var.network_nfs
    ip_allocation_mode = "POOL"
    is_primary         = false
  }


  override_template_disk {
    bus_type    = "paravirtual"
    size_in_mb  = var.disk_size * 1024
    bus_number  = 0
    unit_number = 0
  }
  guest_properties = {
    "guestinfo.ignition.config.data.encoding" = "base64"
    "guestinfo.ignition.config.data"          = base64encode(file("${path.module}/install.ign"))
  }
}

