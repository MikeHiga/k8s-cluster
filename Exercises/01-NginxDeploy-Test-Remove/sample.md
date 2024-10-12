# Run Nginx in Kubernetes

Here's what this excercize will do.

1. I want to run nginx
1. I want to access it from my host
1. I want to remove it

## Deploying Nginx on Kubernetes
First, let's deploy Nginx as a simple pod. We'll then expose it as a service so you can access it from your host machine.

Step 1: Create an Nginx Deployment
You can create an Nginx deployment using the following kubectl command:

```bash
kubectl create deployment nginx --image=nginx
```

This command creates a deployment named nginx that runs an Nginx container.

Step 2: Verify the Deployment
Check if the deployment was created and the pod is running:

```bash
kubectl get deployments
kubectl get pods
```

You should see a deployment named nginx and a corresponding pod running.

## Exposing Nginx Service

To access the Nginx server from your host machine, you need to expose the deployment as a service. For simplicity, we'll use a NodePort service, which makes the service accessible on a port on the host machine's IP address.

Step 1: Expose the Deployment

Run the following command to expose the Nginx deployment:

```bash
kubectl expose deployment nginx --port=80 --type=NodePort
```

This command creates a service that maps port 80 of the Nginx pod to a randomly selected high port (in the range 30000-32767) on each node in the cluster.

Step 2: Get the NodePort

Find out which port was assigned to the service:

```bash
kubectl get svc nginx
```

Look for the NodePort in the output. It will be in the format 80:<NodePort>/TCP, where <NodePort> is the port number you need to use.

Step 3: Access Nginx from the Host

Now, you can access Nginx from your host machine by navigating to http://<node-ip>:<NodePort> in your web browser, where <node-ip> is the IP address of any node in your Kubernetes cluster, and <NodePort> is the port number you found in the previous step.

For example, if the node IP is 192.168.1.100 and the NodePort is 31703, you'd navigate to:

```http
http://192.168.1.100:31703
```

You should see the default Nginx welcome page.

## Cleaning Up: Remove the Nginx Deployment
Once you’re done, you can remove the Nginx deployment and the service to clean up your cluster.

Step 1: Delete the Service
First, delete the service you created:

```bash
kubectl delete svc nginx
```

Step 2: Delete the Deployment

Then, delete the deployment:

```bash
kubectl delete deployment nginx
```

These commands will remove the Nginx service and deployment from your cluster, cleaning up all resources associated with them.

## Summary

1. Deploy Nginx:
   * kubectl create deployment nginx --image=nginx
1. Expose it as a Service:
   * kubectl expose deployment nginx --port=80 --type=NodePort
1. Access Nginx from the Host:
   * Navigate to http://<node-ip>:<NodePort>
1. Clean Up:
   * kubectl delete svc nginx
   * kubectl delete deployment nginx

These steps should help you deploy a simple Nginx server on your Kubernetes cluster, access it from your host machine, and remove it when you're done.

