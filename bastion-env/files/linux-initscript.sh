#!/bin/bash

# Function to create users with ssh key

create_users() {
  local username=$1
  local group=$2
  local ssh_key=$3

  # Checked if users already exist
  if id "$username" &>/dev/null; then
     echo "The user $username already exist."
     return
  fi

  # Create the user
  useradd -m -s /bin/bash -g $group $username
  if [ $? -ne 0 ]; then
    echo "Failed to create the user $username."
    exit 1
  fi

  # configuration of the .ssh directory and authorized_keys file
  local home_dir="/home/$username"
  local ssh_dir="$home_dir/.ssh"
  local authorized_keys="$ssh_dir/authorized_keys"

  if [ ! -f $authorized_keys ]; then
    mkdir -p $ssh_dir
    echo $ssh_key > $authorized_keys
    chown -R $username:$group $ssh_dir
    chmod 700 $ssh_dir
    chmod 600 $authorized_keys
  fi

  # Adding sudo rights without password
  echo "$username ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$username"
  chmod 0440 "/etc/sudoers.d/$username"

  echo "User $username created successfully."
}

# Check the variables
if [ "$1" = "precustomization" ]; then
  echo "Pre-customization script started........."
  echo "Pre-customization script completed........."

elif [ "$1" = "postcustomization" ]; then
  echo "Post-customization script started........."

  # Installation et enabling ssh service
  dnf install -y openssh-server
  systemctl enable sshd
  systemctl start sshd

# Create k8s group
  groupadd k8s || echo "The group k8s already exist."

# Users list with their ssh key
  declare -A users=(
    ["cirrus"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3z1Z.................."
    ["czogbelemou"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3z1Z.................."
    ["mcharette"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3z1Z.................."
  )

# Loop to create the users
  for user in "${!users[@]}"; do
    create_users $user k8s "${users[$user]}"
  done

  echo "Post-customization script completed........."
else
  echo "Usage: $0 [precustomization|postcustomization]"
  exit 1
fi

exit 0
  