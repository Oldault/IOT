SHELL := /bin/bash
.PHONY: restart destroy up status ssh provision halt reload help

VAGRANT ?= vagrant
VM_NAME ?= svolodinS

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RESET := \033[0m

install:
	@bash ./install.sh

# Reload: reload VM (provision on reload if PROVISION=yes)
argocd-install:
	@echo -e "$(BLUE)Installing Argo CD...$(RESET)"
	@sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-pwd:
	@echo -e "$(BLUE)Getting initial Argo CD admin password...$(RESET)"
	@sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Argocd-web: port-forward argocd-server to localhost:8080
argocd-web:
	@echo -e "$(BLUE)Port-forwarding Argo CD server to localhost:8080...$(RESET)"
	@sudo kubectl -n argocd port-forward svc/argocd-server 8080:443

# Help: list available targets and usage
help:
	@printf "\nAvailable targets:\n"
	@printf "  %-12s %s\n" "install"   "Install Docker and k3d"
	@printf "  %-12s %s\n" "argocd-install"   "Install Argo CD in the cluster"
	@printf "  %-12s %s\n" "argocd-pwd"  "Get initial Argo CD admin password"
	@printf "  %-12s %s\n" "argocd-web"   "Port-forward Argo CD server to localhost:8080"

