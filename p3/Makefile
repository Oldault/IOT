SHELL := /bin/bash
.PHONY: all install argocd-install argocd-deploy argocd-status argocd-pwd argocd-web uninstall clean help

CLUSTER_NAME ?= svolodin

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RESET := \033[0m

# Complete setup: install cluster and deploy argocd with apps
all: install argocd-install argocd-deploy argocd-status

# Install Docker, k3d, kubectl, and create cluster
install:
	@echo -e "$(BLUE)Setting up k3d cluster...$(RESET)"
	@./src/scripts/install.sh
	@k3d kubeconfig merge $(CLUSTER_NAME) --kubeconfig-merge-default
	@kubectl config use-context k3d-$(CLUSTER_NAME)
	@echo -e "$(GREEN)Cluster $(CLUSTER_NAME) is ready!$(RESET)"

# Install Argo CD in the cluster
argocd-install:
	@echo -e "$(BLUE)Installing Argo CD...$(RESET)"
	@kubectl apply -f ./src/confs/namespaces.yml
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo -e "$(YELLOW)Waiting for Argo CD to initialize...$(RESET)"
	@sleep 10
	@kubectl -n argocd patch deployment argocd-repo-server --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/securityContext/seccompProfile"}]'
	@echo -e "$(YELLOW)Waiting for Argo CD pods to be ready...$(RESET)"
	@kubectl wait --for=condition=Ready pods --all -n argocd || true
	@echo -e "$(GREEN)Argo CD installed successfully!$(RESET)"

# Deploy AppProject and Application to Argo CD
argocd-deploy:
	@echo -e "$(BLUE)Deploying Argo CD AppProject and Application...$(RESET)"
	@kubectl apply -f ./src/confs/argocd-app-project.yml
	@kubectl apply -f ./src/confs/argocd-app.yml
	@kubectl apply -f ./src/confs/argocd-app-ingress.yml
	@echo -e "$(GREEN)Argo CD applications deployed!$(RESET)"

# Check status of Argo CD and applications
argocd-status:
	@echo -e "$(BLUE)Argo CD Pods:$(RESET)"
	@kubectl get pods -n argocd
	@echo -e "\n$(BLUE)Argo CD Applications:$(RESET)"
	@kubectl get applications -n argocd 2>/dev/null || echo "No applications found yet"
	@echo -e "\n$(BLUE)Dev Namespace Pods:$(RESET)"
	@kubectl get pods -n dev 2>/dev/null || echo "No pods in dev namespace yet"

# Get initial Argo CD admin password
argocd-pwd:
	@echo -e "$(BLUE)Getting initial Argo CD admin password...$(RESET)"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo "" || echo "$(RED)Password secret not found yet$(RESET)"

# Port-forward Argo CD server to localhost:8080
argocd-web:
	@echo -e "$(BLUE)Starting Argo CD port-forward...$(RESET)"
	@echo -e "$(GREEN)Access Argo CD at: https://localhost:8080 (HTTPS!)$(RESET)"
	@echo -e "$(YELLOW)Username: admin$(RESET)"
	@echo -e "$(YELLOW)Password: Run 'make argocd-pwd' to get the password$(RESET)"
	@echo -e "$(YELLOW)Note: Accept the self-signed certificate warning in your browser$(RESET)"
	@echo -e ""
	@kubectl port-forward svc/argocd-server -n argocd 8080:443

# Uninstall everything
uninstall:
	@echo -e "$(BLUE)Uninstalling everything...$(RESET)"
	@./src/scripts/uninstall.sh
	@echo -e "$(GREEN)Cleanup complete!$(RESET)"

# Clean up Argo CD applications only (keep Argo CD installed)
clean:
	@echo -e "$(BLUE)Removing Argo CD applications...$(RESET)"
	@kubectl delete -f ./src/confs/argocd-app.yml --ignore-not-found=true
	@kubectl delete -f ./src/confs/argocd-app-project.yml --ignore-not-found=true
	@kubectl delete -f ./src/confs/ingress.yml --ignore-not-found=true
	@echo -e "$(GREEN)Applications removed!$(RESET)"

# Help: list available targets and usage
help:
	@printf "\n$(BLUE)p3 - ArgoCD with GitHub$(RESET)\n\n"
	@printf "$(YELLOW)Recommended:$(RESET) Use the orchestration Makefile in parent directory\n"
	@printf "  Run: $(GREEN)cd .. && make help$(RESET)\n\n"
	@printf "$(BLUE)Available targets:$(RESET)\n\n"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "all" "Complete setup (install + argocd-install + argocd-deploy)"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "install" "Install Docker, k3d, kubectl, and create cluster"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "argocd-install" "Install Argo CD in the cluster"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "argocd-deploy" "Deploy AppProject and Application to Argo CD"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "argocd-status" "Check status of Argo CD and applications"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "argocd-pwd" "Get initial Argo CD admin password"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "argocd-web" "Port-forward Argo CD server to localhost:8080"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "clean" "Remove Argo CD applications (keep Argo CD)"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "uninstall" "Uninstall everything (Argo CD + cluster)"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "help" "Show this help message"
	@printf "\n$(YELLOW)Next step:$(RESET) After verifying p3, run: $(GREEN)cd ../bonus && make all$(RESET)\n"
	@printf "\n"

