#!/bin/bash
set -e

# Get the directory in which this script lives
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# =============================================================================
# Shared Functions
# =============================================================================

setup_zsh() {
    # Set zsh as default shell (needed for SSH sessions)
    if command -v zsh >/dev/null 2>&1; then
        sudo chsh "$(id -un)" --shell "$(which zsh)" 2>/dev/null || true
    fi
}

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew already installed."
        return
    fi

    echo "Installing Homebrew..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo "Adding Homebrew to PATH for Apple Silicon..."
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Linux
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        echo "⚠️  Unsupported OS for Homebrew installation. Please install manually."
        echo "   Visit: https://brew.sh"
        return
    fi
    
    echo "Homebrew installed successfully."
}

create_symlinks() {
    # Get a list of all files in this directory that start with a dot
    files=$(find "$SCRIPT_DIR" -maxdepth 1 -type f -name ".*")

    # Create a symbolic link to each file in the home directory
    for file in $files; do
        name=$(basename "$file")

        # Special handling for .gitconfig - copy instead of symlink
        if [ "$name" = ".gitconfig" ]; then
            echo "Copying $name to home directory."
            cp "$file" ~/"$name"
        else
            echo "Creating symlink to $name in home directory."
            rm -rf ~/"$name"
            ln -s "$file" ~/"$name"
        fi
    done
}

setup_vim_theme() {
    mkdir -p ~/.vim/colors
    mkdir -p ~/.vim/backup

    if [ ! -f ~/.vim/colors/molokai.vim ]; then
        echo "Installing molokai vim theme..."
        git clone --depth 1 https://github.com/tomasr/molokai.git /tmp/molokai
        mv /tmp/molokai/colors/molokai.vim ~/.vim/colors/
        rm -rf /tmp/molokai
    else
        echo "Molokai vim theme already installed."
    fi
}

install_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    else
        echo "fzf already installed."
    fi
}

install_starship() {
    if ! command -v starship >/dev/null 2>&1; then
        echo "Installing Starship prompt..."
        # Suppress the shell setup instructions (we handle this in .zshrc.custom)
        curl -sS https://starship.rs/install.sh | sh -s -- --yes > /dev/null 2>&1
        echo "Starship installed. (init already configured in .zshrc.custom)"
    else
        echo "Starship already installed."
    fi

    # Symlink starship config
    mkdir -p ~/.config
    if [ -f "$SCRIPT_DIR/configs/starship.toml" ]; then
        echo "Creating symlink to starship.toml in ~/.config/"
        rm -rf ~/.config/starship.toml
        ln -s "$SCRIPT_DIR/configs/starship.toml" ~/.config/starship.toml
    fi
}

setup_zshrc() {
    # Add source line for .zshrc.custom to .zshrc if it doesn't already exist
    if ! grep -q "source \$HOME/.zshrc.custom" ~/.zshrc 2>/dev/null; then
        echo "source \$HOME/.zshrc.custom" >> ~/.zshrc
        echo "Added 'source \$HOME/.zshrc.custom' to .zshrc"
    else
        echo "'source \$HOME/.zshrc.custom' already exists in .zshrc"
    fi
}

setup_git_user() {
    # Check if git user.name and user.email are already configured
    local git_name=$(git config --global user.name 2>/dev/null || echo "")
    local git_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        echo "Git user already configured:"
        echo "  Name: $git_name"
        echo "  Email: $git_email"
        read -p "Do you want to update these? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    # Prompt for git user name
    if [ -z "$git_name" ]; then
        read -p "Enter your Git user name: " git_name
    else
        read -p "Enter your Git user name [$git_name]: " new_name
        git_name=${new_name:-$git_name}
    fi
    
    # Prompt for git user email
    if [ -z "$git_email" ]; then
        read -p "Enter your Git email: " git_email
    else
        read -p "Enter your Git email [$git_email]: " new_email
        git_email=${new_email:-$git_email}
    fi
    
    # Set git config
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    echo "Git user configured:"
    echo "  Name: $git_name"
    echo "  Email: $git_email"
}

