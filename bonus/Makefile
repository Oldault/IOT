SHELL := /bin/bash
.PHONY: all install status get-password gitlab-web uninstall clean help

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

# Uninstall GitLab completely
uninstall:
	@echo -e "$(BLUE)Uninstalling GitLab...$(RESET)"
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
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "all" "Complete setup (install + status)"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "install" "Install GitLab in the k3d cluster"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "status" "Check status of GitLab pods and services"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "get-password" "Get GitLab root password"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "gitlab-web" "Port-forward GitLab to localhost:8081"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "clean" "Clean GitLab data (keep GitLab installed)"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "uninstall" "Uninstall GitLab completely"
	@printf "  $(GREEN)%-18s$(RESET) %s\n" "help" "Show this help message"
	@printf "\n$(YELLOW)Prerequisites:$(RESET)\n"
	@printf "  - k3d cluster must be running (from p3)\n"
	@printf "  - kubectl must be configured for the cluster\n"
	@printf "\n$(YELLOW)Quick start:$(RESET)\n"
	@printf "  1. cd ../p3 && make all  # Setup cluster first\n"
	@printf "  2. cd ../bonus && make all  # Install GitLab\n"
	@printf "  3. Access GitLab at http://gitlab.local:8888 or use 'make gitlab-web' (port 8081)\n"
	@printf "\n"
