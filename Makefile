# ==============================================================================
# Host Project Development Automation Matrix & Proxy Gateway
# ==============================================================================

.PHONY: help githooks

# Centralized third-party submodules execution paths
SUBMODULE_GITHOOKS := .dev/tools/githooks/Makefile

help: ## Display available host and proxy automation targets
	@echo "================================================================================"
	@echo "Available Development Automation Targets (Alphabetical):"
	@echo "================================================================================"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' | sort
	@echo "================================================================================"
	@echo "Usage for internal toolchain namespaces:"
	@echo "  make githooks do=<target>  (e.g., 'make githooks do=help', 'make githooks do=update')"
	@echo "================================================================================"

# ------------------------------------------------------------------------------
# BYPASS GATEWAY ENGINE (The 'githooks' Switch)
# ------------------------------------------------------------------------------
githooks: ## Bypass switch to access the internal GitHooks quality toolchain (requires do=<target>)
	@if [ -z "$(do)" ]; then \
		echo "================================================================================"; \
		echo "[ERR] Missing internal execution target pointer."; \
		echo "      Usage: make githooks do=<target>  (e.g., 'make githooks do=help')"; \
		echo "================================================================================"; \
		exit 1; \
	fi
	@if [ ! -f "$(SUBMODULE_GITHOOKS)" ]; then \
		echo "================================================================================"; \
		echo "[ERR] Core quality toolchain not found at '$(SUBMODULE_GITHOOKS)'."; \
		echo "      Please run the provisioning installation stream before executing targets."; \
		echo "================================================================================"; \
		exit 1; \
	fi
	@$(MAKE) -f $(SUBMODULE_GITHOOKS) --no-print-directory $(do) HOST_PROJECT_ROOT=$(CURDIR)