install_noto_sans_mono_font() {
    # Check if the font is already installed
    if fc-list | grep -i "Noto Sans Mono" >/dev/null 2>&1; then
        echo "Noto Sans Mono font already installed."
        return
    fi

    if ! command -v brew >/dev/null 2>&1; then
        echo "⚠️  Homebrew not available. Skipping Noto Sans Mono font installation."
        echo "   Visit: https://fonts.google.com/noto/specimen/Noto+Sans+Mono"
        return
    fi

    echo "Installing Noto Sans Mono font..."
    # Tap the fonts cask repository if not already tapped
    brew tap homebrew/cask-fonts 2>/dev/null || true
    # Install the font
    brew install --cask font-noto-sans-mono
    echo "Noto Sans Mono font installed via Homebrew."
}

install_cursor() {
    # Check if Cursor is already installed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Applications/Cursor.app" ]; then
            echo "Cursor already installed."
        else
            if ! command -v brew >/dev/null 2>&1; then
                echo "⚠️  Homebrew not available. Skipping Cursor installation."
                echo "   Visit: https://cursor.sh to install manually"
                return
            fi
            
            echo "Installing Cursor..."
            brew install --cask cursor
            echo "Cursor installed via Homebrew."
        fi
        
        # Apply Cursor settings
        local cursor_settings_dir="$HOME/Library/Application Support/Cursor/User"
        if [ -f "$SCRIPT_DIR/configs/cursor.json" ]; then
            echo "Applying Cursor settings..."
            mkdir -p "$cursor_settings_dir"
            rm -f "$cursor_settings_dir/settings.json"
            ln -s "$SCRIPT_DIR/configs/cursor.json" "$cursor_settings_dir/settings.json"
            echo "Cursor settings symlinked."
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v cursor >/dev/null 2>&1; then
            echo "Cursor already installed."
        else
            echo "⚠️  Please install Cursor manually from https://cursor.sh"
            return
        fi
        
        # Apply Cursor settings
        local cursor_settings_dir="$HOME/.config/Cursor/User"
        if [ -f "$SCRIPT_DIR/configs/cursor.json" ]; then
            echo "Applying Cursor settings..."
            mkdir -p "$cursor_settings_dir"
            rm -f "$cursor_settings_dir/settings.json"
            ln -s "$SCRIPT_DIR/configs/cursor.json" "$cursor_settings_dir/settings.json"
            echo "Cursor settings symlinked."
        fi
    else
        echo "⚠️  Unsupported OS for Cursor installation."
        echo "   Visit: https://cursor.sh"
    fi
}

# =============================================================================
# Setup
# =============================================================================

if [ -n "$CODESPACES" ]; then
    echo "🔧  Detected GitHub Codespaces environment"
elif [ -n "$GITPOD_WORKSPACE_ID" ]; then
    echo "🔧  Detected Ona environment"
else
    echo "ℹ️  Running dotfiles setup..."
fi

echo ""

setup_zsh
install_homebrew
create_symlinks
setup_git_user
setup_vim_theme
install_fzf
install_starship
install_noto_sans_mono_font
install_cursor
setup_zshrc

echo ""
echo "✅  Dotfiles setup complete!"
echo ""
echo "📝  Notes:"
echo "   - Git user name and email configured"
echo "   - Homebrew installed (if not already present)"
echo "   - fzf keybindings: Ctrl+R (history), Ctrl+T (files), Alt+C (cd)"
echo "   - Starship config is symlinked from this repo's configs/starship.toml"
echo "   - Noto Sans Mono font installed via Homebrew"
echo "   - Cursor installed and settings symlinked from this repo's configs/cursor.json"
echo "   - Restart your shell or run 'source ~/.zshrc' to apply changes"
