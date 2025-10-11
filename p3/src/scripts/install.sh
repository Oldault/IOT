#!/bin/sh

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    curl -s https://get.docker.com | sh
    sudo usermod -aG docker $USER
    sudo usermod -aG docker svolodin
fi

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

k3d cluster create $USER

kubectl config use-context k3d-$USER