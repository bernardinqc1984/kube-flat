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
    local required_vars=("VCD_ORG" "DC" "VCD_VDC" "ENV" "VDC")
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

# Création du répertoire de destination si nécessaire
readonly CONFIG_DIR="../bastion-env"
if [[ ! -d "${CONFIG_DIR}" ]]; then
    info "Création du répertoire ${CONFIG_DIR}..."
    mkdir -p "${CONFIG_DIR}" || {
        error "Impossible de créer le répertoire ${CONFIG_DIR}"
        exit 1
    }
fi

# Génération du fichier de configuration
readonly CONFIG_FILE="${CONFIG_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.config"
info "Génération du fichier de configuration ${CONFIG_FILE}..."

# Sauvegarde de l'ancien fichier s'il existe
if [[ -f "${CONFIG_FILE}" ]]; then
    readonly BACKUP_FILE="${CONFIG_FILE}.$(date +%Y%m%d_%H%M%S).bak"
    info "Sauvegarde de l'ancien fichier de configuration..."
    cp "${CONFIG_FILE}" "${BACKUP_FILE}" || {
        error "Impossible de sauvegarder l'ancien fichier de configuration"
        exit 1
    }
fi

# Génération du nouveau fichier de configuration
cat <<EOF > "${CONFIG_FILE}"
# Configuration générée automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
# Ne pas modifier manuellement

# Désactivation des logs Terraform
unset TF_LOG
unset TF_LOG_PATH

# Variables d'environnement
CIRRUS_ENV=${ENV}
VCD_ORG=${VCD_ORG}
VCD_VDC=${VCD_VDC}
CIRRUS_DC=${DC}

# Configuration du backend S3
export BUCKET=openshift-terraform-$CIRRUS_ENV
export KEY=${VCD_ORG}-${CIRRUS_DC}-${VDC}/terraform.tfstate
export AWS_REGION=$CIRRUS_DC
export AWS_ACCESS_KEY_ID=<key id>
export AWS_SECRET_ACCESS_KEY=<secret key>
export AWS_S3_ENDPOINT=https://cirrus-plateforme.os-qc1.cirrusproject.ca

# Variables Terraform
export TF_VAR_vcd_pass='<vcd password>'
VAR_FILE="${VCD_ORG}-${CIRRUS_DC}-${VDC}.tfvars"
export TF_CLI_ARGS_plan="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_apply="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_destroy="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_import="-var-file=${VAR_FILE}"
EOF

if [[ $? -eq 0 ]]; then
    success "Le fichier de configuration a été généré avec succès"
else
    error "Erreur lors de la génération du fichier de configuration"
    exit 1
fi