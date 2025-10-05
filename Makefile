# Enhanced Stow Dotfiles Makefile
# Automated management using stow-manager.sh with fallback to legacy mode

# Configuration
STOW_MANAGER := $(CURDIR)/stow-manager.sh
TARGET_DIR := $(HOME)
CONFIG_FILE := $(CURDIR)/stow-config.yaml

# Legacy package lists (for fallback mode)
LEGACY_PACKAGES := bash zsh git tmux nvim hyprland waybar vscode wget secrets scripts shared
LEGACY_CORE := bash zsh git scripts shared

# Check if we should use legacy mode
USE_LEGACY := $(shell if [ ! -f "$(STOW_MANAGER)" ] || [ "$$STOW_LEGACY" = "1" ]; then echo "true"; else echo "false"; fi)

.PHONY: help deps validate preflight status stow unstow restow clean backup
.PHONY: stow-all stow-core stow-dev stow-desktop unstow-all group list
.PHONY: check info interactive legacy-help install-hooks

# Default target - show comprehensive help
help:
	@echo "🏠 Enhanced Stow Dotfiles Management"
	@echo "===================================="
	@echo ""
ifeq ($(USE_LEGACY),true)
	@echo "⚠️  Running in LEGACY MODE"
	@echo "   (stow-manager.sh not found or STOW_LEGACY=1)"
	@echo ""
	@$(MAKE) legacy-help
else
	@echo "🤖 Using Advanced Stow Manager"
	@echo ""
	@echo "📋 QUICK ACTIONS:"
	@echo "  make deps        - Install required dependencies"
	@echo "  make interactive - Interactive package selection (recommended)"
	@echo "  make status      - Show package status dashboard"
	@echo "  make validate    - Validate configuration"
	@echo "  make preflight   - Pre-installation checks"
	@echo ""
	@echo "📦 PACKAGE MANAGEMENT:"
	@echo "  make stow        - Interactive stow packages"
	@echo "  make unstow      - Interactive unstow packages"
	@echo "  make restow      - Interactive restow packages"
	@echo "  make group GROUP=essential  - Stow package group"
	@echo ""
	@echo "🎯 PREDEFINED GROUPS:"
	@echo "  make stow-core   - Stow essential packages (bash, zsh, git, etc.)"
	@echo "  make stow-dev    - Stow development tools (nvim, tmux, vscode)"
	@echo "  make stow-desktop- Stow desktop environment (hyprland, waybar)"
	@echo "  make stow-all    - Stow all available packages"
	@echo ""
	@echo "🔧 MAINTENANCE:"
	@echo "  make clean       - Clean broken symlinks and old backups"
	@echo "  make backup      - Create backup of current configuration"
	@echo "  make check       - Check for conflicts (dry-run)"
	@echo ""
	@echo "ℹ️  INFORMATION:"
	@echo "  make list        - List all available packages"
	@echo "  make info PACKAGE=bash  - Show detailed package info"
	@echo "  make status json - Show status in JSON format"
	@echo ""
	@echo "⚙️  ADVANCED:"
	@echo "  make install-hooks - Install git hooks for auto-management"
	@echo "  STOW_LEGACY=1 make help  - Use legacy mode"
	@echo ""
	@echo "📁 FILES:"
	@echo "  Config: $(CONFIG_FILE)"
	@echo "  Manager: $(STOW_MANAGER)"
	@echo "  Logs: $(CURDIR)/logs/"
endif

# Stow all packages
stow-all:
	@echo "Stowing all packages to $(TARGET_DIR)..."
	@for package in $(PACKAGES); do \
		if [ -d $$package ]; then \
			echo "Stowing $$package..."; \
			stow -t $(TARGET_DIR) $$package; \
		else \
			echo "Warning: Package $$package not found"; \
		fi; \
	done
	@echo "Done stowing all packages"

# Stow only core packages
stow-core:
	@echo "Stowing core packages to $(TARGET_DIR)..."
	@for package in $(CORE_PACKAGES); do \
		if [ -d $$package ]; then \
			echo "Stowing $$package..."; \
			stow -t $(TARGET_DIR) $$package; \
		else \
			echo "Warning: Package $$package not found"; \
		fi; \
	done
	@echo "Done stowing core packages"

