variable "domain_name" {
  type        = string
  description = "The base DNS zone to add the sub zone to."
  default     = "cirrus.appcirrus.ca"
}

variable "cluster_name" {
  type        = string
  description = "This cluster id must be of max length 27 and must have only alphanumeric or hyphen characters."
}

variable "compute_count" {
  type    = number
  default = 3
}

variable "cluster_domain" {
  type = string
}


variable "hostnames_ip_addresses" {
  type = map(string)
}

variable "nfs_ip_addresses" {
  type = map(string)
}

variable "dns_addresses" {
  type = list(string)
}

variable "app_name" {
  type = string
}

variable "ignition" {
  type    = string
  default = ""
}

variable "flatcar_template" {
  type    = string
  default = ""
}

variable "vcd_vdc" {
  type = string
}

variable "vcd_org" {
  type = string
}

variable "vcd_catalog" {
  type    = string
  default = ""
}

variable "machine_cidr" {
  type    = string
  default = ""
}

variable "memory" {
  type = string
}

variable "num_cpus" {
  type = string
}

variable "compute_cpu_core" {
  type   = number
  default = 4
}

variable "disk_size" {
  type = number
}


variable "network_name" {
  type = string
}

variable "network_nfs" {
  type = string
}


variable "vm_count" {
  type = number
}

variable "mac" {
  type    = list(any)
  default = ["00:50:56:1f:03:a1", "00:50:56:1f:03:9b", "00:50:56:1f:03:a2"]
}

variable "compute_ip_addresses" {
  type    = list(any)
  default = ["172.16.1.40", "172.16.1.41", "172.16.1.42"]
}

variable "ssh_public_key" {
  type        = string
  description = "Path to your ssh public key.  If left blank we will generate one."
  default     = ""
}
