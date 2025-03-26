variable "temp_pass" {}
variable "vapp_name" {}
variable "name" {}
variable "catalog_name" {
  type    = string
  default = "Catalog"
}
variable "template_name" {
  type    = string
  default = "Rocky Linux 8.5 - EN"
}
variable "network_name" {}
variable "os_type" {
  type    = string
  default = "centos8_64Guest"
}
variable "memory" {
  type    = number
  default = 1 * 1024
}
variable "cpus" {
  type    = number
  default = 1
}
variable "power_on" {
  type    = bool
  default = false
}
variable "ip" {
  type    = list(any)
  default = []
}
variable "initscript" {}

variable "vm_count" {
  type    = number
  default = 1
}
