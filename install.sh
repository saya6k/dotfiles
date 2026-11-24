#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Replace $2 with a symlink to $1, moving any real file already there to .bak
# so a first run on an existing machine never destroys hand-written config.
link() {
    local src="$1" dest="$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.bak"
        echo -e "${YELLOW}Backed up $dest -> $dest.bak${NC}"
    fi
    ln -sfn "$src" "$dest"
}

echo -e "${GREEN}Starting dotfiles installation...${NC}"

# Git identity stays out of the repo. Carry it over from an existing ~/.gitconfig
# on first run, otherwise leave a template to fill in.
if [ ! -f ~/.gitconfig.local ]; then
    echo
    echo "** Creating ~/.gitconfig.local"
    git_name=$(git config --file ~/.gitconfig user.name 2>/dev/null || true)
    git_email=$(git config --file ~/.gitconfig user.email 2>/dev/null || true)
    printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" > ~/.gitconfig.local
    if [ -z "$git_name" ] || [ -z "$git_email" ]; then
        echo -e "${YELLOW}Fill in user.name / user.email in ~/.gitconfig.local${NC}"
    fi
fi

# Git
link "$DOTFILES_DIR/config/.gitconfig" ~/.gitconfig
link "$DOTFILES_DIR/config/.gitignore" ~/.gitignore

# Run platform-specific installer
if [[ "$OSTYPE" == "darwin"* ]]; then
    source "$DOTFILES_DIR/install-macos.sh"
else
    source "$DOTFILES_DIR/install-linux.sh"
fi

# Oh My Zsh (leave an existing install and its customizations alone)
if [ ! -d ~/.oh-my-zsh ]; then
    echo
    echo "** Installing Oh My Zsh"
    CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ZSH
link "$DOTFILES_DIR/config/.zshrc" ~/.zshrc

# Machine-specific zsh config
echo
echo "** Linking .zshrc-local"
if [[ "$OSTYPE" == "darwin"* ]]; then
    link "$DOTFILES_DIR/config/.zshrc-local.macos" ~/.zshrc-local
else
    link "$DOTFILES_DIR/config/.zshrc-local.linux" ~/.zshrc-local
fi

# uv
echo
echo "** Installing uv"
curl -LsSf https://astral.sh/uv/install.sh | sh

# AI agent config (Claude Code)
echo
echo "** Setting up AI agent config"
mkdir -p ~/.claude
link "$DOTFILES_DIR/config/AGENTS.md" ~/.claude/CLAUDE.md

# Claude Code settings. ~/.claude/settings.json is also written by Claude Code
# itself (/config, /model, plugin installs) and holds machine-only keys, so
# merge the shared keys from config/claude/settings.json instead of linking:
# repo values win, lists only gain missing items, other keys are left alone.
mkdir -p ~/.claude/hooks
link "$DOTFILES_DIR/config/claude/hooks/korean-guard.py" ~/.claude/hooks/korean-guard.py
python3 - "$DOTFILES_DIR/config/claude/settings.json" <<'EOF'
import json, os, sys

def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        elif isinstance(value, list) and isinstance(dst.get(key), list):
            dst[key] += [item for item in value if item not in dst[key]]
        else:
            dst[key] = value

path = os.path.expanduser("~/.claude/settings.json")
current = json.load(open(path)) if os.path.exists(path) else {}
merged = json.loads(json.dumps(current))
merge(merged, json.load(open(sys.argv[1])))
if merged != current:
    with open(path, "w") as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("Updated " + path)
EOF

echo
echo -e "${GREEN}** Done${NC}"
