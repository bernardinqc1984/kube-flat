#!/bin/bash

# Script to generate install.yaml.tmpl files for controllers and workers
# This script should be run from the root directory of the project

# Function to generate the template content
generate_template() {
    local type=$1
    local output_file=$2
    
    cat > "$output_file" << 'EOL'
---
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      password_hash: $y$j9T$CtGIbNZlD9CntbkyGeMUR-----------
      groups:
        - docker
      ssh_authorized_keys:
        - "ssh-rsa PUBLIC_KEY"
storage:
  files:
    # Configure automatic updates without rebooting
    - path: /etc/flatcar/update.conf
      overwrite: true
      contents:
        inline: |
          REBOOT_STRATEGY=off
      mode: 0420 # Read-only for root
EOL

    # Add resolv.conf only for controllers
    if [ "$type" = "controllers" ]; then
        cat >> "$output_file" << 'EOL'
    - path: /etc/resolv.conf
      overwrite: true
      contents:
        inline: |
          nameserver 8.8.8.8
          nameserver 8.8.4.4
      mode: 0644 # Readable by all users
EOL
    fi

    cat >> "$output_file" << 'EOL'
    - path: /etc/motd.d/pi.conf
      mode: 0644
      contents:
        inline: This machine is dedicated to computing kubernetes

systemd:
  units:
    - name: getty@.service
      dropins:
        - name: 10-autologin.conf
          contents: |
            [Service]
            ExecStart=
            ExecStart=-/sbin/agetty --noclear %I $TERM
EOL
}

# Main script execution
echo "Generating install.yaml.tmpl files..."

# Generate controller template
generate_template "controllers" "controllers/install.yaml.tmpl"
echo "Generated controllers/install.yaml.tmpl"

# Generate worker template
generate_template "workers" "workers/install.yaml.tmpl"
echo "Generated workers/install.yaml.tmpl"

echo "Template generation completed successfully!" 