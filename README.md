# Overview

This repository contains a collection of personal dotfiles and utility scripts, primarily intended for a Linux environment.

# Structure

The repository is organized as follows:

* **`.config/`**: Contains configuration files for various applications.
    * **`hypr.bac/`**: Backup configurations for Hyprland, a dynamic tiling Wayland compositor.
    * **`nvim/`**: Configuration files for Neovim, a highly extensible text editor.
    * **`yazi/`**: Configuration for Yazi, a terminal file manager.
    * **`tmux/`**: Configuration for tmux, a terminal multiplexer.
* **`app/`**: Houses standalone applications or scripts.
* **`old/`**: Contains older or deprecated dotfiles and scripts.
* **`web/`**: Web-related configurations or scripts.
* **`backup/`**: Scripts or configurations related to system backups.

# Installation/Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
   ```
   (Replace `YOUR_USERNAME` with your actual GitHub username and `~/dotfiles` with your preferred local directory).

2. **Review and selectively use configurations:**
   It is highly recommended to review the configurations before using them. You can:
    * **Symlink:** Create symbolic links from your home directory to the specific configuration files or directories within the cloned repository. Ensure parent directories (e.g., `~/.config`) exist. For example, to use the Neovim configuration:
      ```bash
      # Ensure ~/.config directory exists
      mkdir -p ~/.config
      # Create the symlink
      ln -s ~/dotfiles/.config/nvim ~/.config/nvim
      ```
    * **Copy:** Copy individual files or directories if you prefer to modify them directly without affecting the cloned repository.

**Disclaimer:** These are my personal dotfiles and configurations. They are tailored to my specific workflow and system setup. Using them directly on your system might require adjustments to suit your environment and preferences. Some configurations could potentially have unintended consequences if used without understanding their purpose. Proceed with caution and always back up your existing configurations before making changes.

# Key Components

*   **Hyprland Configuration (`.config/hypr.bac/`)**:
    This directory contains the configuration files for Hyprland, a dynamic tiling Wayland compositor. It includes customization scripts that enhance the user experience, such as theme selectors, window management utilities, and status bar configurations.

*   **Neovim Configuration (`.config/nvim/`)**:
    A personalized Neovim setup designed for efficient text editing and development. It likely includes a selection of plugins, custom keybindings, and settings tailored for various programming languages and workflows.

*   **Custom Scripts (`app/`)**:
    The `app/` directory hosts a variety of custom scripts. These scripts might offer utilities for system administration, workflow automation, or other personalized tasks. Explore this directory to find potentially useful tools that can streamline your command-line experience.

# Customization

Users are encouraged to fork this repository and customize the configurations to suit their own needs and preferences. Here's a general approach:

1.  **Fork the Repository:** Create your own copy of this repository on GitHub (or your preferred Git hosting service).
2.  **Clone Your Fork:** Clone your forked repository to your local machine.
3.  **Experiment and Modify:** Feel free to modify existing configurations, add new ones, or remove those you don't need. The structure provided is a starting point; adapt it to your liking.
4.  **Track Your Changes:** Use Git to commit your changes and push them to your fork. This allows you to maintain your personalized setup and easily pull updates from the original repository if desired.

By forking, you can tailor these dotfiles to create a setup that is uniquely yours while still having a reference to the original configurations. Remember to commit your changes to your fork regularly to keep your setup safe and version-controlled.

# Dependencies

These configurations may depend on specific software, tools, or packages being installed on your system. For example:

*   The Hyprland configurations will require Hyprland to be installed.
*   The Neovim setup will need Neovim, and potentially specific plugins or language servers.
*   Various scripts in `app/` or other directories might rely on common CLI utilities (e.g., `grep`, `sed`, `awk`, `curl`) or more specialized tools.

Users are responsible for identifying and installing the necessary dependencies based on the specific configurations they choose to use. It's recommended to check individual configuration files or scripts for clues about their requirements. For instance, Neovim plugin managers often list required plugins, and scripts might mention necessary commands.

# License

This repository is currently not licensed. If you intend to share your configurations more broadly, you might consider adding an open-source license.

Common choices include:

*   **MIT License:** A permissive license that is short and simple.
*   **GNU General Public License (GPL):** A copyleft license that ensures derivatives also remain open source.

You can add a `LICENSE` file to the root of your repository and update this section to reflect your choice. For example:

"This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details."

If you do not wish to add a specific license, you can state:

"These dotfiles are provided as-is for personal use. No license is granted for redistribution or modification beyond personal use."
