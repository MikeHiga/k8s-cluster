# Build My K8S Cluster

|Software|version|URL|
|---|---|---|
|UBUNTU SERVER|22.04.4 LTS (Jammy Jellyfish)|https://ubuntu.com/download/server|
|KUBERNETES|1.30.3|https://kubernetes.io/releases/|
|CONTAINERD|1.7.2|https://containerd.io/releases/|
|RUNC|1.1.7|https://github.com/opencontainers/runc/releases|
|CNI PLUGINS|1.5.1|https://github.com/containernetworking/plugins/releases|
|CALICO CNI|3.28.0|https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart|

## Cluster Node Specs

Each node has the same specs

* 4 vCPU
* 8 GB RAM
* 50GB Disk EACH

|Server Name|Static IP|
|---|---|
|kmaster|192.168.1.100|
|kworker01|192.168.1.110|
|kworker02|192.168.1.111|

## Do this to all Nodes

### Switch to root

**I'm running with `sudo -i` because it provides a clean root environment, reducing the risk of environment-related issues.**

```sh
sudo -i
```

```sh
# Set version variables
KMAJOR="1"
KMINOR="30"
KUBERNETES_VERSION_MajorMinor="${KMAJOR}.${KMINOR}"
CONTAINERD_VERSION="1.7.2"
RUNC_VERSION="1.1.7"
CNI_PLUGINS_VERSION="1.5.1"
CALICO_VERSION="v3.28.0"
```

### Turn off swap

```sh
swapoff -a
sudo sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab
grep "#/swap" /etc/fstab

# check swap config, ensure swap is 0. (-h show human-readable output)
free -h
```

### Load Kernel Modules

Ensure the necessary kernel modules are loaded first, as they are prerequisites for the networking setup and container runtime.

```sh
# Ensure the necessary kernel modules are loaded at boot
printf "overlay\nbr_netfilter\n" | tee /etc/modules-load.d/containerd.conf

# Load the kernel modules now
modprobe overlay
modprobe br_netfilter
```

### Configure Sysctl for Kubernetes Networking

Set up the required networking parameters for Kubernetes.

```sh
# Set required sysctl parameters for Kubernetes networking
printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" | tee /etc/sysctl.d/99-kubernetes-cri.conf

# Apply the sysctl settings
sysctl --system
```

### Install Containerd

Install and configure the container runtime.

```sh
# Download and extract containerd
wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -P /tmp/

tar -C /usr/local -xzvf /tmp/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# Download and configure the containerd systemd service
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /etc/systemd/system/

systemctl daemon-reload

systemctl enable --now containerd
```

### Install runc

Install the runc runtime component.

```sh
# Download and install runc
wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64 -P /tmp/

install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc
```

### Install CNI Plugins

Install the Container Network Interface (CNI) plugins required for Kubernetes networking.

```sh
# Download and install CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz -P /tmp/

mkdir -p /opt/cni/bin

tar -C /opt/cni/bin -xzvf /tmp/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz
```

### Configure Containerd

Generate and edit the containerd configuration to set SystemdCgroup to true for Kubernetes compatibility.

```sh
# Create containerd configuration directory
mkdir -p /etc/containerd

# Generate default containerd configuration and edit for Kubernetes
containerd config default | tee /etc/containerd/config.toml
```

### Manually edit config.toml

```sh
# Manually edit /etc/containerd/config.toml to change SystemdCgroup to true
nvim /etc/containerd/config.toml
```

```sh
# Replace these values in the config.toml file
sed 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml | sudo tee /etc/containerd/config.toml > /dev/null

sed 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml | sudo tee /etc/containerd/config.toml > /dev/null
```

### Restart containerd

```sh
# Restart containerd to apply configuration changes
systemctl restart containerd
```

### Add Kubernetes APT Repository

Set up the Kubernetes APT repository and install necessary packages.

```sh
# Update package index and install prerequisites
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes apt repository keyring
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION_MajorMinor}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


# Add Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION_MajorMinor}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Update package index
apt-get update
```

### Reboot the System

