·#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

GITLAB_NAMESPACE="gitlab"
GITLAB_RELEASE="gitlab"

echo -e "${BLUE}Starting GitLab uninstallation...${RESET}"

if helm list -n "$GITLAB_NAMESPACE" | grep -q "$GITLAB_RELEASE"; then
    echo -e "${YELLOW}Uninstalling GitLab Helm release...${RESET}"
    helm uninstall "$GITLAB_RELEASE" -n "$GITLAB_NAMESPACE" --wait || true
    echo -e "${GREEN}GitLab Helm release uninstalled${RESET}"
else
    echo -e "${YELLOW}GitLab Helm release not found, skipping...${RESET}"
fi

echo -e "${YELLOW}Deleting GitLab namespace...${RESET}"
kubectl delete namespace "$GITLAB_NAMESPACE" --ignore-not-found=true --wait=false

sleep 2

echo -e "${YELLOW}Cleaning up any remaining resources...${RESET}"
kubectl delete pvc --all -n "$GITLAB_NAMESPACE" --ignore-not-found=true --wait=false 2>/dev/null || true
kubectl delete pv -l release="$GITLAB_RELEASE" --ignore-not-found=true --wait=false 2>/dev/null || true

echo -e "${BLUE}Removing gitlab.local from /etc/hosts...${RESET}"
if grep -q "gitlab.local" /etc/hosts 2>/dev/null; then
    echo -e "${YELLOW}Removing gitlab.local from /etc/hosts (requires sudo)...${RESET}"
    if sudo -n sed -i '/gitlab.local/d' /etc/hosts 2>/dev/null; then
        echo -e "${GREEN}Removed gitlab.local from /etc/hosts${RESET}"
    else
        echo -e "${YELLOW}Could not remove from /etc/hosts (sudo required)${RESET}"
        echo -e "${YELLOW}You can manually remove the line containing 'gitlab.local' from /etc/hosts${RESET}"
    fi
else
    echo -e "${GREEN}gitlab.local not in /etc/hosts${RESET}"
fi

echo -e "${GREEN}===========================================${RESET}"
echo -e "${GREEN}GitLab uninstallation complete!${RESET}"
echo -e "${GREEN}===========================================${RESET}"
echo -e ""
echo -e "${YELLOW}Note: Namespace deletion may take a few moments to complete${RESET}"
echo -e "${YELLOW}You can check with: kubectl get namespace | grep gitlab${RESET}"
echo -e ""
