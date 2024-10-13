# Set up with QEMU/KVM and Virt-Manager

To install **QEMU/KVM with Virt-Manager** on your Arch Linux machine, follow these steps:

## Step 1: Install QEMU, KVM, and Virt-Manager

Run the following command to install the necessary packages:

```bash
sudo pacman -S qemu virt-manager libvirt edk2-ovmf dnsmasq vde2 bridge-utils openbsd-netcat
```

- **`qemu`**: The core virtualization software.
- **`virt-manager`**: A graphical tool to manage VMs.
- **`libvirt`**: A virtualization API used by Virt-Manager.
- **`edk2-ovmf`**: Provides UEFI support for VMs (important for running UEFI guests).
- **`dnsmasq`**: Lightweight DNS forwarder for managing network configurations.
- **`vde2`, `bridge-utils`, and `openbsd-netcat`**: Networking utilities to manage virtual network interfaces.

## Step 2: Enable and Start libvirt Service

Once the packages are installed, you need to start and enable the `libvirtd` service, which is responsible for managing your virtual machines.

1. Start the `libvirtd` service:

   ```bash
   sudo systemctl start libvirtd
   ```

2. Enable the `libvirtd` service to start on boot:

   ```bash
   sudo systemctl enable libvirtd
   ```

3. Verify the service status to ensure it's running properly:

   ```bash
   sudo systemctl status libvirtd
   ```

## Step 3: Add Your User to the `libvirt` Group

To manage VMs without needing root privileges, add your user to the `libvirt` group:

```bash
sudo usermod -aG libvirt $USER
```

You may need to log out and log back in for this change to take effect.

## Step 4: Configure UEFI (Optional but Recommended)

If you plan to run virtual machines using UEFI (for example, modern Linux distributions), you'll need to configure the OVMF firmware:

1. Open the **Virt-Manager** application.
2. When creating a new virtual machine, under **Firmware** settings, select `UEFI` from the **Firmware** options.

This will allow your VMs to boot in UEFI mode using `edk2-ovmf`.

## Step 5: Launch Virt-Manager

Now, you can launch `virt-manager` either from the terminal or through your system's application menu:

```bash
virt-manager
```

This will open the graphical interface where you can create, configure, and manage your virtual machines.

## Optional: Enable Bridged Networking (if needed)

If you want to use bridged networking so your VMs can appear on the same network as your host machine, you need to configure it:

1. Edit the network configuration file:

   ```bash
   sudo nano /etc/libvirt/qemu/networks/default.xml
   ```

2. Change the `<forward mode='nat'/>` line to:

   ```xml
   <forward mode='bridge'/>
   ```

3. Restart the libvirtd service:

   ```bash
   sudo systemctl restart libvirtd
   ```
