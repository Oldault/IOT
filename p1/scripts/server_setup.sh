#!/bin/sh

apk add --no-cache curl openssh

ssh-keygen -A
rc-update add sshd

curl -sfL https://get.k3s.io | sh -
rc-update add k3s default
rc-service k3s start

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

chmod a+r /var/lib/rancher/k3s/server/node-token
cp /var/lib/rancher/k3s/server/node-token /vagrant/config/k3s_token.txt

if ! curl -k -s https://127.0.0.1:6443/version >/dev/null; then
    echo "Warning: local API endpoint not responding" >&2
fi

echo "k3s server installed and running"
