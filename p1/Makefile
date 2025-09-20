SHELL := /bin/bash
.PHONY: restart destroy up status ssh provision halt reload help

VAGRANT ?= vagrant
VM_NAME ?= default

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RESET := \033[0m

# Default: restart (destroy then up)
restart: destroy up

# Destroy: force non-interactive; also try piping confirmations for compatibility
destroy:
	@echo -e "$(YELLOW)Destroying Vagrant VM...$(RESET)"
	@set -o pipefail; \
	if command -v $(VAGRANT) >/dev/null 2>&1; then \
	  $(VAGRANT) destroy --force || ( printf 'y\n' | $(VAGRANT) destroy ); \
	else \
	  echo -e "$(RED)Vagrant not found in PATH.$(RESET)" && exit 1; \
	fi

# Up: start VM, with optional provider (e.g., make up PROVIDER=virtualbox)
up:
	@echo -e "$(GREEN)Bringing Vagrant VM up...$(RESET)"
	@$(VAGRANT) up $(if $(PROVIDER),--provider=$(PROVIDER))

# Status: show vagrant status
status:
	@echo -e "$(BLUE)Vagrant status:$(RESET)"
	@$(VAGRANT) status

# SSH: ssh into the VM (pass optional NAME or use VM_NAME)
ssh:
	@echo -e "$(BLUE)SSH into VM '$(VM_NAME)'...$(RESET)"
	@$(VAGRANT) ssh $(VM_NAME)

# Provision: run vagrant provision
provision:
	@echo -e "$(BLUE)Provisioning VM...$(RESET)"
	@$(VAGRANT) provision $(VM_NAME)

# Halt: stop the VM gracefully
halt:
	@echo -e "$(YELLOW)Halting VM...$(RESET)"
	@$(VAGRANT) halt $(VM_NAME)

# Reload: reload VM (provision on reload if PROVISION=yes)
reload:
	@echo -e "$(YELLOW)Reloading VM...$(RESET)"
	@$(VAGRANT) reload $(VM_NAME) $(if $(filter yes,$(PROVISION)),--provision,)

# Help: list available targets and usage
help:
	@printf "\nAvailable targets:\n"
	@printf "  %-12s %s\n" "restart"   "Destroy (force) then up"
	@printf "  %-12s %s\n" "destroy"   "Destroy VM non-interactively"
	@printf "  %-12s %s\n" "up"        "Start VM (use PROVIDER=virtualbox)"
	@printf "  %-12s %s\n" "status"    "Show vagrant status"
	@printf "  %-12s %s\n" "ssh"       "SSH into VM (use VM_NAME=name)"
	@printf "  %-12s %s\n" "provision" "Run vagrant provision"
	@printf "  %-12s %s\n" "halt"      "Halt the VM"
	@printf "  %-12s %s\n" "reload"    "Reload VM (PROVISION=yes to provision)"
	@printf "  %-12s %s\n\n" "help"      "Show this help message"
	@printf "Examples:\n"
	@printf "  %-36s %s\n" "make restart" "Destroy and bring up the VM"
	@printf "  %-36s %s\n" "make up PROVIDER=virtualbox" "Start with specific provider"
	@printf "  %-36s %s\n\n" "make ssh VM_NAME=web" "SSH into 'web' VM"

