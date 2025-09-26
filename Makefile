# Stow Dotfiles Makefile
# Automate the management of dotfiles using GNU Stow

# Default target directory (user's home)
TARGET_DIR := $(HOME)

# List of all available packages
PACKAGES := bash zsh git tmux nvim hyprland waybar vscode wget secrets scripts shared

# Core packages that should be stowed first
CORE_PACKAGES := bash zsh git scripts

.PHONY: help stow-all stow-core unstow-all clean check status

# Default target
help:
	@echo "Stow Dotfiles Management"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@echo "  help        - Show this help message"
	@echo "  stow-all    - Stow all packages"
	@echo "  stow-core   - Stow only core packages ($(CORE_PACKAGES))"
	@echo "  unstow-all  - Unstow all packages"
	@echo "  check       - Check for conflicts before stowing"
	@echo "  status      - Show status of all symlinks"
	@echo "  clean       - Remove broken symlinks"
	@echo ""
	@echo "Available packages:"
	@echo "  $(PACKAGES)"
	@echo ""
	@echo "Examples:"
	@echo "  make stow-core           # Stow bash, zsh, git"
	@echo "  make stow PACKAGE=nvim   # Stow specific package"
	@echo "  make unstow PACKAGE=bash # Unstow specific package"

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

# Re-stow all packages (useful after moving the dotfiles repo)
restow-all:
	@echo "Re-stowing all packages..."
	@$(MAKE) unstow-all
	@$(MAKE) stow-all
	@echo "Done re-stowing all packages"