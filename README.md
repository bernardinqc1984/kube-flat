# Pré-requis
S'assurer d'avoir OpenTofu d'installer sur votre poste de Travail

* Installation de OpenTofu via Homebrew sur MacOS
````shell
brew update
brew install opentofu
````

* Install de OpenTofu sur Linux
````shell
# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method rpm

````

# Déployer Kubernetes

* Tenant cirrus-dev
* **cluster_name**: cluster_name
* **vcd**: vdc-0037
* **domaine**: appcirrus.ca
* **Gateway external network ip**: 63.135.171.71
* **Gateway external network name**: ISP-63.135.171.0

## VM

| hostname  | ip        | OS      | role                       | vCPU | RAM   | Disque | power_on |
|:----------| :-------- | :----   | :------------------------- |:-----|:------| :----- | :------- |
| master0   |172.16.1.34| Flatcar | Control plane              | 6    | 16 GB | 100 GB | false    |
| master1   |172.16.1.36| Flatcar | Control plane              | 6    | 16 GB | 100 GB | false    |
| master2   |172.16.1.42| Faltcar | Control plane              | 6    | 16 GB | 100 GB | false    |
| worker0   |172.16.1.38| Flatcar | node                       | 8    | 32 GB | 100 GB | false    |
| worker1   |172.16.1.32| Flatcar | node                       | 8    | 32 GB | 100 GB | false    |
| worker2   |172.16.1.42| Flatcar | node                       | 8    | 32 GB | 100 GB | false    |

## Edge / VDC

* 1 network nonrouted 172.16.1.1/24.
  * Organisation Name: cirrusdev
  * Gateway CIDR: 172.16.0.10/24./24
  * Shared: off. (à revoir avec infra)
  * Interface type: Internal.
  * Guest VLAN Allowed: Off. 
  * Notes:
    * Le choix du réseau principal 172.16.1.1/24 a été fait pour être en phase avec les recommandations de l'infra et de ce qui se fait du côté de Openshift.
    


### Firewall

| Name     | Source                            | Destination | Service | Action | Enabled logging |
| :------- |:----------------------------------| :---------- | :------ | :----- | :-------------- |
| Outbound | vnet-kubernetes                   | external    | Any     | Accept | Off             |
| Jumpbox  | `whitelist ou Any, (voir note)`   | external    | Any     | Accept | Off             |

Note: Pour le SSH (port 22) Nous l'avons remplacé par le port (8446), idéalement nous y accéderions via un VPN.

### NAT

Simplement pour que les serveurs aient accès à internet.

| Action | Applied On | Oridinal IP/Range   | Protocol | Original Port | Translated range | Translated Port | Source IP Address | Source Port | Description  |
| :----- | :--------- |:--------------------| :------- |:--------------|:-----------------|:----------------| :---------------- | :---------- |:-------------|
| SNAT   | `ISP`      | 172.16.0.1/24       | Any      | Any           | `ISP ip`         | Any             | N/A               | N/A         | Outbound     |
| DNAT   | `ISP`      | `ISP ip`            | TCP      | 8445          | 172.16.0.10      | 22 (8446)       | N/A               | N/A         | ssh          |
| DNAT   | `ISP`      | `ISP ip`            | TCP      | 6443          | 172.16.0.10      | 6443            | N/A               | N/A         | API          |
| DNAT   | `ISP`      | `ISP ip`            | TCP      | 80            | 172.16.0.10      | 80              | N/A               | N/A         | HTTP         |
| DNAT   | `ISP`      | `ISP ip`            | TCP      | 443           | 172.16.0.10      | 443             | N/A               | N/A         | HTTPS        |

Note: Pour le SSH (port 22), idéalement nous y accéderions via un VPN.

## Terraform

* Exécuter terraform

* * Charger les variables d'environnement dont on a besoin
````
cd cirrus.kubernetes-vcd/bastion-en/terraform
source cirrusdev-qbc1-vdc-0037.config
````

