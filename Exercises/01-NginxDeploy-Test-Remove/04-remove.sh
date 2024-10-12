#!/bin/bash

kubectl delete svc nginx
kubectl delete deployment nginx

kubectl get deployments
kubectl get pods
