#!/bin/sh

CLUTER_NAME=svolodin

docker ps &>/dev/null
rc=$?
if [ $rc -ne 0 ]; then
    echo "Docker not found. Installing Docker..."
    curl -s https://get.docker.com | sh
    usermod -aG docker $USER
fi

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.0.0 bash

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

k3d cluster delete $CLUTER_NAME
k3d cluster create $CLUTER_NAME --port "8888:80@loadbalancer"

kubectl config use-context k3d-$CLUTER_NAME