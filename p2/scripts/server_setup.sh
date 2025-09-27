
#!/bin/sh

if ! command -v docker >/dev/null 2>&1; then
    sudo apk update
    sudo apk add docker
    sudo service docker start
    sudo rc-update add docker boot
else
    echo "Docker already installed."
fi

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

if ! curl -k -s https://127.0.0.1:6443/version >/dev/null; then
    echo "Warning: local API endpoint not responding" >&2
fi

echo "k3s server installed and running"

echo 'alias k=kubectl' >> /etc/profile.d/aliases.sh
. /etc/profile.d/aliases.sh

echo "Applying Kubernetes configurations..."

while ! kubectl get nodes | grep -q "Ready"; do
  echo "Waiting for node to be ready..."
  sleep 5
done

if ! kubectl get namespace hello-kubernetes > /dev/null 2>&1; then
  kubectl create namespace hello-kubernetes
fi

kubectl apply -f /app/deployment.yml
kubectl apply -f /app/services.yml
kubectl apply -f /app/ingress.yml

echo "Kubernetes configurations applied."

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
echo "Ingress controller deployed."

