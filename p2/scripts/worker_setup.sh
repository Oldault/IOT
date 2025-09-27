#!/bin/sh

if ! command -v docker >/dev/null 2>&1; then
    sudo apk update
    sudo apk add docker
    sudo service docker start
    sudo rc-update add docker boot
else
    echo "Docker already installed."
fi

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://$2:6443 --token $1 --node-ip $3" sh -s -
