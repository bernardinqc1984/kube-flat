variable "vcd" {
  description = "vCloud Director configuration"
  type = object({
    url = string
    user = string
    password = string
    org = string
    vdc = string
    allow_unverified_ssl = bool
    external_network = object({
      name = string
      ip = string
    })
  })
}

# Edge Gateway Configuration

variable "networking" {
  description = "Networking configuration"
  type = object({
    edge_gateway = string
    networks = map(object({
      subnet = string
      gateway = string
      prefix = number
      dns_server = list(string)
      static_ips = string
    }))
    transit = object({
      subnet = string
      gateway = string
      prefix = number
      dns_server = list(string)
      static_ips = string
    })
    shared = object({
      subnet = string
      gateway = string
      prefix = number
      dns_server = list(string)
      jumpbox_ip = string
      ns_ips = list(string)
      helper = object({
        enabled = bool
        ip = string
        template = string 
      }) 
    })
    fw_rules = object({
      allow_ssh_source = list(string)
    })
  })
}

variable "services" {
  type = object({
    catalog = string
    lb = object({
      vip_ip = string
      ips = list(string) 
    }) 
  })
}

variable "lb_cpus" {
  type    = number
  default = 2
}
variable "lb_memory" {
  type    = number
  default = 2 * 1024
}

variable "jumpbox_memory" {
  type = number
  default = 2 * 1024
}

variable "jumpbox_ip" {}

variable "jumpbox_cpus" {
  type    = number
  default = 2
}

variable "temp_pass" {
  type    = string
  default = "........."
}
