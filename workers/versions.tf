terraform {
  required_providers {
    template = {
      source = "hashicorp/template"
    }
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.11"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
    ignition = {
      source = "community-terraform-providers/ignition"
    }
    vcd = {
      source = "vmware/vcd"
    }
  }
  required_version = ">= 0.13"
}