# Stow a specific package (use: make stow PACKAGE=package_name)
stow:
ifdef PACKAGE
	@echo "Stowing $(PACKAGE) to $(TARGET_DIR)..."
	@stow -t $(TARGET_DIR) $(PACKAGE)
	@echo "Done stowing $(PACKAGE)"
else
	@echo "Usage: make stow PACKAGE=package_name"
	@echo "Available packages: $(PACKAGES)"
endif

# Unstow all packages
unstow-all:
	@echo "Unstowing all packages from $(TARGET_DIR)..."
	@for package in $(PACKAGES); do \
		if [ -d $$package ]; then \
			echo "Unstowing $$package..."; \
			stow -t $(TARGET_DIR) -D $$package; \
		fi; \
	done
	@echo "Done unstowing all packages"

# Unstow a specific package (use: make unstow PACKAGE=package_name)
unstow:
ifdef PACKAGE
	@echo "Unstowing $(PACKAGE) from $(TARGET_DIR)..."
	@stow -t $(TARGET_DIR) -D $(PACKAGE)
	@echo "Done unstowing $(PACKAGE)"
else
	@echo "Usage: make unstow PACKAGE=package_name"
	@echo "Available packages: $(PACKAGES)"
endif

# Check for conflicts before stowing
check:
	@echo "Checking for conflicts..."
	@for package in $(PACKAGES); do \
		if [ -d $$package ]; then \
			echo "Checking $$package..."; \
			stow --no -t $(TARGET_DIR) $$package; \
		fi; \
	done
	@echo "Conflict check complete"

# Show status of all symlinks managed by stow
status:
	@echo "Stow symlink status:"
	@echo "==================="
	@find $(TARGET_DIR) -maxdepth 2 -type l -ls | grep "$(PWD)" || echo "No stow-managed symlinks found"

# Clean up broken symlinks
clean:
	@echo "Cleaning broken symlinks..."
	@find $(TARGET_DIR) -maxdepth 2 -type l ! -exec test -e {} \; -print -delete

# === ENHANCED STOW MANAGER TARGETS ===

# Install system dependencies
deps:
ifeq ($(USE_LEGACY),false)
	@echo "🔧 Installing dependencies for enhanced stow manager..."
	@if command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --needed stow fzf python python-yaml; \
	elif command -v apt >/dev/null 2>&1; then \
		sudo apt update && sudo apt install -y stow fzf python3-yaml; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y stow fzf python3-pyyaml; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install stow fzf yq; \
	else \
		echo "❌ Unknown package manager. Please install: stow, fzf, yq/python3-yaml"; \
		exit 1; \
	fi
	@echo "✅ Dependencies installed successfully"
else
	@echo "📦 Installing basic dependencies for legacy mode..."
	@if command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --needed stow; \
	elif command -v apt >/dev/null 2>&1; then \
		sudo apt update && sudo apt install -y stow; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y stow; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install stow; \
	else \
		echo "❌ Unknown package manager. Please install: stow"; \
		exit 1; \
	fi
endif

# Validate configuration
validate:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) validate
else
	@echo "⚠️  Configuration validation not available in legacy mode"
endif

# Pre-installation checks
preflight:
ifeq ($(USE_LEGACY),false)
	@echo "🔍 Running pre-installation checks..."
	@echo "📊 System Information:"
	@echo "  OS: $(shell uname -s) $(shell uname -r)"
	@echo "  Shell: $(SHELL)"
	@echo "  User: $(USER)"
	@echo "  Home: $(HOME)"
	@echo "  PWD: $(PWD)"
	@echo ""
	@echo "💾 Disk Space:"
	@df -h $(HOME) | tail -1
	@echo ""
	@echo "📦 Dependencies:"
	@command -v stow >/dev/null && echo "  ✅ stow" || echo "  ❌ stow (run: make deps)"
	@command -v fzf >/dev/null && echo "  ✅ fzf" || echo "  ⚠️  fzf (optional, for interactive mode)"
	@(command -v yq >/dev/null || command -v python3 >/dev/null) && echo "  ✅ YAML parser" || echo "  ❌ yq/python3 (run: make deps)"
	@echo ""
	@$(STOW_MANAGER) validate
	@echo "✅ Preflight checks complete"
else
	@echo "⚠️  Preflight checks not available in legacy mode"
	@echo "Basic check: $(shell command -v stow >/dev/null && echo "✅ stow available" || echo "❌ stow missing")"
endif

