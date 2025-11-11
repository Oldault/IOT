#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

GITLAB_NAMESPACE="gitlab"
GITLAB_RELEASE="gitlab"
GITLAB_PASSWORD="Sup3rS3cur3P@ss!"

echo -e "${BLUE}Starting GitLab installation for bonus part...${RESET}"

echo -e "${BLUE}Checking Helm installation...${RESET}"
if ! command -v helm &>/dev/null; then
    echo -e "${YELLOW}Helm not found. Installing Helm locally...${RESET}"

    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "$LOCAL_BIN"

    HELM_VERSION="v3.19.0"
    HELM_TAR="helm-${HELM_VERSION}-linux-amd64.tar.gz"
    TMP_DIR=$(mktemp -d)

    cd "$TMP_DIR"
    curl -fsSL "https://get.helm.sh/${HELM_TAR}" -o "${HELM_TAR}"
    tar -zxf "${HELM_TAR}"
    mv linux-amd64/helm "$LOCAL_BIN/helm"
    chmod +x "$LOCAL_BIN/helm"
    cd - > /dev/null
    rm -rf "$TMP_DIR"


    export PATH="$LOCAL_BIN:$PATH"


    if ! grep -q "$LOCAL_BIN" "$HOME/.bashrc" 2>/dev/null; then
        echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$HOME/.bashrc"
    fi

    echo -e "${GREEN}Helm installed successfully to $LOCAL_BIN!${RESET}"
    echo -e "${YELLOW}Note: You may need to run 'source ~/.bashrc' or restart your shell${RESET}"
else
    echo -e "${GREEN}Helm is already installed ($(helm version --short))${RESET}"
fi

echo -e "${BLUE}Creating GitLab namespace...${RESET}"
kubectl apply -f ./src/confs/namespace.yml

echo -e "${BLUE}Creating GitLab initial root password secret...${RESET}"
kubectl create secret generic gitlab-initial-root-password \
    --from-literal=password="$GITLAB_PASSWORD" \
    -n "$GITLAB_NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${BLUE}Adding GitLab Helm repository...${RESET}"
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
helm repo update


echo -e "${BLUE}Installing GitLab via Helm...${RESET}"
echo -e "${YELLOW}This will take 5-10 minutes. Please be patient...${RESET}"
helm upgrade --install "$GITLAB_RELEASE" gitlab/gitlab \
    -n "$GITLAB_NAMESPACE" \
    -f ./src/confs/gitlab-values.yaml \
    --timeout 30m \
    --wait

echo -e "${YELLOW}Waiting for GitLab pods to be ready...${RESET}"
echo -e "${YELLOW}This can take 5-10 minutes on first installation...${RESET}"
kubectl wait --for=condition=Ready pods --all -n "$GITLAB_NAMESPACE" --timeout=600s || true

echo -e "${BLUE}Configuring /etc/hosts for gitlab.local...${RESET}"
if ! grep -q "gitlab.local" /etc/hosts 2>/dev/null; then
    echo -e "${YELLOW}Adding gitlab.local to /etc/hosts (requires sudo)...${RESET}"
    if echo "127.0.0.1 gitlab.local" | sudo -n tee -a /etc/hosts > /dev/null 2>&1; then
        echo -e "${GREEN}Added gitlab.local to /etc/hosts${RESET}"
    else
        echo -e "${YELLOW}Could not add to /etc/hosts (sudo required or not available)${RESET}"
        echo -e "${YELLOW}You can manually add this line to /etc/hosts:${RESET}"
        echo -e "${YELLOW}  127.0.0.1 gitlab.local${RESET}"
        echo -e "${YELLOW}Or use port-forwarding with 'make gitlab-web'${RESET}"
    fi
else
    echo -e "${GREEN}gitlab.local already in /etc/hosts${RESET}"
fi

echo -e "${GREEN}===========================================${RESET}"
echo -e "${GREEN}GitLab installation complete!${RESET}"
echo -e "${GREEN}===========================================${RESET}"
echo -e ""
echo -e "${BLUE}Access GitLab at: ${YELLOW}http://gitlab.local:8888${RESET}"
echo -e "${BLUE}Username: ${YELLOW}root${RESET}"
echo -e "${BLUE}Password: ${YELLOW}$GITLAB_PASSWORD${RESET}"
echo -e ""
echo -e "${YELLOW}IMPORTANT: Root user needs to be created on first access.${RESET}"
echo -e "${YELLOW}If login fails, create root user with:${RESET}"
echo -e "${YELLOW}  cd bonus && kubectl exec -n gitlab deployment/gitlab-toolbox -- \\${RESET}"
echo -e "${YELLOW}    gitlab-rails runner /tmp/create-root-user2.rb${RESET}"
echo -e ""
echo -e "${YELLOW}Note: Make sure port-forwarding is set up or use the cluster load balancer${RESET}"
echo -e "${YELLOW}If using k3d loadbalancer on port 8888, access via: http://gitlab.local:8888${RESET}"
echo -e ""
echo -e "${BLUE}To check GitLab status, run:${RESET}"
echo -e "  kubectl get pods -n $GITLAB_NAMESPACE"
echo -e ""
