//////
// VMWare Cloud Director variables
//////

# variables

variable "vcd_vdc" {
  type        = string
  description = "This is the vcd vdc for the environment."
}

variable "vcd_user" {
  type        = string
  description = "This is the vcd user."
}

variable "vcd_pass" {
  type        = string
  description = "This is the vcd password for the environment."
}

variable "vcd_org" {
  type        = string
  description = "This is the vcd org string from the console for the environment."
}

variable "vcd_url" {
  type        = string
  description = "This is the vcd url for the environment."
}

variable "vcd_catalog" {
  type        = string
  description = "This is the vcd catalog to use for the environment."
  default     = ""
}

variable "vcd_logging" {
  default = false
}

variable "flatcar_template" {
  type        = string
  description = "This is the name of the RHCOS template to clone."
  default     = ""
}

/////////
// Kubernetes cluster variables
/////////

variable "cluster_name" {
  type        = string
  description = "This cluster id must be of max length 27 and must have only alphanumeric or hyphen characters."
}

variable "base_domain" {
  type        = string
  description = "The base DNS zone to add the sub zone to."
  default     = "cirrus.appcirrus.ca"
}

/////////
// Extra config
/////////


variable "kubernetes_cluster_cidr" {
  type = string
}

variable "kubernetes_service_cidr" {
  type = string
}

variable "flatcar_version" {
  type        = string
  description = "Specify the Openshift version that you would like to deploy."
}

///////////
// control-plane machine variables
///////////

variable "control_plane_mac_address" {
  type    = list(string)
  default = []
}

variable "dns_addresses" {
  type        = list(string)
  description = "List of DNS servers to use for your OpenShift Nodes"
}

variable "control_plane_ip_addresses" {
  type    = list(string)
  default = []
}
variable "control_plane_count" {
  type    = string
  default = "3"
}

variable "machine_cidr" {
  type = string
}

variable "ssh_public_key" {
  type        = string
  description = "Path to your ssh public key.  If left blank we will generate one."
  default     = ""
}

variable "control_plane_memory" {
  type    = string
  default = "16384"
}

variable "control_plane_num_cpus" {
  type    = string
  default = "6"
}

variable "control_plane_cpu_core" {
  type    = number
  default = 2
}

variable "control_disk" {
  type    = string
  default = ""
}

/////////
// Worker Nodes machines variables
/////////

variable "compute_compute_mac_addresses" {
  type    = list(string)
  default = []
}

variable "compute_ip_addresses" {
  type    = list(string)
  default = []
}

variable "compute_count" {
  type    = number
  default = 4
}

variable "compute_memory" {
  type    = number
  default = 32768
}

variable "compute_num_cpus" {
  type    = number
  default = 8
}

variable "compute_cpu_core" {
  type    = number
  default = 4
}


variable "compute_disk" {
  type    = number
  default = 100
}


variable "vcd_external_network_ip" {
  type = string
}

variable "kubernetes_host_prefix" {
  type    = string
  default = 24
}

variable "vcd_allow_unverified_ssl" {
  default = true
}

# Common variables
variable "edge_gateway" {
  type = string
}

variable "path_wrk" {
  type    = string
  default = "."
}

variable "nfs_compute_ip_addresses" {
  type = list(string)
}