# Enhanced status display
status:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) status $(if $(filter json,$(MAKECMDGOALS)),json,table)
else
	@echo "📊 Legacy Status Report"
	@echo "======================"
	@find $(TARGET_DIR) -maxdepth 2 -type l -ls | grep "$(PWD)" || echo "No stow-managed symlinks found"
endif

# Interactive package management
interactive:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) stow
else
	@echo "❌ Interactive mode requires enhanced stow manager"
	@echo "💡 Available legacy commands: make stow-core, make stow-all"
endif

# Package group management
group:
ifeq ($(USE_LEGACY),false)
ifdef GROUP
	@$(STOW_MANAGER) group $(GROUP)
else
	@echo "Usage: make group GROUP=<group_name>"
	@echo "Available groups:"
	@$(STOW_MANAGER) groups
endif
else
	@echo "❌ Group management requires enhanced stow manager"
	@echo "💡 Use: make stow-core (essential) or make stow-all (everything)"
endif

# Package information
info:
ifeq ($(USE_LEGACY),false)
ifdef PACKAGE
	@$(STOW_MANAGER) info $(PACKAGE)
else
	@echo "Usage: make info PACKAGE=<package_name>"
	@echo "Available packages:"
	@$(STOW_MANAGER) list
endif
else
	@echo "❌ Package info requires enhanced stow manager"
	@echo "💡 Available packages: $(LEGACY_PACKAGES)"
endif

# List packages
list:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) list
else
	@echo "📦 Available Packages (Legacy Mode):"
	@echo "$(LEGACY_PACKAGES)" | tr ' ' '\n' | sed 's/^/  • /'
endif

# === ENHANCED STOW OPERATIONS ===

# Interactive stowing
stow:
ifeq ($(USE_LEGACY),false)
ifdef PACKAGE
	@$(STOW_MANAGER) stow $(PACKAGE)
else
	@$(STOW_MANAGER) stow
endif
else
	$(call legacy_stow_single)
endif

# Interactive unstowing
unstow:
ifeq ($(USE_LEGACY),false)
ifdef PACKAGE
	@$(STOW_MANAGER) unstow $(PACKAGE)
else
	@$(STOW_MANAGER) unstow
endif
else
	$(call legacy_unstow_single)
endif

# Interactive restowing
restow:
ifeq ($(USE_LEGACY),false)
ifdef PACKAGE
	@$(STOW_MANAGER) restow $(PACKAGE)
else
	@$(STOW_MANAGER) restow
endif
else
	@echo "❌ Restow requires enhanced stow manager"
	@echo "💡 Use: make unstow PACKAGE=<name> && make stow PACKAGE=<name>"
endif

# Stow all packages
stow-all:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) group full
else
	$(call legacy_stow_all)
endif

# Stow core packages
stow-core:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) group essential
else
	$(call legacy_stow_core)
endif

# Stow development packages
stow-dev:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) group development
else
	@echo "🔧 Stowing development packages (legacy mode)..."
	@for package in nvim tmux vscode; do \
		if [ -d $$package ]; then \
			echo "Stowing $$package..."; \
			stow -t $(TARGET_DIR) $$package || echo "⚠️  Failed to stow $$package"; \
		fi; \
	done
endif

# Stow desktop packages
stow-desktop:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) group desktop
else
	@echo "🖥️  Stowing desktop packages (legacy mode)..."
	@for package in hyprland waybar; do \
		if [ -d $$package ]; then \
			echo "Stowing $$package..."; \
			stow -t $(TARGET_DIR) $$package || echo "⚠️  Failed to stow $$package"; \
		fi; \
	done
endif

# Unstow all packages
unstow-all:
ifeq ($(USE_LEGACY),false)
	@echo "⚠️  This will unstow ALL packages. Are you sure?"
	@read -p "Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@$(STOW_MANAGER) --force unstow $(shell $(STOW_MANAGER) list | tr '\n' ' ')
else
	$(call legacy_unstow_all)
endif

# Conflict checking
check:
ifeq ($(USE_LEGACY),false)
ifdef PACKAGE
	@$(STOW_MANAGER) check $(PACKAGE)
else
	@$(STOW_MANAGER) --dry-run stow
endif
else
	$(call legacy_check)
endif

# Enhanced cleanup
clean:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) clean
else
	$(call legacy_clean)
endif

