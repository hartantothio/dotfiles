# Dotfiles

Collection of my dotfiles and development environment setup.

## Installation

Run the install script:

```bash
./install.sh
```

The script will:
- Set zsh as the default shell
- Install Homebrew (if not already installed)
- Create symlinks for all dotfiles to your home directory
- **Prompt for your Git user name and email** (not stored in this repo)
- Install and configure vim with the molokai theme
- Install fzf for fuzzy finding
- Install and configure Starship prompt
- Install Noto Sans Mono font
- Configure .zshrc to source custom settings

## Git Configuration

The `.gitconfig` file does **not** include `user.name` and `user.email` to keep personal information out of version control. The install script will prompt you for this information and configure it using `git config --global`.

## What's Included

- `.gitconfig` - Git configuration with aliases and color settings
- `.vimrc` - Vim configuration
- `.zshrc.custom` - Custom zsh configuration (sourced by .zshrc)
- `starship.toml` - Starship prompt configuration
- `cursor.settings.json` - Cursor IDE settings
