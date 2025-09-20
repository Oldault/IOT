#!/bin/sh

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token $1 --node-ip $2

for i in $(seq 1 60); do
    if [ -f /var/lib/rancher/k3s/server/node-token ]; then
        break
    fi
    sleep 1
done

if [ ! -f /var/lib/rancher/k3s/server/node-token ]; then
    echo "Error: K3s token not created – aborting"
    exit 1
fi

sudo chmod a+r /etc/rancher/k3s/k3s.yaml
cp /var/lib/rancher/k3s/server/node-token /vagrant/config/k3s_token.txt

if ! curl -k -s https://127.0.0.1:6443/version >/dev/null; then
    echo "Warning: local API endpoint not responding" >&2
fi

echo "k3s server installed and running"

alias k=kubectl
