#!/bin/bash

set -e

CLUSTER_NAME=svolodin

echo "Uninstalling Argo CD applications..."
kubectl delete -f ./src/confs/argocd-app.yml --ignore-not-found=true 2>/dev/null || true
kubectl delete -f ./src/confs/argocd-app-project.yml --ignore-not-found=true 2>/dev/null || true
kubectl delete -f ./src/confs/ingress.yml --ignore-not-found=true 2>/dev/null || true

echo "Uninstalling Argo CD..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found=true 2>/dev/null || true

echo "Deleting ingress configurations..."
kubectl delete -f ./src/confs/argocd-ingress.yml --ignore-not-found=true 2>/dev/null || true

echo "Deleting namespaces..."
kubectl delete -f ./src/confs/namespaces.yml --ignore-not-found=true 2>/dev/null || true

echo "Deleting k3d cluster '$CLUSTER_NAME'..."
k3d cluster delete $CLUSTER_NAME 2>/dev/null || echo "Cluster '$CLUSTER_NAME' not found or already deleted."

echo "Pruning Docker resources..."
docker system prune -a -f
docker volume prune -f

echo "Uninstall complete!"
