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

while ! kubectl get nodes --request-timeout='10s' 2>/dev/null | grep -q "Ready"; do
  echo "Waiting for node to be ready..."
  sleep 5
done

echo "Node is ready. Waiting for API server to be fully available..."
sleep 10

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# wait for controller deployment to be available
kubectl -n ingress-nginx wait --for=condition=available deployment/ingress-nginx-controller --timeout=180s || {
  echo "Controller deployment not available after timeout"
  kubectl -n ingress-nginx get pods -o wide
  kubectl -n ingress-nginx logs -l app.kubernetes.io/component=controller --tail=200
  exit 1
}

# wait for admission webhook pod (if present) and its endpoints
kubectl -n ingress-nginx wait --for=condition=ready pod -l app.kubernetes.io/component=admission --timeout=60s || true

# ensure controller service has endpoints
for i in {1..12}; do
  ep=$(kubectl get endpoints ingress-nginx-controller-admission -n ingress-nginx -o jsonpath='{.subsets}' 2>/dev/null || true)
  svc=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.type}' 2>/dev/null || true)
  if [ -n "$ep" ] || [ "$svc" = "NodePort" ] || [ "$svc" = "LoadBalancer" ]; then
    echo "Ingress controller service/endpoints ready"
    break
  fi
  echo "Waiting for ingress controller endpoints/service..."
  sleep 5
done

kubectl apply -f /app/namespace.yml
kubectl apply -f /app/deployment.yml
kubectl apply -f /app/services.yml
kubectl apply -f /app/ingress.yml