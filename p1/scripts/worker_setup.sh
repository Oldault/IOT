#!/bin/sh

apk add --no-cache curl openssh

ssh-keygen -A
rc-update add sshd

while [ ! -f /vagrant/config/k3s_token.txt ]; do
  sleep 1
done

K3S_TOKEN=$(cat /vagrant/config/k3s_token.txt)

curl -sfL https://get.k3s.io | sh -

export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN=$K3S_TOKEN

rc-update add k3s default   
rc-service k3s start

if rc-service k3s status | grep -q 'started'; then
  echo "k3s agent is up and running"
else
  echo "WARNING: k3s agent failed to start – check $INSTALL_LOG"
fi

