# terraform.tfvars
vcd = {
  url = "https://vcd-url"
  user = "user"
  password = "password"
  org = "org"
  vdc = "vdc"
  allow_unverified_ssl = true
  external_network = {
    name = "external-network"
    ip = "external-ip"
  }
}

networking = {
  edge_gateway = "edge-gateway"
  networks = {
    kubernetes = {
      subnet = "subnet"
      gateway = "gateway"
      prefix = 24
      dns_server = ["dns-server1", "dns-server2"]
    }
    transit = {
      subnet = "subnet"
      gateway = "gateway"
      prefix = 26
      dns_server = ["dns-server1", "dns-server2"]
      }
    shared = {
      subnet = "subnet"
      gateway = "gateway"
      prefix = 24
      dns_server = ["dns-server1", "dns-server2"]
      jumpbox_ip = "jumpbox-ip"
      ns_ips = ["ns-ip1"]
      helper = {
        enabled = true
        ip = "helper-ip"
        template = "template"
        }
    }
    fw_rules = {
      allow_ssh_source = ["source"]
    }
  }
}

services = {
  catalog = "catalog"
  lb = {
    vip_ip = "vip-ip"
    ips = ["ip1"]
  }
}