***Reboot the system to apply all changes and ensure the new configuration is fully loaded.***

### Reboot the system to apply all changes

```sh
reboot
```

---

## Steps after reboot

### Switching to Root User

```sh
# Switch to the root user
sudo -i
```

***<span style='color: red;'>STOP RIGHT HERE!! Re-initilize the variables that hold version information.</span>***

```sh
# Re-set version variables
KMAJOR="1"
KMINOR="30"
KPATCH="3"
KREV="1.1"
KUBERNETES_VERSION_MajorMinorPatch="${KMAJOR}.${KMINOR}.${KPATCH}"
KUBERNETES_VERSION_MajorMinorPatch_Revision="${KMAJOR}.${KMINOR}.${KPATCH}-${KREV}"
CALICO_VERSION="v3.28.0"
```

### Installing Kubernetes Components

```sh
# Install specific versions of kubelet, kubeadm, and kubectl
# apt-get install -y kubelet=${KUBERNETES_VERSION_MajorMinorPatch_Revision} kubeadm=${KUBERNETES_VERSION_MajorMinorPatch_Revision} kubectl=${KUBERNETES_VERSION_MajorMinorPatch_Revision}

# Let the installer decide what version to install.
apt-get install -y kubelet kubeadm kubectl

# Mark the Kubernetes packages to hold them at the installed version
apt-mark hold kubelet kubeadm kubectl
```

### Initialize the Kubernetes Control Plane (Only on Control Node)

```sh
# Initialize the Kubernetes control plane with a specific pod network CIDR and Kubernetes version
# Also, set the node name to kmaster
kubeadm init --pod-network-cidr 10.10.0.0/16 --kubernetes-version ${KUBERNETES_VERSION_MajorMinorPatch} --node-name kmaster
```

### RUN THIS COMMAND TO GET RID OF THOSE STUPID LOCALHOST:8080 ERRORS!!!

#### For Root user

```sh
# Set the KUBECONFIG environment variable to use the admin.conf file for kubectl commands
export KUBECONFIG=/etc/kubernetes/admin.conf
```

#### For Non-Root user

To allow a non-root user to access the cluster, follow these steps:

1. Copy admin.conf to the User's Home Directory:

    ```sh
    mkdir -p $HOME/.kube/
    sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

1. Set the KUBECONFIG Environment Variable:

    ```sh
    export KUBECONFIG=$HOME/.kube/config
    ```

1. Optional: Add to Shell Profile:
To make this change persistent across sessions, add the export command to your shell profile (e.g., .bashrc or .bash_profile):

    ```sh
    echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
    source ~/.bashrc
    ```

### Installing Calico CNI Plugin  (Only on Control Node)

#### Apply the Tigera operator for Calico

```sh
# Apply the Tigera operator for Calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml

# Download the custom resources for Calico configuration
wget https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml
```

#### Edit the custom-resources.yaml

```sh
# Edit the custom-resources.yaml file to set the CIDR for pods if necessary
# Change cidr: to 10.10.0.0/16 because that's what we set it to when initializing kubeadm
nvim custom-resources.yaml
```

#### Apply the Calico custom resources configuration

```sh
# Apply the Calico custom resources configuration
kubectl apply -f custom-resources.yaml
```

#### Obtaining Join Command for Worker Nodes

```sh
# Generate and print the command to join additional nodes to the cluster
kubeadm token create --print-join-command
```

---

## ONLY ON WORKER Nodes

Run the command from the token create output. `kubeadm token create --print-join-command`

## Run these on the controller

```sh
# These commands will lable the worker nodes.
kubectl label node kworker01 node-role.kubernetes.io/worker=worker
kubectl label node kworker02 node-role.kubernetes.io/worker=worker
```

### Notes

* The `--node-name` value is correctly set to `kmaster` during the Kubernetes control plane initialization.
* The version numbers are set as variables at the beginning of both parts of the procedure (before and after reboot).
* Ensure that you update the versions in the table and script if newer versions are required or available.
* Review each command and ensure it aligns with your infrastructure and environment settings.
