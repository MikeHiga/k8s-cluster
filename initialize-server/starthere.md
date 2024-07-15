# Steps for VMs

## Copy necessary files needed for networking

Make sure the template image contains these files in `/etc/netplan`

* 00-installer-usedhcp.yaml
* 01-static_ip.yaml.bak

## Install These Packages

```sh
sudo apt install neofetch neovim btop
```
