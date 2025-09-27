#!/bin/sh

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://$2:6443 --token $1 --node-ip $3" sh -s -
