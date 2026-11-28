#!/bin/bash
# macOS-specific installation - sourced by install.sh

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Xcode command line tools (git, make, clang)
if ! xcode-select -p &> /dev/null; then
    echo -e "${YELLOW}Installing Xcode command line tools...${NC}"
    xcode-select --install
    echo -e "${YELLOW}Finish the installer dialog, then re-run install.sh${NC}"
    exit 1
fi

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo -e "${GREEN}Homebrew already installed${NC}"
fi

# Install Homebrew packages from Brewfile
echo -e "\n${GREEN}Installing Homebrew packages from Brewfile...${NC}"
brew bundle --file="$DOTFILES_DIR/Brewfile"

# Start menu bar utilities at login; skip apps that are already login items
login_items=$(osascript -e 'tell application "System Events" to get the name of every login item')
for app in "Caffeine" "Hidden Bar"; do
    if [ -d "/Applications/$app.app" ] && ! grep -qF "$app" <<< "$login_items"; then
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/$app.app\", hidden:false}" > /dev/null
        echo -e "${GREEN}Added $app to login items${NC}"
    fi
done

# Claude Code
echo -e "\n${GREEN}Installing Claude Code...${NC}"
curl -fsSL https://claude.ai/install.sh | bash

# macOS system preferences are deliberately not run from here: they need sudo
# and change system state. Run ./macos-defaults.sh by hand when you want them.
echo -e "\n${YELLOW}Skipping macOS defaults. Run ./macos-defaults.sh separately.${NC}"
