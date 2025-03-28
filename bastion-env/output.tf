# Network Information
output "kubernetes_network" {
  description = "Information about the Kubernetes network"
  value = {
    name         = vcd_network_routed_v2.kubernetes_net_routed.name
    gateway      = vcd_network_routed_v2.kubernetes_net_routed.gateway
    prefix       = vcd_network_routed_v2.kubernetes_net_routed.prefix_length
    dns_servers  = [
      vcd_network_routed_v2.kubernetes_net_routed.dns1,
      vcd_network_routed_v2.kubernetes_net_routed.dns2
    ]
  }
}

output "shared_network" {
  description = "Information about the Shared network"
  value = {
    name         = vcd_network_routed_v2.vnet_routed_shared.name
    gateway      = vcd_network_routed_v2.vnet_routed_shared.gateway
    prefix       = vcd_network_routed_v2.vnet_routed_shared.prefix_length
    dns_servers  = [
      vcd_network_routed_v2.vnet_routed_shared.dns1,
      vcd_network_routed_v2.vnet_routed_shared.dns2
    ]
  }
}

output "transit_network" {
  description = "Information about the Transit network"
  value = {
    name         = vcd_network_routed_v2.vnet_routed_transit.name
    gateway      = vcd_network_routed_v2.vnet_routed_transit.gateway
    prefix       = vcd_network_routed_v2.vnet_routed_transit.prefix_length
    dns_servers  = [
      vcd_network_routed_v2.vnet_routed_transit.dns1,
      vcd_network_routed_v2.vnet_routed_transit.dns2
    ]
  }
}

# vApp Information
output "kubernetes_vapp" {
  description = "Information about the Kubernetes vApp"
  value = {
    name        = vcd_vapp.kubernetes_vapp.name
    description = vcd_vapp.kubernetes_vapp.description
  }
}

output "shared_vapp" {
  description = "Information about the Shared vApp"
  value = {
    name        = vcd_vapp.vapp_shared.name
    description = vcd_vapp.vapp_shared.description
  }
}

output "lb_vapp" {
  description = "Information about the Load Balancer vApp"
  value = {
    name        = vcd_vapp.vapp_lb.name
    description = vcd_vapp.vapp_lb.description
  }
}

# Edge Gateway Information
output "edge_gateway" {
  description = "Information about the Edge Gateway"
  value = {
    name = data.vcd_edgegateway.mygw.name
    external_ip = tolist(data.vcd_edgegateway.mygw.external_ip_addresses)[0].primary_ip_address
  }
}

# NAT Rules Information
output "nat_rules" {
  description = "Information about the NAT rules"
  value = {
    kubernetes_outbound = {
      name = vcd_nsxt_nat_rule.outbound_snat_kubernetes.name
      type = vcd_nsxt_nat_rule.outbound_snat_kubernetes.rule_type
    }
    shared_outbound = {
      name = vcd_nsxt_nat_rule.outbound_snat_shared.name
      type = vcd_nsxt_nat_rule.outbound_snat_shared.rule_type
    }
    transit_outbound = {
      name = vcd_nsxt_nat_rule.outbound_snat_transit.name
      type = vcd_nsxt_nat_rule.outbound_snat_transit.rule_type
    }
    jumpbox_ssh = {
      name = vcd_nsxt_nat_rule.ssh_dnat_jumpbox.name
      type = vcd_nsxt_nat_rule.ssh_dnat_jumpbox.rule_type
    }
  }
}

# Firewall Rules Information
output "firewall_rules" {
  description = "Information about the Firewall rules"
  value = {
    kubernetes_to_transit = {
      name = vcd_nsxt_firewall_rule.rule-kubernetes-to-transit.name
      enabled = vcd_nsxt_firewall_rule.rule-kubernetes-to-transit.enabled
    }
    transit_to_kubernetes = {
      name = vcd_nsxt_firewall_rule.rule-transit_kubernetes.name
      enabled = vcd_nsxt_firewall_rule.rule-transit_kubernetes.enabled
    }
    shared_to_kubernetes = {
      name = vcd_nsxt_firewall_rule.rule-shared_kubernetes.name
      enabled = vcd_nsxt_firewall_rule.rule-shared_kubernetes.enabled
    }
    kubernetes_to_shared = {
      name = vcd_nsxt_firewall_rule.rule_kubernetes_to_shared.name
      enabled = vcd_nsxt_firewall_rule.rule_kubernetes_to_shared.enable
    }
    shared_outbound = {
      name = vcd_nsxt_firewall_rule.rule-shared-outbound.name
      enabled = vcd_nsxt_firewall_rule.rule-shared-outbound.enabled
    }
  }
}

# Application Port Profiles
output "app_port_profiles" {
  description = "Information about the Application Port Profiles"
  value = {
    http = {
      name = vcd_nsxt_app_port_profile.http.name
      id = vcd_nsxt_app_port_profile.http.id
    }
    https = {
      name = vcd_nsxt_app_port_profile.https.name
      id = vcd_nsxt_app_port_profile.https.id
    }
    api = {
      name = vcd_nsxt_app_port_profile.api.name
      id = vcd_nsxt_app_port_profile.api.id
    }
    dns = {
      name = vcd_nsxt_app_port_profile.dns.name
      id = vcd_nsxt_app_port_profile.dns.id
    }
    dhcp = {
      name = vcd_nsxt_app_port_profile.dhcp.name
      id = vcd_nsxt_app_port_profile.dhcp.id
    }
    ntp = {
      name = vcd_nsxt_app_port_profile.ntp.name
      id = vcd_nsxt_app_port_profile.ntp.id
    }
  }
}
