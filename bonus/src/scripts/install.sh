#!/bin/bash

set -e

CLUSTER_NAME=svolodin

echo "Setting up k3d cluster '$CLUSTER_NAME'..."
if k3d cluster list | grep -q "^$CLUSTER_NAME "; then
    echo "Cluster '$CLUSTER_NAME' already exists. Deleting it first..."
    k3d cluster delete $CLUSTER_NAME
fi

echo "Creating k3d cluster '$CLUSTER_NAME'..."
k3d cluster create $CLUSTER_NAME --image rancher/k3s:v1.30.10-k3s1 --port "8888:80@loadbalancer"

echo "Cluster '$CLUSTER_NAME' created successfully!"