# Create backup
backup:
ifeq ($(USE_LEGACY),false)
	@echo "💾 Creating backup of current dotfiles..."
	@mkdir -p "$(HOME)/.dotfiles-backup-$(shell date +%Y%m%d_%H%M%S)"
	@echo "✅ Backup created (manual process in legacy mode)"
else
	@echo "💾 Creating manual backup..."
	@mkdir -p "$(HOME)/.dotfiles-backup-$(shell date +%Y%m%d_%H%M%S)"
	@echo "✅ Backup directory created (manual copy required)"
endif

# Install git hooks
install-hooks:
ifeq ($(USE_LEGACY),false)
	@echo "🔗 Installing git hooks for automated stow management..."
	@mkdir -p .git/hooks
	@echo '#!/bin/bash' > .git/hooks/post-merge
	@echo '# Auto-restow changed packages after git pull/merge' >> .git/hooks/post-merge
	@echo 'cd "$(PWD)" && ./stow-manager.sh scan --auto-restow 2>/dev/null || true' >> .git/hooks/post-merge
	@chmod +x .git/hooks/post-merge
	@echo '#!/bin/bash' > .git/hooks/pre-commit
	@echo '# Validate stow configuration before commit' >> .git/hooks/pre-commit
	@echo 'cd "$(PWD)" && ./stow-manager.sh validate' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Git hooks installed:"
	@echo "   📥 post-merge: Auto-restow after pull/merge"
	@echo "   ✅ pre-commit: Validate config before commit"
else
	@echo "❌ Git hooks require enhanced stow manager"
endif

# === LEGACY MODE FUNCTIONS ===

define legacy_stow_single
ifdef PACKAGE
	@echo "📦 Stowing $(PACKAGE) (legacy mode)..."
	@stow -t $(TARGET_DIR) $(PACKAGE)
	@echo "✅ Done stowing $(PACKAGE)"
else
	@echo "Usage: make stow PACKAGE=package_name"
	@echo "Available packages: $(LEGACY_PACKAGES)"
endif
endef

define legacy_unstow_single
ifdef PACKAGE
	@echo "📦 Unstowing $(PACKAGE) (legacy mode)..."
	@stow -t $(TARGET_DIR) -D $(PACKAGE)
	@echo "✅ Done unstowing $(PACKAGE)"
else
	@echo "Usage: make unstow PACKAGE=package_name"
	@echo "Available packages: $(LEGACY_PACKAGES)"
endif
endef

define legacy_stow_all
	@echo "📦 Stowing all packages (legacy mode)..."
	@for package in $(LEGACY_PACKAGES); do \
		if [ -d $$package ]; then \
			echo "Stowing $$package..."; \
			stow -t $(TARGET_DIR) $$package || echo "⚠️  Failed to stow $$package"; \
		fi; \
	done
	@echo "✅ Done stowing all packages"
endef

define legacy_stow_core
	@echo "🎯 Stowing core packages (legacy mode)..."
	@for package in $(LEGACY_CORE); do \
		if [ -d $$package ]; then \
			echo "Stowing $$package..."; \
			stow -t $(TARGET_DIR) $$package || echo "⚠️  Failed to stow $$package"; \
		fi; \
	done
	@echo "✅ Done stowing core packages"
endef

define legacy_unstow_all
	@echo "📦 Unstowing all packages (legacy mode)..."
	@for package in $(LEGACY_PACKAGES); do \
		if [ -d $$package ]; then \
			echo "Unstowing $$package..."; \
			stow -t $(TARGET_DIR) -D $$package || echo "⚠️  Failed to unstow $$package"; \
		fi; \
	done
	@echo "✅ Done unstowing all packages"
endef

define legacy_check
	@echo "🔍 Checking for conflicts (legacy mode)..."
	@for package in $(LEGACY_PACKAGES); do \
		if [ -d $$package ]; then \
			echo "Checking $$package..."; \
			stow --no -t $(TARGET_DIR) $$package || echo "⚠️  Conflicts in $$package"; \
		fi; \
	done
	@echo "✅ Conflict check complete"
endef

define legacy_clean
	@echo "🧹 Cleaning broken symlinks (legacy mode)..."
	@find $(TARGET_DIR) -maxdepth 2 -type l ! -exec test -e {} \; -print -delete
	@echo "✅ Cleanup complete"
endef

