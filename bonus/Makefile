SHELL := /bin/bash
.PHONY: all install status get-password gitlab-web argocd-deploy-gitlab argocd-gitlab-creds gitlab-stop gitlab-start gitlab-restart uninstall clean help

CLUSTER_NAME ?= svolodin
GITLAB_NAMESPACE := gitlab
GITLAB_RELEASE := gitlab

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RESET := \033[0m

# Complete setup: install GitLab
all: install status

# Install GitLab in the existing k3d cluster
install:
	@echo -e "$(BLUE)Installing GitLab...$(RESET)"
	@./src/scripts/install.sh
	@k3d kubeconfig merge $(CLUSTER_NAME) --kubeconfig-merge-default
	@kubectl config use-context k3d-$(CLUSTER_NAME)
	@./src/scripts/install_gitlab.sh
	@echo -e "$(GREEN)GitLab installation complete!$(RESET)"

# Check status of GitLab pods and services
status:
	@echo -e "$(BLUE)GitLab Namespace Pods:$(RESET)"
	@kubectl get pods -n $(GITLAB_NAMESPACE) 2>/dev/null || echo "$(YELLOW)No pods in gitlab namespace yet$(RESET)"
	@echo -e "\n$(BLUE)GitLab Services:$(RESET)"
	@kubectl get svc -n $(GITLAB_NAMESPACE) 2>/dev/null || echo "$(YELLOW)No services in gitlab namespace yet$(RESET)"
	@echo -e "\n$(BLUE)GitLab Ingresses:$(RESET)"
	@kubectl get ingress -n $(GITLAB_NAMESPACE) 2>/dev/null || echo "$(YELLOW)No ingresses in gitlab namespace yet$(RESET)"

# Get GitLab root password
get-password:
	@echo -e "$(BLUE)Retrieving GitLab root password...$(RESET)"
	@kubectl get secret gitlab-initial-root-password -n $(GITLAB_NAMESPACE) -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo "" || echo "$(RED)Password secret not found$(RESET)"
	@echo -e "$(BLUE)Username: $(YELLOW)root$(RESET)"

# Access GitLab via port-forward (alternative to ingress)
gitlab-web:
	@echo -e "$(BLUE)Starting GitLab port-forward...$(RESET)"
	@echo -e "$(GREEN)Access GitLab at: http://localhost:8081$(RESET)"
	@echo -e "$(YELLOW)Username: root$(RESET)"
	@echo -e "$(YELLOW)Password: Run 'make get-password' to get the password$(RESET)"
	@echo -e "$(YELLOW)Note: ArgoCD uses port 8080, GitLab uses 8081$(RESET)"
	@echo -e ""
	@kubectl port-forward -n $(GITLAB_NAMESPACE) svc/gitlab-webservice-default 8081:8181

# Configure Argo CD credentials for GitLab repository (internal service)
argocd-gitlab-creds:
	@echo -e "$(BLUE)Configuring GitLab repository credentials in Argo CD...$(RESET)"
	@kubectl create secret generic gitlab-repo-secret \
		-n argocd \
		--from-literal=type=git \
		--from-literal=url=http://gitlab-webservice-default.gitlab.svc:8181/root/owl-llepage-svolodin.git \
		--from-literal=username=root \
		--from-literal=password=argocd-migration-2024-token \
		--dry-run=client -o yaml | kubectl apply -f -
	@kubectl label secret gitlab-repo-secret -n argocd argocd.argoproj.io/secret-type=repository --overwrite
	@echo -e "$(GREEN)GitLab credentials configured!$(RESET)"

# Deploy ArgoCD Application to use GitLab (instead of GitHub)
argocd-deploy-gitlab: argocd-gitlab-creds
	@echo -e "$(BLUE)Deploying Argo CD AppProject and Application (GitLab)...$(RESET)"
	@kubectl apply -f ./src/confs/argocd-app-project-gitlab.yml
	@kubectl apply -f ./src/confs/argocd-app-gitlab.yml
	@echo -e "$(GREEN)Argo CD configured to use GitLab!$(RESET)"
	@echo -e "$(YELLOW)Verify with: kubectl get application playground -n argocd$(RESET)"

# Stop GitLab pods (data persists in PVCs)
gitlab-stop:
	@echo -e "$(BLUE)Stopping GitLab pods (data will persist)...$(RESET)"
	@echo -e "$(YELLOW)Scaling down deployments...$(RESET)"
	@kubectl scale deployment --all --replicas=0 -n $(GITLAB_NAMESPACE)
	@echo -e "$(YELLOW)Scaling down statefulsets...$(RESET)"
	@kubectl scale statefulset --all --replicas=0 -n $(GITLAB_NAMESPACE)
	@echo -e "$(GREEN)GitLab pods stopped! Data is preserved in PVCs.$(RESET)"
	@echo -e "$(YELLOW)To start GitLab again: make gitlab-start$(RESET)"

# Start GitLab pods (restore from persistent data)
gitlab-start:
	@echo -e "$(BLUE)Starting GitLab pods...$(RESET)"
	@echo -e "$(YELLOW)Scaling up statefulsets...$(RESET)"
	@kubectl scale statefulset gitlab-gitaly --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale statefulset gitlab-postgresql --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale statefulset gitlab-redis-master --replicas=1 -n $(GITLAB_NAMESPACE)
	@echo -e "$(YELLOW)Waiting for databases to be ready...$(RESET)"
	@sleep 10
	@echo -e "$(YELLOW)Scaling up deployments...$(RESET)"
	@kubectl scale deployment gitlab-certmanager --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-certmanager-cainjector --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-certmanager-webhook --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-gitlab-exporter --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-gitlab-shell --replicas=2 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-kas --replicas=2 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-minio --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-registry --replicas=2 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-sidekiq-all-in-1-v2 --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-toolbox --replicas=1 -n $(GITLAB_NAMESPACE)
	@kubectl scale deployment gitlab-webservice-default --replicas=1 -n $(GITLAB_NAMESPACE)
	@echo -e "$(GREEN)GitLab pods starting! Check status with: make status$(RESET)"

# Restart GitLab pods
gitlab-restart: gitlab-stop
	@echo -e "$(YELLOW)Waiting 5 seconds before restart...$(RESET)"
	@sleep 5
	@$(MAKE) gitlab-start

# Uninstall GitLab completely
uninstall:
	@echo -e "$(BLUE)Uninstalling GitLab...$(RESET)"
	@./src/scripts/uninstall_gitlab.sh
	@./src/scripts/uninstall.sh
	@echo -e "$(GREEN)GitLab uninstallation complete!$(RESET)"

# Clean only GitLab data (keep GitLab installed)
clean:
	@echo -e "$(BLUE)Cleaning GitLab data...$(RESET)"
	@kubectl delete pvc --all -n $(GITLAB_NAMESPACE) --ignore-not-found=true
	@echo -e "$(GREEN)GitLab data cleaned!$(RESET)"

# Help: list available targets and usage
help:
	@printf "\n$(BLUE)GitLab Bonus - Available targets:$(RESET)\n\n"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "all" "Complete setup (install + status)"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "install" "Install GitLab in the k3d cluster"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "status" "Check status of GitLab pods and services"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "get-password" "Get GitLab root password"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "gitlab-web" "Port-forward GitLab to localhost:8081"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "gitlab-stop" "Stop GitLab pods (data persists)"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "gitlab-start" "Start GitLab pods (restore data)"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "gitlab-restart" "Restart GitLab pods"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "argocd-deploy-gitlab" "Configure ArgoCD to use GitLab"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "argocd-gitlab-creds" "Configure GitLab credentials in ArgoCD"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "clean" "Clean GitLab data (keep GitLab installed)"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "uninstall" "Uninstall GitLab completely"
	@printf "  $(GREEN)%-25s$(RESET) %s\n" "help" "Show this help message"
	@printf "\n$(YELLOW)Prerequisites:$(RESET)\n"
	@printf "  - k3d cluster must be running (from p3)\n"
	@printf "  - ArgoCD must be installed (from p3)\n"
	@printf "  - kubectl must be configured for the cluster\n"
	@printf "\n$(YELLOW)Quick start:$(RESET)\n"
	@printf "  1. cd ../p3 && make all  # Setup cluster + ArgoCD first\n"
	@printf "  2. cd ../bonus && make all  # Install GitLab\n"
	@printf "  3. make argocd-deploy-gitlab  # Configure ArgoCD to use GitLab\n"
	@printf "  4. Access GitLab at http://gitlab.gitlab.local:8888\n"
	@printf "\n"
