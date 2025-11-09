#!/bin/bash

set -e

CLUSTER_NAME=svolodin

echo "Checking Docker installation..."
if ! docker ps &>/dev/null; then
    echo "Docker not found or not running. Installing Docker..."
    curl -s https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
else
    echo "Docker is already installed and running."
fi

echo "Checking k3d installation..."
if ! command -v k3d &>/dev/null; then
    echo "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.0.0 bash
else
    echo "k3d is already installed ($(k3d version | head -1))."
fi

echo "Checking kubectl installation..."
if ! command -v kubectl &>/dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl is already installed ($(kubectl version --client --short 2>/dev/null || kubectl version --client))."
fi

echo "Setting up k3d cluster '$CLUSTER_NAME'..."
if k3d cluster list | grep -q "^$CLUSTER_NAME "; then
    echo "Cluster '$CLUSTER_NAME' already exists. Deleting it first..."
    k3d cluster delete $CLUSTER_NAME
fi

echo "Creating k3d cluster '$CLUSTER_NAME'..."
k3d cluster create $CLUSTER_NAME --port "8888:80@loadbalancer"

echo "Cluster '$CLUSTER_NAME' created successfully!"