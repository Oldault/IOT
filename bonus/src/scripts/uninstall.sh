#!/bin/bash

set -e

CLUSTER_NAME=svolodin

echo "Cleaning up ArgoCD GitLab configurations..."
kubectl delete secret gitlab-repo-secret -n argocd --ignore-not-found=true 2>/dev/null || true
kubectl delete -f ./src/confs/argocd-app-gitlab.yml --ignore-not-found=true 2>/dev/null || true
kubectl delete -f ./src/confs/argocd-app-project-gitlab.yml --ignore-not-found=true 2>/dev/null || true

echo "Deleting k3d cluster '$CLUSTER_NAME'..."
k3d cluster delete $CLUSTER_NAME 2>/dev/null || echo "Cluster '$CLUSTER_NAME' not found or already deleted."

echo "Uninstall complete!"
