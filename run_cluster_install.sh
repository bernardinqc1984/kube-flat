#!/usr/bin/env bash

# Configuration des options strictes
set -euo pipefail
IFS=$'\n\t'

# Variables en lecture seule
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/../config.sh"
readonly TERRAFORM_DIR="${SCRIPT_DIR}/../bastion-env"
readonly ANSIBLE_DIR="${TERRAFORM_DIR}/ansible"

# Configuration des couleurs
readonly COLOR_INFO="\033[0;35m"
readonly COLOR_SUCCESS="\033[0;32m"
readonly COLOR_ERROR="\033[0;31m"
readonly COLOR_DIVIDER="\033[0;1m"
readonly COLOR_RESET="\033[0m"

# Configuration des outils requis
readonly REQUIRED_TOOLS=("tofu" "sed" "curl" "jq" "ansible-playbook")

# Gestion des signaux
interrupt_count=0
interrupt_handler() {
  ((interrupt_count++))
  echo ""
  if [[ ${interrupt_count} -eq 1 ]]; then
    error "Interruption détectée. Appuyez à nouveau sur Ctrl-C pour forcer l'arrêt."
  else
    error "Arrêt forcé. Au revoir !"
    exit 1
  fi
}
trap interrupt_handler SIGINT SIGTERM

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

divider() {
  printf "${COLOR_DIVIDER}============================================================================${COLOR_RESET}\n"
}

verify_last_command() {
  if [[ $? -ne 0 ]]; then
    error "Échec de la commande précédente"
    exit 1
  fi
}

check_required_tools() {
  info "Vérification des outils requis..."
  for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "${tool}" &> /dev/null; then
      error "${tool} est requis mais n'est pas installé."
      exit 1
    fi
  done
  success "Tous les outils requis sont présents."
}

cleanup_terraform() {
  local lock_file="../.terraform.lock.hcl"
  if [[ -d "../.terraform" && -f "${lock_file}" ]]; then
    info "Nettoyage des artefacts Terraform..."
    rm -rf "../.terraform" "${lock_file}"
    verify_last_command
    success "Nettoyage Terraform terminé."
  fi
}

run_step() {
  local message="$1"
  local command="$2"
  divider
  info "${message}"
  read -rsp $'Appuyez sur Entrée pour continuer (Ctrl-C pour annuler)...\n'
  eval "${command}"
  verify_last_command
  success "Étape terminée avec succès."
}

generate_configuration() {
  run_step "Génération du fichier de configuration" \
    "bash scripts/generate_config_file.sh && source ${CONFIG_FILE}"
}

generate_tfvars() {
  run_step "Génération des fichiers TFVARS" \
    "bash scripts/generate_terraform_tfvars.sh"
}

generate_inventory() {
  run_step "Génération du fichier d'inventaire Ansible" \
    "bash scripts/generate_inventory.sh"
}

generate_yaml() {
  run_step "Génération des fichiers YAML de configuration" \
    "bash scripts/generate_yaml.sh"
}

initialize_terragrunt() {
  run_step "Initialisation d'OpenTofu" \
    "bash ${TERRAFORM_DIR}/init.sh"
}

plan_infrastructure() {
  run_step "Exécution du plan Terraform" \
    "tofu -chdir=${TERRAFORM_DIR} plan -var-file=${VCD_ORG}-${DC}-${VCD_VDC}.tfvars"
}

apply_infrastructure() {
  run_step "Application de la configuration Terraform" \
    "tofu -chdir=${TERRAFORM_DIR} apply -var-file=${VCD_ORG}-${DC}-${VCD_VDC}.tfvars --auto-approve"
}

configure_ansible() {
  run_step "Configuration via Ansible" \
    "(cd ${ANSIBLE_DIR} && ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml -i inventory/${DNS_CLUSTERID}-inventory tasks/main.yml -e 'ansible_python_interpreter=/usr/bin/python3.9' -f 5)"
}

configure_bastion() {
  run_step "Configuration du serveur Bastion" \
    "(cd ${ANSIBLE_DIR} && ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml -i inventory/${DNS_CLUSTERID}-inventory bastion-vm.yml -e 'ansible_python_interpreter=/usr/bin/python3.9')"
}

configure_loadbalancer() {
  run_step "Configuration du Load Balancer" \
    "(cd ${ANSIBLE_DIR} && ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml -i inventory/${DNS_CLUSTERID}-inventory lb.yml -e 'ansible_python_interpreter=/usr/bin/python3.9')"
}

# Ajouter une fonction de nettoyage en cas d'erreur
cleanup_on_error() {
    error "Une erreur est survenue. Nettoyage..."
    # Ajouter les commandes de nettoyage nécessaires
    exit 1
}
trap cleanup_on_error ERR

# Ajouter une vérification des variables d'environnement requises
check_required_vars() {
    local required_vars=("VCD_ORG" "DC" "VCD_VDC" "DNS_CLUSTER_ID" "EXTERNAL_NETWORK_IP" "JUMPBOX_IP")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "La variable ${var} n'est pas définie"
            exit 1
        fi
    done
}

# Ajouter un système de logging
setup_logging() {
    local log_file="${SCRIPT_DIR}/cluster_install_$(date +%Y%m%d_%H%M%S).log"
    exec 1> >(tee -a "${log_file}")
    exec 2> >(tee -a "${log_file}" >&2)
}

# Ajouter une fonction de backup
backup_config() {
    local backup_dir="${SCRIPT_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${backup_dir}"
    cp -r "${CONFIG_FILE}" "${backup_dir}/"
    # Ajouter d'autres fichiers à sauvegarder si nécessaire
}

# Ajouter une vérification de l'espace disque
check_disk_space() {
    local required_space=1000000  # 1GB en KB
    local available_space=$(df -k "${SCRIPT_DIR}" | awk 'NR==2 {print $4}')
    if [[ ${available_space} -lt ${required_space} ]]; then
        error "Espace disque insuffisant. ${required_space}KB requis."
        exit 1
    fi
}

# Ajouter une vérification des versions minimales requises
check_tool_versions() {
    local min_tofu_version="1.0.0"
    local min_ansible_version="2.9.0"
    
    if ! command -v tofu &> /dev/null; then
        error "OpenTofu n'est pas installé"
        exit 1
    fi
    
    local tofu_version=$(tofu version | awk '{print $2}')
    if [[ $(echo "${tofu_version} >= ${min_tofu_version}" | bc) -eq 0 ]]; then
        error "Version d'OpenTofu trop ancienne. ${min_tofu_version} requis."
        exit 1
    fi
}

main() {
  check_required_tools
  cleanup_terraform
  generate_configuration
  run_step "Génération des templates d'installation" \
    "bash scripts/generate_install_templates.sh"
  generate_tfvars
  generate_inventory
  generate_yaml
  initialize_terragrunt
  plan_infrastructure
  apply_infrastructure
  configure_ansible
  configure_bastion
  configure_loadbalancer
  success "Installation terminée avec succès !"
  info "Accès Bastion : ssh -J $(whoami)@${EXTERNAL_NETWORK_IP}:8446 $(whoami)@${JUMPBOX_IP}"
}

# Point d'entrée
main "$@"
