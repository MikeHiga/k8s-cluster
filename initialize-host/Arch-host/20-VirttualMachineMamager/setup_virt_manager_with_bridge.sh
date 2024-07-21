#!/bin/bash

# Update the system
sudo pacman -Syu

# Install Virt-Manager and Dependencies
sudo pacman -S --needed virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat

# Install Linux Headers
sudo pacman -S --needed linux-headers

# Install Base Development Tools
sudo pacman -S --needed base-devel

# Install OVMF for UEFI Support (Optional)
sudo pacman -S --needed edk2-ovmf

# Install dmidecode
sudo pacman -S --needed dmidecode

# Enable and Start libvirtd Service
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service

# Add User to libvirt Group
sudo usermod -aG libvirt $(whoami)

# Disable systemd-resolved Service (if running)
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved.service

# Create a minimal dnsmasq configuration
echo "
# /etc/dnsmasq.conf

# Enable the DHCP server, but disable DNS functionality
port=0

# Interface to bind to (replace with your interface, e.g., eth0)
interface=br0

# Enable DHCP
dhcp-range=192.168.0.10,192.168.0.50,12h
" | sudo tee /etc/dnsmasq.conf

# Enable and Start dnsmasq and iptables Services
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq
sudo systemctl enable iptables
sudo systemctl start iptables

# Create bridge network files
echo "
[NetDev]
Name=br0
Kind=bridge
" | sudo tee /etc/systemd/network/bridge-br0.netdev

echo "
[Match]
Name=br0

[Network]
Address=192.168.1.31/24
Gateway=192.168.1.1
DNS=192.168.1.1
" | sudo tee /etc/systemd/network/br0.network

echo "
[Match]
Name=enp8s0

[Network]
Bridge=br0
" | sudo tee /etc/systemd/network/enp8s0.network

# Restart systemd-networkd service
sudo systemctl restart systemd-networkd

# Enable systemd-resolved Service again
sudo systemctl enable systemd-resolved.service
sudo systemctl start systemd-resolved.service

# Reboot the System
echo "Rebooting the system to apply changes..."
sudo reboot

