# config.sh

# Ansible USER
ansible_ser="your"

# General Configuration
VCD_USER="api-platform"
VCD_ORG="............."
VCD_VDC="............."
VCD_URL="............../api"
DC="qbc1/mtl1"
ENV="poc"

# External Network Configuration
EXTERNAL_NETWORK_IP="x.x.x.x"
EXTERNAL_NETWORK_NAME="ISP-x.x.x.x"

# Edge Gateway Configuration
EDGE_GATEWAY="edge_name....."
NETWORK_NAME="......." # example : vnet-kubernetes

# Networks Configuration
KUBERNETES_SUBNET="x.x.x.x"
KUBERNETES_GATEWAY="x.x.x.x"
KUBERNETES_PREFIX=24
KUBERNETES_DNS1="1.1.1.1"
KUBERNETES_DNS2="1.0.0.1"
KUBERNETES_NET=""
NFS_STORAGE_NET=""

# Shared Configuration
SHARED_SUBNET="x.x.x.x"
SHARED_GATEWAY="x.x.x.x"
SHARED_PREFIX=24
SHARED_DNS1="x.x.x.x"
SHARED_DNS2="x.x.x.x"
JUMPBOX_IP="x.x.x.x"
NS_IP="x.x.x.x"

# Transit (LB) Configuration
TRANSIT_SUBNET="x.x.x.x"
TRANSIT_GATEWAY="x.x.x.x"
TRANSIT_PREFIX=26
TRANSIT_DNS1="x.x.x.x"
TRANSIT_DNS2="x.x.x.x"
LBVIP_IP="x.x.x.x"
LB_IPS="x.x.x.x"

# Helper Configuration
HELPER_ENABLED=false
HELPER_TEMPLATE="helper-vapp"

# Firewall Configuration
FW_ALLOW_SSH_SOURCE=("x.x.x.x" "y.y.y.y" "z.z.z.z")

# Catalog Configuration
CATALOG_PaaS="...................."

# Variables for Ansible playbook
DISK="sda"
HELPER_NAME="bastion-vm"
HELPER_IPADDR="x.x.x.x"
DNS_DOMAIN="cirrus.----.--"
DNS_CLUSTER_ID="____-____"
DNS_FORWARDER1="x.x.x.x"
DNS_FORWARDER2="x.x.x.x"
DNS_SERVER_NAME="ns-____"
DNS_EMAIL="________@________.__"
LB_NAME="lb-______"
LB_IPADDR="x.x.x.x"

# DHCP Configuration
DHCP_NETWORKIFACENAME="en192"
DHCP_ROUTER="x.x.x.x"
DHCP_BCAST="x.x.x.x"
DHCP_NETMASK="x.x.x.x"
DHCP_POOLSTART="x.x.x.x"
DHCP_POOLSEND="x.x.x.x"
DHCP_IPID="ns_ip"
DHCP_NETMASKID="x.x.x.x"
DHCP_DNS="ns_ip"

# Masters Configuration (arrays)
MASTERS_NAME=("k8s-cp01" "k8s-cp02" "k8s-cp03")
MASTERS_IPADDR=("x.x.x.x" "x.x.x.x" "x.x.x.x")
MASTERS_MACADDR=("aa:aa:aa:aa:aa:aa" "aa:aa:aa:aa:aa:aa" "aa:aa:aa:aa:aa:aa")

# Worker configuration (arrays)
WORKERS_NAME=("k8s-worker01" "k8s-worker02" "k8s-worker03")
WORKERS_IPADDR=("x.x.x.x" "x.x.x.x" "x.x.x.x")
WORKERS_MACADDR=("aa:aa:aa:aa:aa:aa" "aa:aa:aa:aa:aa:aa" "aa:aa:aa:aa:aa:aa")
