#!/bin/bash

# Source the functions script
source ./functions.sh

# Main function to orchestrate the script execution
main() {
    check_root
    set_version_variables
    disable_swap
    load_kernel_modules
    set_sysctl_parameters
    install_containerd
    install_runc
    install_cni_plugins
    install_kubernetes_components

    # Check if this is a controller node
    if [ "$1" == "controller" ]; then
        initialize_control_plane
        install_calico
        generate_join_command
    fi
}

# Execute the main function with the first argument as a parameter
main $1

