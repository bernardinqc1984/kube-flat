pipeline {
    agent any

    environment {
        // Variables d'environnement globales
        TERRAFORM_VERSION = '1.5.7'
        TOFU_VERSION = '1.5.7'
        ANSIBLE_VERSION = '2.9.27'
        PYTHON_VERSION = '3.9'
        WORKSPACE_DIR = "${WORKSPACE}"
        CONFIG_DIR = "${WORKSPACE}/config"
        BASTION_ENV_DIR = "${WORKSPACE}/bastion-env"
        SCRIPTS_DIR = "${WORKSPACE}/scripts"
    }

    options {
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
    }

    stages {
        stage('Préparation') {
            steps {
                script {
                    // Vérification des prérequis
                    sh '''
                        #!/bin/bash
                        set -euo pipefail
                        
                        # Vérification des outils requis
                        command -v tofu >/dev/null 2>&1 || { echo "OpenTofu n'est pas installé"; exit 1; }
                        command -v ansible >/dev/null 2>&1 || { echo "Ansible n'est pas installé"; exit 1; }
                        command -v python3 >/dev/null 2>&1 || { echo "Python3 n'est pas installé"; exit 1; }
                        
                        # Vérification des versions
                        tofu version | grep -q "${TOFU_VERSION}" || { echo "Version d'OpenTofu incorrecte"; exit 1; }
                        ansible --version | grep -q "${ANSIBLE_VERSION}" || { echo "Version d'Ansible incorrecte"; exit 1; }
                        python3 --version | grep -q "${PYTHON_VERSION}" || { echo "Version de Python incorrecte"; exit 1; }
                    '''
                }

                // Nettoyage du workspace
                sh '''
                    #!/bin/bash
                    set -euo pipefail
                    
                    # Sauvegarde des fichiers de configuration existants
                    if [ -d "${CONFIG_DIR}" ]; then
                        tar -czf "${WORKSPACE_DIR}/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C "${CONFIG_DIR}" .
                    fi
                    
                    # Nettoyage des fichiers temporaires
                    find . -type f -name "*.tfstate*" -delete
                    find . -type f -name "*.tfvars" -delete
                    find . -type f -name "*.config" -delete
                '''
            }
        }

        stage('Configuration') {
            steps {
                // Génération des fichiers de configuration
                sh '''
                    #!/bin/bash
                    set -euo pipefail
                    
                    # Création du répertoire de configuration
                    mkdir -p "${CONFIG_DIR}"
                    
                    # Copie des fichiers de configuration
                    cp "${WORKSPACE_DIR}/config.sh" "${CONFIG_DIR}/"
                    
                    # Génération des fichiers de configuration
                    cd "${SCRIPTS_DIR}"
                    ./generate_config_file.sh
                    ./generate_terraform_tfvars.sh
                    ./generate_inventory.sh
                    ./generate_yaml.sh
                '''
            }
        }

        stage('Infrastructure') {
            steps {
                // Initialisation et application de l'infrastructure
                sh '''
                    #!/bin/bash
                    set -euo pipefail
                    
                    # Initialisation d'OpenTofu
                    cd "${BASTION_ENV_DIR}"
                    tofu init
                    
                    # Planification
                    tofu plan -var-file="${VCD_ORG}-${DC}-${VCD_VDC}.tfvars" -out=tfplan
                    
                    # Application
                    tofu apply -auto-approve tfplan
                '''
            }
        }

        stage('Configuration Ansible') {
            steps {
                // Configuration via Ansible
                sh '''
                    #!/bin/bash
                    set -euo pipefail
                    
                    # Configuration du serveur Bastion
                    cd "${BASTION_ENV_DIR}/ansible"
                    ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml \
                                  -i inventory/${DNS_CLUSTERID}-inventory \
                                  bastion-vm.yml \
                                  -e 'ansible_python_interpreter=/usr/bin/python3.9'
                    
                    # Configuration du Load Balancer
                    ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml \
                                  -i inventory/${DNS_CLUSTERID}-inventory \
                                  lb.yml \
                                  -e 'ansible_python_interpreter=/usr/bin/python3.9'
                    
                    # Configuration principale
                    ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml \
                                  -i inventory/${DNS_CLUSTERID}-inventory \
                                  tasks/main.yml \
                                  -e 'ansible_python_interpreter=/usr/bin/python3.9'
                '''
            }
        }

        stage('Vérification') {
            steps {
                // Vérification de l'infrastructure
                sh '''
                    #!/bin/bash
                    set -euo pipefail
                    
                    # Vérification de l'état de l'infrastructure
                    cd "${BASTION_ENV_DIR}"
                    tofu show
                    
                    # Vérification des services
                    cd "${BASTION_ENV_DIR}/ansible"
                    ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml \
                                  -i inventory/${DNS_CLUSTERID}-inventory \
                                  verify.yml \
                                  -e 'ansible_python_interpreter=/usr/bin/python3.9'
                '''
            }
        }
    }

    post {
        always {
            // Nettoyage et archivage
            sh '''
                #!/bin/bash
                set -euo pipefail
                
                # Archivage des fichiers de configuration
                tar -czf "${WORKSPACE_DIR}/config_${BUILD_NUMBER}.tar.gz" \
                    -C "${CONFIG_DIR}" .
                
                # Archivage des logs
                tar -czf "${WORKSPACE_DIR}/logs_${BUILD_NUMBER}.tar.gz" \
                    -C "${WORKSPACE_DIR}" \
                    *.log
            '''
        }

        success {
            echo "Déploiement réussi !"
        }

        failure {
            echo "Échec du déploiement. Consultez les logs pour plus de détails."
        }
    }
} 