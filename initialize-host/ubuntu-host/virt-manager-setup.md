# Setup Host Environment

## Install Virt-Manager

* Install Debian on your physical machine.

* Update your system:

    ```sh
    sudo apt update && sudo apt upgrade -y
    ```

* Install required packages for virtualization:

    ```sh
    sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y
    ```

## Configuring Bridge Network in Virt-Manager

1. Create a Bridge Interface on the Host:

   * First, you need to create a bridge interface on your host machine. This can be done by editing the network interfaces configuration file.
   * Create a new network interfaces configuration file `br0.cfg`:

       ```sh
       sudo vim /etc/network/interfaces.d/
       ```

   * Add the following configuration for the bridge (assuming your primary network interface is enp8s0):

       ```sh
       auto br0
       iface br0 inet dhcp
           bridge_ports enp8s0
           bridge_stp off
           bridge_fd 0
           bridge_maxwait 0
       ```

   * Restart networking services:

       ```sh
       sudo systemctl restart networking
       ```

1. Configure VMs to Use the Bridge Network:

    * Open Virt-Manager and select the VM you want to configure.
    * Go to the VM’s **Details** view.
    * In the **NIC** settings, change the network source to **`Bridge`** and select the bridge interface **`br0`** created earlier.
    * Ensure that the **Device Model** is set to **`virtio`** for better performance.
    * Apply the changes and repeat for each VM.

1. Verify Configuration:

    * Start your VMs and SSH into each one.
    * Check the network configuration to ensure that each VM has received an IP address from the same network as the host.

    ```sh
    ip a
    ```
