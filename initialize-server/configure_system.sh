#!/bin/bash

# Check if the correct number of arguments is passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <SourceIP> <TargetIP> <NewHostName>"
    exit 1
fi

# Assign positional parameters to variables
SourceIP=$1
TargetIP=$2
NewHostName=$3

# Update the hostname if it's different
current_hostname=$(cat /etc/hostname)
if [ "$current_hostname" != "$NewHostName" ]; then
    echo -e "$NewHostName" | sudo tee /etc/hostname
fi

# Function to append to /etc/hosts if the entry does not exist
append_to_hosts() {
    local ip=$1
    local hostname=$2
    if ! grep -q "$ip $hostname" /etc/hosts; then
        echo "$ip $hostname" | sudo tee -a /etc/hosts
    fi
}

# Append the new lines to /etc/hosts only if they do not exist
append_to_hosts "192.168.1.100" "kmaster"
append_to_hosts "192.168.1.110" "kworker01"
append_to_hosts "192.168.1.111" "kworker02"

# Backup and rename netplan configuration files only if not already backed up
if [ -f /etc/netplan/00-installer-usedhcp.yaml ] && [ ! -f /etc/netplan/00-installer-usedhcp.yaml.bak ]; then
    sudo mv /etc/netplan/00-installer-usedhcp.yaml /etc/netplan/00-installer-usedhcp.yaml.bak
fi

if [ -f /etc/netplan/10-static_ip.yaml.bak ] && [ ! -f /etc/netplan/10-static_ip.yaml ]; then
    sudo mv /etc/netplan/10-static_ip.yaml.bak /etc/netplan/10-static_ip.yaml
fi

# Update the IP address in the netplan configuration file only if the source IP exists
if grep -q "$SourceIP" /etc/netplan/10-static_ip.yaml; then
    sudo sed -i "s/$SourceIP/$TargetIP/" /etc/netplan/10-static_ip.yaml
fi

# Display the updated netplan configuration
sudo cat /etc/netplan/10-static_ip.yaml

# Reset the machine ID only if it exists
if [ -f /etc/machine-id ]; then
    sudo rm /etc/machine-id
    sudo systemd-machine-id-setup
fi

# Remove old SSH host keys only if they exist
if ls /etc/ssh/ssh_host_* 1> /dev/null 2>&1; then
    sudo rm /etc/ssh/ssh_host_*
    sudo dpkg-reconfigure openssh-server
fi
