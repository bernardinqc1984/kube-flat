#!/bin/bash

# Configuration des options strictes
set -euo pipefail
IFS=$'\n\t'

# Configuration des couleurs pour les messages
readonly COLOR_INFO="\033[0;35m"
readonly COLOR_SUCCESS="\033[0;32m"
readonly COLOR_ERROR="\033[0;31m"
readonly COLOR_RESET="\033[0m"

# Fonctions utilitaires
info() {
    printf "${COLOR_INFO}INFO: %s${COLOR_RESET}\n" "$1"
}

success() {
    printf "${COLOR_SUCCESS}SUCCESS: %s${COLOR_RESET}\n" "$1"
}

error() {
    printf "${COLOR_ERROR}ERROR: %s${COLOR_RESET}\n" "$1" >&2
}

# Vérification des variables d'environnement requises
check_required_vars() {
    local required_vars=(
        "VCD_ORG" "DC" "VCD_VDC" "VCD_USER" "VCD_PASSWORD" "VCD_URL"
        "VCD_ALLOW_UNVERIFIED_SSL" "VCD_EXTERNAL_NETWORK_IP" "VCD_EXTERNAL_NETWORK_NAME"
        "EDGE_GATEWAY" "NETWORK_NAME" "KUBERNETES_SUBNET" "KUBERNETES_GATEWAY"
        "KUBERNETES_PREFIX" "KUBERNETES_DNS1" "KUBERNETES_DNS2" "SHARED_SUBNET"
        "SHARED_GATEWAY" "SHARED_PREFIX" "SHARED_DNS1" "SHARED_DNS2" "JUMPBOX_IP"
        "NS_IP" "TRANSIT_SUBNET" "TRANSIT_GATEWAY" "TRANSIT_PREFIX" "TRANSIT_DNS1"
        "TRANSIT_DNS2" "HELPER_ENABLED" "HELPER_TEMPLATE" "LBVIP_IP" "LB_IPS"
        "CATALOG_PaaS"
    )
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "La variable ${var} n'est pas définie dans config.sh"
            exit 1
        fi
    done
}

# Vérification de l'existence du fichier config.sh
if [[ ! -f "config.sh" ]]; then
    error "Le fichier config.sh n'existe pas"
    exit 1
fi

# Chargement des variables depuis config.sh
info "Chargement des variables depuis config.sh..."
source ./config.sh || {
    error "Erreur lors du chargement de config.sh"
    exit 1
}

# Vérification des variables requises
check_required_vars

# Configuration des chemins
readonly TFVARS_DIR="../bastion-env"
readonly TFVARS_FILE="${TFVARS_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars"

# Création du répertoire si nécessaire
if [[ ! -d "${TFVARS_DIR}" ]]; then
    info "Création du répertoire ${TFVARS_DIR}..."
    mkdir -p "${TFVARS_DIR}" || {
        error "Impossible de créer le répertoire ${TFVARS_DIR}"
        exit 1
    }
fi

# Sauvegarde de l'ancien fichier s'il existe
if [[ -f "${TFVARS_FILE}" ]]; then
    readonly BACKUP_FILE="${TFVARS_FILE}.$(date +%Y%m%d_%H%M%S).bak"
    info "Sauvegarde de l'ancien fichier tfvars..."
    cp "${TFVARS_FILE}" "${BACKUP_FILE}" || {
        error "Impossible de sauvegarder l'ancien fichier tfvars"
        exit 1
    }
fi

# Génération du fichier tfvars
info "Génération du fichier tfvars ${TFVARS_FILE}..."

cat <<EOF > "${TFVARS_FILE}"
# Fichier généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
# Ne pas modifier manuellement

# Configuration VCD
vcd_user = "${VCD_USER}"
vcd_org = "${VCD_ORG}"
vcd_vdc = "${VCD_VDC}"
vcd_password = "${VCD_PASSWORD}"
vcd_url = "${VCD_URL}"
vcd_allow_unverified_ssl = "${VCD_ALLOW_UNVERIFIED_SSL}"

# Configuration réseau externe
vcd_external_network_ip = "${VCD_EXTERNAL_NETWORK_IP}"
vcd_external_network_name = "${VCD_EXTERNAL_NETWORK_NAME}"

# Configuration Edge Gateway
edge_gateway = "${EDGE_GATEWAY}"

# Configuration réseau Kubernetes
network_name = "${NETWORK_NAME}"
kubernetes_subnet = "${KUBERNETES_SUBNET}"
vcd_network_gateway = "${KUBERNETES_GATEWAY}"
vcd_network_prefix = "${KUBERNETES_PREFIX}"
vcd_network_dns1 = "${KUBERNETES_DNS1}"
vcd_network_dns2 = "${KUBERNETES_DNS2}"

# Configuration réseau partagé
shared_subnet = "${SHARED_SUBNET}"
shared_gateway = "${SHARED_GATEWAY}"
shared_prefix = "${SHARED_PREFIX}"
shared_dns1 = "${SHARED_DNS1}"
shared_dns2 = "${SHARED_DNS2}"
jumpbox_ip = "${JUMPBOX_IP}"
ns_ip = "${NS_IP}"

# Configuration réseau transit
transit_subnet = "${TRANSIT_SUBNET}"
transit_gateway = "${TRANSIT_GATEWAY}"
transit_prefix  = "${TRANSIT_PREFIX}"
transit_dns1    = "${TRANSIT_DNS1}"
transit_dns2    = "${TRANSIT_DNS2}"

# Configuration helper et load balancer
helper_enabled = "${HELPER_ENABLED}"
helper_template = "${HELPER_TEMPLATE}"
lbvip_ip = "${LBVIP_IP}"
lb_ips = "${LB_IPS}"

# Configuration des règles de pare-feu
fw_allow_ssh_source = ${FW_ALLOW_SSH_SOURCE[@]}

# Configuration du catalogue
catalog_paas = "${CATALOG_PaaS}"
EOF

if [[ $? -eq 0 ]]; then
    success "Le fichier tfvars a été généré avec succès"
    info "Fichier généré : ${TFVARS_FILE}"
else
    error "Erreur lors de la génération du fichier tfvars"
    exit 1
fi