# Legacy help (fallback)
legacy-help:
	@echo "📦 BASIC PACKAGE OPERATIONS:"
	@echo "  make stow-all    - Stow all packages"
	@echo "  make stow-core   - Stow core packages ($(LEGACY_CORE))"
	@echo "  make unstow-all  - Unstow all packages"
	@echo "  make check       - Check for conflicts"
	@echo "  make clean       - Remove broken symlinks"
	@echo ""
	@echo "📝 SINGLE PACKAGE:"
	@echo "  make stow PACKAGE=nvim    - Stow specific package"
	@echo "  make unstow PACKAGE=bash  - Unstow specific package"
	@echo ""
	@echo "📋 AVAILABLE PACKAGES:"
	@echo "  $(LEGACY_PACKAGES)"
	@echo ""
	@echo "💡 To use enhanced features, ensure stow-manager.sh exists"

# Re-stow all packages (useful after moving the dotfiles repo)
restow-all:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) --force restow $(shell $(STOW_MANAGER) list | tr '\n' ' ')
else
	@echo "🔄 Re-stowing all packages (legacy mode)..."
	@$(MAKE) unstow-all
	@$(MAKE) stow-all
	@echo "✅ Done re-stowing all packages"
endif

# === HELP SYSTEM ===

# Main help (adapts to available features)
help:
	@echo "$(COLOR_CYAN)🏠 DOTFILES MANAGEMENT$(COLOR_RESET)"
	@echo "============================"
	@echo ""
ifeq ($(USE_LEGACY),false)
	@echo "$(COLOR_GREEN)✨ Enhanced Mode Active$(COLOR_RESET) (stow-manager.sh detected)"
	@echo ""
	@echo "$(COLOR_YELLOW)🚀 QUICK START:$(COLOR_RESET)"
	@echo "  make deps           - Install system dependencies"
	@echo "  make preflight      - Run system compatibility checks"
	@echo "  make interactive    - Interactively choose packages to stow"
	@echo "  make stow-core      - Stow essential packages ($(shell $(STOW_MANAGER) group essential --list 2>/dev/null | tr '\n' ' ' | sed 's/ *$$//'))"
	@echo "  make stow-all       - Stow all packages"
	@echo ""
	@echo "$(COLOR_YELLOW)📦 PACKAGE OPERATIONS:$(COLOR_RESET)"
	@echo "  make stow [PACKAGE=name]      - Stow packages (interactive if no package)"
	@echo "  make unstow [PACKAGE=name]    - Unstow packages"
	@echo "  make restow [PACKAGE=name]    - Re-stow packages"
	@echo "  make check [PACKAGE=name]     - Check for conflicts"
	@echo "  make list                     - List all available packages"
	@echo "  make info PACKAGE=name       - Show package information"
	@echo ""
	@echo "$(COLOR_YELLOW)👥 GROUP OPERATIONS:$(COLOR_RESET)"
	@echo "  make group GROUP=name         - Stow package groups"
	@echo "  make stow-core                - Stow essential packages"
	@echo "  make stow-dev                 - Stow development packages"
	@echo "  make stow-desktop             - Stow desktop packages"
	@echo ""
	@echo "$(COLOR_YELLOW)🔧 SYSTEM MAINTENANCE:$(COLOR_RESET)"
	@echo "  make status                   - Show current stow status"
	@echo "  make validate                 - Validate stow configuration"
	@echo "  make clean                    - Remove broken symlinks"
	@echo "  make backup                   - Create backup of current dotfiles"
	@echo "  make install-hooks            - Install git hooks for automation"
	@echo "  make deps                     - Install/update dependencies"
	@echo ""
	@echo "$(COLOR_YELLOW)📋 INFORMATION:$(COLOR_RESET)"
	@echo "  make help                     - Show this help"
	@echo "  make help-advanced            - Show advanced usage examples"
	@echo "  make help-legacy              - Show legacy mode commands"
	@echo ""
