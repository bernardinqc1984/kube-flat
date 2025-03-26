// ID identifying the cluster to create. Use your username so that resources created can be tracked back to you.

cluster_name = "kube-stab"

// Base domain from which the cluster domain is a subdomain.
base_domain = "cirrus.appcirrus.ca"

// Name of the VDC.
vcd_vdc = "vdc-0037"

// User on the vSphere servers.
vcd_user = "api-platform"

// Name of the VCD organization. Found on the VCD console, Data Centers tab
vcd_org = "cirrusdev"

// url for the vcd. (this is dal)
vcd_url = "https://vcloud-qbc1.cirrusproject.ca/api"

// Edge Gateway name
edge_gateway = "QBC1 CIRRUSDEV Edge"

vcd_external_network_ip = "10.255.50.66"

vcd_allow_unverified_ssl = true

// Name of the vcd Catalog
vcd_catalog = "Kubernetes ova"

// DNS
dns_addresses = ["10.15.0.2", "10.15.0.3"]

// The number of control plane VMs to create. Default is 3.
control_plane_count = 3
control_disk        = "100"

// The IP addresses to assign to the control plane VMs. The length of this list
// must match the value of control_plane_count.
control_plane_ip_addresses = ["10.16.144.33", "10.16.144.34", "10.16.144.35"]


// The number of compute VMs to create. Default is 3.
compute_count = 3
compute_disk  = 100

// The IP addresses to assign to the compute VMs. The length of this list must
// match the value of compute_count.
compute_ip_addresses     = ["10.16.144.36", "10.16.144.37", "10.16.144.38"]
nfs_compute_ip_addresses = ["172.16.20.115", "172.16.20.115", "172.16.20.115"]

flatcar_version = "stable"
// Name of the RHCOS VM template to clone to create VMs for the cluster
flatcar_template = "flatcar_production_vmware_ova"

control_plane_mac_address     = ["00:50:56:1f:03:a4", "00:50:56:1f:03:a8", "00:50:56:1f:03:a6"]
compute_compute_mac_addresses = ["00:50:56:1f:03:a1", "00:50:56:1f:03:9b", "00:50:56:1f:03:a2"]
