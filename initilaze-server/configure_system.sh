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

# Update the hostname
echo -e "$NewHostName" | sudo tee /etc/hostname

# Append the new lines to /etc/hosts using sudo tee
echo -e "\n192.168.1.100 kmaster\n192.168.1.110 kworker01\n192.168.1.111 kworker02\n" | sudo tee -a /etc/hosts

# Backup and rename netplan configuration files
sudo mv /etc/netplan/00-installer-usedhcp.yaml /etc/netplan/00-installer-usedhcp.yaml.bak
sudo mv /etc/netplan/10-static_ip.yaml.bak /etc/netplan/10-static_ip.yaml

# Update the IP address in the netplan configuration file
sudo sed -i "s/$SourceIP/$TargetIP/" /etc/netplan/10-static_ip.yaml

# Display the updated netplan configuration
sudo cat /etc/netplan/10-static_ip.yaml

# Reset the machine ID
sudo rm /etc/machine-id
sudo systemd-machine-id-setup

# Remove old SSH host keys
sudo rm /etc/ssh/ssh_host_*

# Reconfigure the SSH server to generate new host keys
sudo dpkg-reconfigure openssh-server
