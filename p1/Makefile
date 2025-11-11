SHELL := /bin/bash
.PHONY: restart destroy up status help

VAGRANT ?= vagrant

RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RESET := \033[0m

restart: destroy up

destroy:
	@echo -e "$(YELLOW)Destroying Vagrant VM...$(RESET)"
	@set -o pipefail; \
	if command -v $(VAGRANT) >/dev/null 2>&1; then \
	  $(VAGRANT) destroy --force || ( printf 'y\n' | $(VAGRANT) destroy ); \
	else \
	  echo -e "$(RED)Vagrant not found in PATH.$(RESET)" && exit 1; \
	fi

up:
	@echo -e "$(GREEN)Bringing Vagrant VM up...$(RESET)"
	@$(VAGRANT) up $(if $(PROVIDER),--provider=$(PROVIDER))

status:
	@echo -e "$(BLUE)Vagrant status:$(RESET)"
	@$(VAGRANT) status

help:
	@printf "\nAvailable targets:\n"
	@printf "  %-12s %s\n" "restart"   "Destroy (force) then up"
	@printf "  %-12s %s\n" "destroy"   "Destroy VM non-interactively"
	@printf "  %-12s %s\n" "up"        "Start VM (use PROVIDER=virtualbox)"
	@printf "  %-12s %s\n" "status"    "Show vagrant status"
	@printf "  %-12s %s\n\n" "help"      "Show this help message"
	@printf "Examples:\n"
	@printf "  %-36s %s\n" "make restart" "Destroy and bring up the VM"
	@printf "  %-36s %s\n" "make up PROVIDER=virtualbox" "Start with specific provider"
	@printf "  %-36s %s\n\n" "make ssh VM_NAME=svolodinS" "SSH into the server VM"

