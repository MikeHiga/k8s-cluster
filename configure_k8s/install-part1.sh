#!/bin/bash

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

# Rest of the script
echo "Script is running as root"

# Set version variables
KMAJOR="1"
KMINOR="30"
KPATCH="3"
KREV="1.1"
KUBERNETES_VERSION_MajorMinor="${KMAJOR}.${KMINOR}"
KUBERNETES_VERSION_MajorMinorPatch="${KMAJOR}.${KMINOR}.${KPATCH}"
KUBERNETES_VERSION_MajorMinorPatch_Revision="${KMAJOR}.${KMINOR}.${KPATCH}-${KREV}"
CONTAINERD_VERSION="1.7.2"
RUNC_VERSION="1.1.7"
CNI_PLUGINS_VERSION="1.5.1"
CALICO_VERSION="v3.28.0"

swapoff -a
sudo sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab
grep "#/swap" /etc/fstab

# check swap config, ensure swap is 0. (-h show human-readable output)
free -h

# Ensure the necessary kernel modules are loaded at boot
printf "overlay\nbr_netfilter\n" | tee /etc/modules-load.d/containerd.conf

# Load the kernel modules now
modprobe overlay
modprobe br_netfilter

# Set required sysctl parameters for Kubernetes networking
printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" | tee /etc/sysctl.d/99-kubernetes-cri.conf

# Apply the sysctl settings
sysctl --system

# Download and extract containerd
wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -P /tmp/

tar -C /usr/local -xzvf /tmp/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# Download and configure the containerd systemd service
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /etc/systemd/system/

systemctl daemon-reload

systemctl enable --now containerd

# Download and install runc
wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64 -P /tmp/

install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc

# Download and install CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz -P /tmp/

mkdir -p /opt/cni/bin

tar -C /opt/cni/bin -xzvf /tmp/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz

# Create containerd configuration directory
mkdir -p /etc/containerd

# Generate default containerd configuration and edit for Kubernetes
containerd config default | tee /etc/containerd/config.toml

# Replace these values in the config.toml file
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml

# Restart containerd to apply configuration changes
systemctl restart containerd

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

# Install specific versions of kubelet, kubeadm, and kubectl
# apt-get install -y kubelet=${KUBERNETES_VERSION_MajorMinorPatch_Revision} kubeadm=${KUBERNETES_VERSION_MajorMinorPatch_Revision} kubectl=${KUBERNETES_VERSION_MajorMinorPatch_Revision}

# Let the installer decide what version to install.
apt-get install -y kubelet kubeadm kubectl

# Mark the Kubernetes packages to hold them at the installed version
apt-mark hold kubelet kubeadm kubectl

### Initialize the Kubernetes Control Plane (Only on Control Node)

# Initialize the Kubernetes control plane with a specific pod network CIDR and Kubernetes version
# Also, set the node name to kmaster
kubeadm init --pod-network-cidr 10.10.0.0/16 --kubernetes-version ${KUBERNETES_VERSION_MajorMinorPatch} --node-name kmaster

#### RUN THIS COMMAND TO GET RID OF THOSE STUPID LOCALHOST:8080 ERRORS!!!
# Set the KUBECONFIG environment variable to use the admin.conf file for kubectl commands
export KUBECONFIG=/etc/kubernetes/admin.conf


# Add the var into the root's .bashrc file
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> $HOME/.bashrc

source ~/.bashrc

### Installing Calico CNI Plugin  (Only on Control Node)
#### Apply the Tigera operator for Calico
# Apply the Tigera operator for Calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml

# Download the custom resources for Calico configuration
wget https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml

# Edit the custom-resources.yaml file to set the CIDR for pods if necessary
# Change cidr: to 10.10.0.0/16 because that's what we set it to when initializing kubeadm
sed -i 's|cidr: 192.168.0.0/16|cidr: 10.10.0.0/16|' ./custom-resources.yaml

# Apply the Calico custom resources configuration
kubectl apply -f custom-resources.yaml

#### Obtaining Join Command for Worker Nodes
# Generate and print the command to join additional nodes to the cluster
kubeadm token create --print-join-command

