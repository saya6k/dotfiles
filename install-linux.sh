#!/bin/bash
# Linux-specific installation - sourced by install.sh
# Targets dev containers / Codespaces: Debian-based, passwordless sudo.

# APT
echo
echo "** Installing apt packages"
sudo -n apt-get update
sudo -n DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends zsh fzf vim jq ripgrep

sudo -n chsh "$(whoami)" -s "$(which zsh)"

# GH CLI from the official apt repo. Looking up the latest release through
# the GitHub API hit the unauthenticated rate limit on shared CI runners.
echo
echo "** Installing GitHub CLI"
KEYRING=/etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo -n mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo -n tee "$KEYRING" > /dev/null
sudo -n chmod go+r "$KEYRING"
echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://cli.github.com/packages stable main" \
  | sudo -n tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo -n apt-get update
sudo -n DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gh

# NVM/Node.js (PROFILE=/dev/null prevents nvm from modifying shell config)
echo
echo "** Installing NVM and Node.js LTS"
export NVM_DIR="$HOME/.nvm"
NVM_VERSION=v0.40.3
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | PROFILE=/dev/null bash

# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"

nvm install --lts
nvm use --lts

# Claude Code
echo
echo "** Installing Claude Code"
curl -fsSL https://claude.ai/install.sh | bash
