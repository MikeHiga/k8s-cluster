#!/bin/bash

# Check if the script is being run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root"
        exit 1
    fi
    echo "Script is running as root"
}

# Set version variables
set_version_variables() {
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
}

# Disable swap
disable_swap() {
    swapoff -a
    sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab
    grep "#/swap" /etc/fstab
    free -h
}

# Ensure necessary kernel modules are loaded
load_kernel_modules() {
    printf "overlay\nbr_netfilter\n" | tee /etc/modules-load.d/containerd.conf
    modprobe overlay
    modprobe br_netfilter
}

# Set required sysctl parameters for Kubernetes networking
set_sysctl_parameters() {
    printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" | tee /etc/sysctl.d/99-kubernetes-cri.conf
    sysctl --system
}

# Install containerd
install_containerd() {
    wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -P /tmp/
    tar -C /usr/local -xzvf /tmp/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
    wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable --now containerd

    # Create containerd configuration directory
    mkdir -p /etc/containerd

    # Generate default containerd configuration and edit for Kubernetes
    containerd config default | tee /etc/containerd/config.toml

    # Replace these values in the config.toml file
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

    sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3.8"|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml
}

# Install runc
install_runc() {
    wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64 -P /tmp/
    install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc
}

# Install CNI plugins
install_cni_plugins() {
    wget https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz -P /tmp/
    mkdir -p /opt/cni/bin
    tar -C /opt/cni/bin -xzvf /tmp/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz
}

# Install Kubernetes components
install_kubernetes_components() {
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
}

# Initialize Kubernetes control plane
initialize_control_plane() {
    kubeadm init --pod-network-cidr 10.10.0.0/16 --kubernetes-version ${KUBERNETES_VERSION_MajorMinorPatch} --node-name kmaster
    export KUBECONFIG=/etc/kubernetes/admin.conf
    echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> $HOME/.bashrc
    source ~/.bashrc
}

# Install Calico CNI plugin
install_calico() {
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml
    wget https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml
    sed -i 's|cidr: 192.168.0.0/16|cidr: 10.10.0.0/16|' ./custom-resources.yaml
    kubectl apply -f custom-resources.yaml
}

# Generate join command for worker nodes
generate_join_command() {
    kubeadm token create --print-join-command
}

