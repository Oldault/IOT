#!/bin/sh

kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl delete -f ./src/confs/namespaces.yml

kubectl delete -f ./src/confs/argocd-ingress.yml

k3d cluster delete svolodin

docker system prune -a -f

docker volume prune -f
