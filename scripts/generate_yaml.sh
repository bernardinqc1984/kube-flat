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
        "DNS_CLUSTER_ID" "DISK" "HELPER_NAME" "HELPER_IPADDR"
        "DNS_DOMAIN" "DNS_CLUSTERID" "DNS_FORWARDER1" "DNS_FORWARDER2"
        "DNS_NAME" "DNS_IPPADDR" "DNS_EMAIL" "LB_NAME" "LB_IPADDR"
        "DHCP_ROUTER" "DHCP_BCAST" "DHCP_NETMASK" "DHCP_POOLSTART"
        "DHCP_POOLSEND" "DHCP_IPID" "DHCP_NETMASKID" "DHCP_DNS"
    )
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "La variable ${var} n'est pas définie dans config.sh"
            exit 1
        fi
    done
}

# Vérification des tableaux
check_arrays() {
    if [[ ${#MASTERS_NAME[@]} -eq 0 ]]; then
        error "Le tableau MASTERS_NAME est vide"
        exit 1
    fi
    if [[ ${#WORKER_NAME[@]} -eq 0 ]]; then
        error "Le tableau WORKER_NAME est vide"
        exit 1
    fi
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
check_arrays

# Configuration des chemins
readonly GROUP_VARS_DIR="../bastion-env/ansible/inventory/group_vars"
readonly VARS_DIR="../bastion-env/ansible/vars/${DNS_CLUSTER_ID}"
readonly YAML_FILE="${GROUP_VARS_DIR}/${DNS_CLUSTER_ID}.yaml"
readonly VARS_YAML_FILE="${VARS_DIR}/config.yaml"

# Création des répertoires nécessaires
for dir in "${GROUP_VARS_DIR}" "${VARS_DIR}"; do
    if [[ ! -d "${dir}" ]]; then
        info "Création du répertoire ${dir}..."
        mkdir -p "${dir}" || {
            error "Impossible de créer le répertoire ${dir}"
            exit 1
        }
    fi
done

# Fonction de génération du contenu YAML
generate_yaml_content() {
    local file="$1"
    info "Génération du fichier YAML ${file}..."

    # Sauvegarde de l'ancien fichier s'il existe
    if [[ -f "${file}" ]]; then
        readonly BACKUP_FILE="${file}.$(date +%Y%m%d_%H%M%S).bak"
        info "Sauvegarde de l'ancien fichier YAML..."
        cp "${file}" "${BACKUP_FILE}" || {
            error "Impossible de sauvegarder l'ancien fichier YAML"
            exit 1
        }
    fi

    # Génération du contenu YAML
    cat <<EOF > "${file}"
---
# Fichier généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
# Ne pas modifier manuellement

disk: ${DISK}
helper:
  name: "${HELPER_NAME}"
  ipaddr: "${HELPER_IPADDR}"
dns:
  domain: "${DNS_DOMAIN}"
  clusterid: "${DNS_CLUSTERID}"
  forwarder1: "${DNS_FORWARDER1}"
  forwarder2: "${DNS_FORWARDER2}"
  name: "${DNS_NAME}"
  ipaddr: "${DNS_IPPADDR}"
  email: "${DNS_EMAIL}"
lb:
  name: "${LB_NAME}"
  ipaddr: "${LB_IPADDR}"
dhcp:
  networkifacename: "ens192"
  router: "${DHCP_ROUTER}"
  bcast: "${DHCP_BCAST}"
  netmask: "${DHCP_NETMASK}"
  poolstart: "${DHCP_POOLSTART}"
  poolend: "${DHCP_POOLSEND}"
  ipid: "${DHCP_IPID}"
  netmaskid: "${DHCP_NETMASKID}"
  dns: "${DHCP_DNS}"
masters:
EOF

    # Génération des masters
    for i in "${!MASTERS_NAME[@]}"; do
        cat <<EOF >> "${file}"
  - name: "${MASTERS_NAME[$i]}"
    ipaddr: "${MASTERS_IPADDR[$i]}"
    macaddr: "${MASTERS_MACADDR[$i]}"
EOF
    done

    # Génération des workers
    cat <<EOF >> "${file}"
workers:
EOF
    for i in "${!WORKER_NAME[@]}"; do
        cat <<EOF >> "${file}"
  - name: "${WORKERS_NAME[$i]}"
    ipaddr: "${WORKERS_IPADDR[$i]}"
    macaddr: "${WORKERS_MACADDR[$i]}"
EOF
    done
}

# Génération des fichiers YAML
generate_yaml_content "${YAML_FILE}"
generate_yaml_content "${VARS_YAML_FILE}"

success "Les fichiers YAML ont été générés avec succès"
info "Fichiers générés :"
info "  - ${YAML_FILE}"
info "  - ${VARS_YAML_FILE}"