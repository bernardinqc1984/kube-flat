terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "~> 3.8.0"
    }
  }
  #required_version = ">= 1.3.0"
}

resource "vcd_vapp_vm" "vm" {
  vapp_name     = var.vapp_name
  count         = var.vm_count
  name          = "${var.name}-${count.index + 1}"
  computer_name = "${var.name}-${count.index + 1}"
  #name          = split("-", var.name)[0]
  #computer_name = replace("${var.name}${count.index}", "_", "-")
  catalog_name = var.catalog_name

  template_name = var.template_name
  os_type       = var.os_type
  memory        = var.memory
  cpus          = var.cpus
  //cpu_cores     = 2

  power_on = var.power_on
  #hardware_version = "vmx-19"

  network {
    type               = "org"
    name               = var.network_name
    ip_allocation_mode = "MANUAL"
    ip                 = var.ip[count.index]
    is_primary         = true
    adapter_type       = "VMXNET3"
  }

  /*
  override_template_disk {
    bus_type        = "paravirtual"
    bus_number      = 0
    unit_number     = 0
    iops            = 0
    size_in_mb      = 20480
    storage_profile = "Tier-2"
  }
  */

  customization {
    admin_password                      = var.temp_pass
    allow_local_admin_password          = true
    auto_generate_password              = false
    change_sid                          = false
    enabled                             = true
    force                               = false
    join_domain                         = false
    join_org_domain                     = false
    must_change_password_on_first_login = false
    number_of_auto_logons               = 0
    initscript                          = var.initscript
  }

  lifecycle {
    #prevent_destroy = true
    #create_before_destroy = true
    ignore_changes = [name]
  }

}

