// ID identifying the cluster to create. Use your username so that resources created can be tracked back to you.

cluster_name = "kube"

// Base domain from which the cluster domain is a subdomain.
base_domain = "-------------"

// Name of the VDC.
vcd_vdc = "-------"

// User on the vSphere servers.
vcd_user = "------------"

// Name of the VCD organization. Found on the VCD console, Data Centers tab
vcd_org = "crusddev"

// url for the vcd. (this is dal)
vcd_url = "https://.........................../api"

// Edge Gateway name
edge_gateway = "edge---"

vcd_external_network_ip = "xx.xx.xx.xx"

vcd_allow_unverified_ssl = true

// Name of the vcd Catalog
vcd_catalog = "-------------"

// DNS
dns_addresses = ["xx.xx.xx.xx", "xx.xx.xx.xx"]

// The number of control plane VMs to create. Default is 3.
control_plane_count = 3
control_disk        = "100"

// The IP addresses to assign to the control plane VMs. The length of this list
// must match the value of control_plane_count.
control_plane_ip_addresses = ["xx.xx.xx.xx", "xx.xx.xx.xx", "xx.xx.xx.xx"]


// The number of compute VMs to create. Default is 3.
compute_count = 3
compute_disk  = 100

// The IP addresses to assign to the compute VMs. The length of this list must
// match the value of compute_count.
compute_ip_addresses     = ["xx.xx.xx.xx", "xx.xx.xx.xx", "xx.xx.xx.xx"]
nfs_compute_ip_addresses = ["xx.xx.xx.xx", "xx.xx.xx.xx", "xx.xx.xx.xx"]

flatcar_version = "stable"
// Name of the RHCOS VM template to clone to create VMs for the cluster
flatcar_template = "flatcar_production_vmware_ova"

control_plane_mac_address     = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
compute_compute_mac_addresses = ["aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff", "aa:bb:cc:dd:ee:ff"]
