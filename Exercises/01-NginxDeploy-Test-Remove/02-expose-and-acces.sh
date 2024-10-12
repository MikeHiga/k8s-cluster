#!/bin/bash

# Get the name of the master/control-plane node
MASTER_NODE_NAME=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')

# If the above selector doesn't work, try the 'master' role label
if [ -z "$MASTER_NODE_NAME" ]; then
    MASTER_NODE_NAME=$(kubectl get nodes --selector='node-role.kubernetes.io/master' -o jsonpath='{.items[0].metadata.name}')
fi

# Get the internal IP address of the master node
MASTER_IP=$(kubectl get node "$MASTER_NODE_NAME" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

# Expose the deployment and create the service if it's not already exposed
kubectl expose deployment nginx --port=80 --type=NodePort --dry-run=client -o yaml | kubectl apply -f -

# Capture the NodePort
NODE_PORT=$(kubectl get service nginx -o=jsonpath='{.spec.ports[0].nodePort}')

# Construct the URL
URL="http://$MASTER_IP:$NODE_PORT"

# Echo the URL
echo "Your Nginx service is available at: $URL"