⚠️ Le fichier **cirrusdev-qbc1-vdc-0037.config** contient les informations sur le user/password vcloud permettant de créer les ressources (Disques, Cpu et autres),
ainsi que le Bucket S3 dédié au stockage du fichier tfstate.
Nous avons besoin de sourcer ce fichier pour s'assurer du bon déroulement de la suite de l'installation.


* * Initialiser les paramètres de Terraform (Tofu)
````
./init.sh (pour charger les modules terraform qu'on a défini et dont on a besoin)
````
Ce script utilise la commande **tofu init** pour charger tous les modules nécessaires pour le déploiement, ainsi que les variables d'environnements.



* * Exécuter le programme d'installation de la machine qui servira de Bastion

````
tofu fmt ; tofu validate && tofu plan (si il n'y a aucune erreur)

tofu apply
````
⚠️ Tester votre connection ssh sur les VMs (À partir de sshs)


````mermaid
---
title: Schéma Cirrus Services Kubernetes
---
stateDiagram-v2
    Edge --> LB: DNAT 80/443/6443/9000
    LB --> Edge: Any
    Edge --> Shared: DNAT ssh 8446(22)
    LB --> Shared
    Shared --> Edge: Any
    LB --> K8S: tcp 6443/80/443
    K8S --> LB: Any
    state LB {
        [*] --> Haproxy
    }
    state Shared {
        Jumpbox --> NS: tcp ssh(22)
        NS --> Kubernetes: tcp ssh(22)
    }
    state K8S {
        Kubernetes
    }

````

## Ansible
1. La VM Jumpbox de l'infra est la première à s'installer er à démarrer ensuite la VM NS et enfin La VM LB
2. Le ansible nous permet de configurer les différentes VM, Mettre à jour et installer tous les paquets nécessaires, 
   3. **VM NS** :  Ici, seront installés et configurés
         4. **Named** (pour le gestion du DNS)
         5. **DHCP** pour l'octroi des adresses IPs aux VMs du Cluster Kubernetes
         6. **Apache** et **tftp** Pour la livraison des fichiers de configuration ignition
   7. **VM LB** : Sera installé et configuré sur cette VM Haproxy qui servira d'équilibreur de charge pour les controls plane et Worker nodes du cluster Kubernetes
3. Déployer en mode `power_on=false` masters et workers qui seront démarrés grâce à un script.
4. Démarrer la node bootstrap.
5. Une fois que son status est up, valider le status

## Configuration du NS 

Note: Utilise actuellement une image custom ova de Rocky Linux vierge.

Nous utilisons Ansible pour configurer le NS. Pour cela vous devez vous assurez d'avoir docker sur votre poste de travail.
Contruire l'image nécessaire contenant ansible pour exécuter cette tâche.

* Contruire l'image ansible contenant les bonnes information
  * Préalable:
    * Se positionner dans le repertoire ansible 
    * ````shell
      cd cirrus-kubernetes/bastion-env/ansible
      ````
    * Puis y copiez-coller vos clés ssh : id_rsa id_rsa.pub
  * Ici vous avez un fichier Dockerfile qui vous permettra de construire votre image
    * ````shell
      docker build -t ansible:2.9.27_rockylinux_python39-2 .
      ````
      
* Modifier le fichier inventaire 
Configuration
Dans le répertoire ansible/inventory, il y a un fichier inventory par **NS**. 
En le spécifiant comme paramètre -i **inventory/inventory-<tenant>-<dc>-<vdc>**, 
c'est ce qui fait en sorte qu'ansible se connectera au bon NS.
Il faut également créer un fichier ansible/inventory/host_vars/<helper ip>.yaml où il y a une configuration spécifique pour l'installation. Créer et l'ajuster selon les besoins.

*Maintenant vous allez pouvoir configurer le server NS

* Configuration générale
  * ````shell
    docker run --rm -it -v $(pwd)/ansible:/opt/ansible ansible:2.9.27 -e @vars/ocpdev-2/config.yaml -i generate_inventory.sh/openshift_dev-2-qbc1-vdc-openshift_dev-Ocp tasks/main.yml -vvv
    ````
* Configuration du NS
  * ``````shell
    docker run --rm -it -v $(pwd)/ansible:/opt/ansible ansible:2.9.27 -e @vars/ocpdev-2/config.yaml -i generate_inventory.sh/openshift_dev-2-qbc1-vdc-openshift_dev-Ocp bastion-vm.yml -vvv
    ``````
Ansible sur le NS node configure le DNS, PXE, DHCP, HAProxy et Apache

## Configuration du LB

Maintenant nous allons configurer le LB en utilisant la même méthode

````shell
docker run --rm -it -v $(pwd)/ansible:/opt/ansible ansible:2.9.27 -e @vars/ocpdev-2/config.yaml -i generate_inventory.sh/openshift_dev-2-qbc1-vdc-openshift_dev-Ocp lb.yml -vvv
````

Une fois les VMs **Jumpbox**, le **NS** et le **LB** installés, nous allons pouvoir procéder à l'installation des VMs Flatcar dédiées à l'exécution de Kubernetes.

Pour cela, nous allons nous connecter à la VM **NS** à travers l'utilitaire **sshs**, une fois connecté à la VM **NS**, nous allons cloner le repos courant:

⚠️ Cette url sera différente quand ce code sera transféré sur le git de cirrus.
````shell
git clone https://gitlab.com/projet_cirrus/paas/cirrus-kubernetes-vcd.git && cd cirrus-kubernetes-vcd

````
On source le fichier de conf comme précedemment
````shell
source cirrusdev-qbc1-vdc-0037.config
````

⚠️ Le fichier **cirrusdev-qbc1-vdc-0037.config** contient les informations sur le user/password vcloud permettant de créer les resources (Disques, Cpu et autres),
ainsi que le Bucket S3 dédié au stockage du fichier tfstate.
Nous avon besoin de sourcer ce fichier pour s'assurer du bon déroulement de la suite de l'installation.


* * Initialiser les paramètres de Terraform (Tofu)
````
./init.sh (pour charger les modules terraform qu'on a défini et dont on a besoin)
````
Ce scritpt utilise la commande **tofu init** pour charger tous les modules nécessaires pour le déploiement, ainsi que les variables d'environnements.



* * Exécuter le programme d'installation de la machine qui servira de Bastion

````
tofu fmt ; tofu validate && tofu plan (si il n'y a aucune erreur)

tofu apply
````

Une fois que les VMs sont installés, seul 3 personnes ont les droits root sur les VMs Flatcar (mcharette, cruiz, czogbelemou).

## Installer Kubernetes sur Flatcar
* Télécharger le programme ansible qui permettra d'installer Kubernetes sur Flatcar
  * ``````shell
    wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.24.1.tar.gz
    ``````
  * Décompresser l'archive précédemment téléchargé
  * ``````shell
    tar xvf v2.24.1.tar.gz
    ``````
⚠️ Nous avons choisi spécifiquement cette version du fait de la version de Flatcar qui est actuellement de **3815.2.3**.
Cette version de Flatcar embarque les versions de paquets suivants :

* Versions des paquets de Flatcar :
  * **containerd - 1.7.13**
  * docker - 24.0.9
  * ignition - 2.15.0
  * kernel - 6.1.90

* Versions des paquets supportés par kubespray-v2.24.1
  * kubernetes v1.28.6
  * etcd v3.5.10
  * docker v20.10 
  * **containerd v1.7.13**

Nous voyons ici que les versions de Containerd correspondent et donc nous avons la bonne version de kubespray.

#### Installation de Kubernetes
* Créer le fichier inventaire, contenant les informations des VMs Flatcar afin qu'ansible puisse s'y connecter et exécuter les opérations nécessaires.
  * se positionner dans le répertoire kubespray-v2.24.1
    * ``````shell
      cd kubespray-v2.24.1
      ``````
    * Puis faire une copie de l'inventaire existant pour le modifier ensuite
      * ``````shell
        cp -rfp generate_inventory.sh/sample generate_inventory.sh/k8scluster
        ``````
      * Modifier le fichier inventaire
        * ``````shell
          vim generate_inventory.sh/k8scluster/generate_inventory.sh.ini
          # ## Configure 'ip' variable to bind kubernetes services on a
          # ## different ip than the default iface
          # ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
          [all]
          k8s-master01 ansible_host=172.16.1.20 etcd_member_name=etcd1  ansible_user=core
          k8s-master02 ansible_host=172.16.1.21 etcd_member_name=etcd2  ansible_user=core
          k8s-master03 ansible_host=172.16.1.22 etcd_member_name=etcd3  ansible_user=core
          k8s-worker01 ansible_host=172.16.1.40 etcd_member_name=       ansible_user=core
          k8s-worker02 ansible_host=172.16.1.41 etcd_member_name=       ansible_user=core
          k8s-worker03 ansible_host=172.16.1.42 etcd_member_name=       ansible_user=core

          [kube_control_plane]
          k8s-master01
          k8s-master02
          k8s-master03

          [etcd]
          k8s-master01
          k8s-master02
          k8s-master03

          [kube_node]
          k8s-worker01
          k8s-worker02
          k8s-worker03
          k8s-worker04

          [calico_rr]

          [k8s_cluster:children]
          kube_control_plane
          kube_node
          ``````

* Ensuite il faut indiquer où déposer les binaires nécessaires à l'installation de Kubernetes. Et le seul endroit sur Flatcar pour ce faire est
  * ``````shell
    /opt/bin
    ``````
* Nous allons donc apporté les modifications nécessaires aux variables du Playbook ansible.
  * ``````shell
     vim generate_inventory.sh/k8scluster/group_vars/all/all.yml
     bin_dir: /opt/bin
    ``````
* Exécution du Playbook ansible
  * ``````shell
    ansible-playbook -i generate_inventory.sh/k8scluster/generate_inventory.sh.ini  --become --become-user=root cluster.yml
    ``````
## NFS
Les VMs (Workers Nodes) sont configurés pour se connecter au Network NFS. En revanche n'ayant pas la commande **mount.nfs** dans Flatcar, les 3 personnes citées ci-dessus peuvent se connecter
à un des workers nodes  :
* Se connecter à un des worker depuis le serveur **[NS]**
  * ````shell
    ssh core@k8s@worker[0,1,2]
    ````
* Puis exécuter la commande suivante
  * ````shell
    mkdir -p /opt/nfs && mount 172.16.20.13:/cirrusdev-dev /opt/nfs
    ````

Un fois le répertoire **[/opt/nfs]** monté, vous pouvez créer les répertoires dont vous avez besoin et y mettre les bons droits.
ensuite créer des PVs qui pointent vers ces répertoires. Example ci dessous:
* Le répertoire racine est :
  * ````shell
    /cirrudev-dev
    ````
* Les répertoires créés sont vault-dev avec des sous-répertoires **[vault-data-0, vault-data-1, vault-data-2]**


````yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-vault-0
  namespace: vault
  labels:
    cirrus: volume-for-vault
    strorage.k8s.io/name: netapp
    role: data
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: cirrus-nfs-storage
  nfs:
    path: /cirrusdev-dev/vault-dev/data-vault-0
    server: 172.16.20.13
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-vault-1
  namespace: vault
  labels:
    cirrus: volume-for-vault
    strorage.k8s.io/name: netapp
    role: data
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: cirrus-nfs-storage
  nfs:
    path: /cirrusdev-dev/vault-dev/data-vault-1
    server: 172.16.20.13
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-vault-2
  namespace: vault
  labels:
    cirrus: volume-for-vault
    strorage.k8s.io/name: netapp
    role: data
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: cirrus-nfs-storage
  nfs:
    path: /cirrusdev-dev/vault-dev/data-vault-2
    server: 172.16.20.13
````






