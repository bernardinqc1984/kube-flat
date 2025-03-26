terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.11"
    }
    tls = {
      source = "hashicorp/tls"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
    vcd = {
      source  = "vmware/vcd"
      version = "3.8.0"
    }
    #    ignition = {
    #       source = "community-terraform-providers/ignition"
    #       version = "2.1.6"
    #    }
  }
  required_version = ">= 1.3.0"
}