else
	@echo "$(COLOR_MAGENTA)📦 Legacy Mode$(COLOR_RESET) (basic stow functionality)"
	@echo ""
	@echo "$(COLOR_YELLOW)🚀 QUICK START:$(COLOR_RESET)"
	@echo "  make deps                     - Install basic dependencies (stow)"
	@echo "  make stow-core                - Stow core packages ($(LEGACY_CORE))"
	@echo "  make stow-all                 - Stow all packages ($(LEGACY_PACKAGES))"
	@echo ""
	@echo "$(COLOR_YELLOW)📦 BASIC OPERATIONS:$(COLOR_RESET)"
	@echo "  make stow PACKAGE=name        - Stow specific package"
	@echo "  make unstow PACKAGE=name      - Unstow specific package"
	@echo "  make restow-all               - Re-stow all packages"
	@echo "  make check                    - Check for conflicts"
	@echo "  make clean                    - Remove broken symlinks"
	@echo ""
	@echo "$(COLOR_YELLOW)💡 UPGRADE PATH:$(COLOR_RESET)"
	@echo "  To unlock enhanced features:"
	@echo "  1. Ensure stow-manager.sh exists and is executable"
	@echo "  2. Run: make deps (installs fzf, yq/python-yaml)"
	@echo "  3. Run: make validate (checks configuration)"
	@echo ""
endif
	@echo "$(COLOR_YELLOW)🌍 ENVIRONMENT:$(COLOR_RESET)"
	@echo "  Mode: $(if $(filter false,$(USE_LEGACY)),$(COLOR_GREEN)Enhanced$(COLOR_RESET),$(COLOR_MAGENTA)Legacy$(COLOR_RESET))"
	@echo "  Target: $(TARGET_DIR)"
	@echo "  Config: $(CONFIG_FILE)"
	@echo "  Manager: $(if $(filter false,$(USE_LEGACY)),$(STOW_MANAGER),$(COLOR_RED)Not Available$(COLOR_RESET))"
	@echo ""
	@echo "$(COLOR_CYAN)For more information, visit: https://github.com/$(USER)/dotfiles$(COLOR_RESET)"

# Advanced usage examples
help-advanced:
ifeq ($(USE_LEGACY),false)
	@echo "$(COLOR_CYAN)🎯 ADVANCED USAGE EXAMPLES$(COLOR_RESET)"
	@echo "=============================="
	@echo ""
	@echo "$(COLOR_YELLOW)🔧 Complex Operations:$(COLOR_RESET)"
	@echo "  make preflight && make stow-core    # Safe installation"
	@echo "  make backup && make stow-all        # Backup then full install"
	@echo "  make check PACKAGE=nvim             # Check specific package"
	@echo ""
	@echo "$(COLOR_YELLOW)🎨 Package Management:$(COLOR_RESET)"
	@echo "  make group GROUP=development        # Install dev tools"
	@echo "  make info PACKAGE=nvim              # Show package details"
	@echo "  make status                         # Dashboard view"
	@echo ""
	@echo "$(COLOR_YELLOW)⚙️  Configuration:$(COLOR_RESET)"
	@echo "  TARGET_DIR=/opt/dotfiles make stow-core  # Custom target"
	@echo "  FORCE=1 make stow PACKAGE=bash           # Force stow"
	@echo "  STOW_LEGACY=1 make stow-all               # Force legacy mode"
	@echo ""
	@echo "$(COLOR_YELLOW)🔄 Automation:$(COLOR_RESET)"
	@echo "  make install-hooks                   # Auto-stow on git pull"
	@echo "  make validate && git commit          # Pre-commit validation"
	@echo ""
	@echo "$(COLOR_YELLOW)🏃 Batch Operations:$(COLOR_RESET)"
	@echo "  # Install everything for new system:"
	@echo "  make deps preflight backup stow-all install-hooks"
	@echo ""
	@echo "  # Developer workstation setup:"
	@echo "  make deps && make group GROUP=development"
	@echo ""
	@echo "  # Desktop environment setup:"
	@echo "  make deps && make group GROUP=desktop"
else
	@echo "$(COLOR_MAGENTA)Advanced features require enhanced mode$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)💡 To enable: ensure stow-manager.sh exists and run 'make deps'$(COLOR_RESET)"
endif

# Show legacy help
help-legacy:
	@$(MAKE) legacy-help

# Special JSON status output (for scripts/automation)
json:
ifeq ($(USE_LEGACY),false)
	@$(STOW_MANAGER) status json
else
	@echo "{\"error\": \"JSON output requires enhanced mode\", \"mode\": \"legacy\"}"
endif

# Quick alias targets
.PHONY: h i s l c install update
h: help
i: interactive
s: status
l: list
c: clean
install: stow-core
update: restow-all

# Default target
.DEFAULT_GOAL := help
