# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="simple"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# uv, Claude Code and other user-local binaries
export PATH="$HOME/.local/bin:$PATH"

# Machine-specific settings (Homebrew, fzf, nvm). Symlinked by install.sh.
[ -f ~/.zshrc-local ] && source ~/.zshrc-local

# API keys and other secrets. Never committed; create it by hand per machine.
if [ -f ~/.env ]; then
  set -a
  source ~/.env
  set +a
fi

# Claude Code launchers pinned to a specific provider.
cc-pro() {
  env \
    -u ANTHROPIC_BASE_URL \
    -u ANTHROPIC_AUTH_TOKEN \
    -u ANTHROPIC_MODEL \
    -u ANTHROPIC_DEFAULT_OPUS_MODEL \
    -u ANTHROPIC_DEFAULT_SONNET_MODEL \
    -u ANTHROPIC_DEFAULT_HAIKU_MODEL \
    -u CLAUDE_CODE_SUBAGENT_MODEL \
    -u CLAUDE_CODE_EFFORT_LEVEL \
    claude "$@"
}

cc-ds() {
  env \
    ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
    ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY" \
    ANTHROPIC_MODEL="deepseek-v4-pro" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash" \
    CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash" \
    CLAUDE_CODE_EFFORT_LEVEL="max" \
    claude "$@"
}

cc-zai() {
  env \
    ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
    ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY" \
    ANTHROPIC_MODEL="glm-5.2" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.2" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.2" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-5-turbo" \
    CLAUDE_CODE_SUBAGENT_MODEL="glm-5-turbo" \
    CLAUDE_CODE_EFFORT_LEVEL="max" \
    claude "$@"
}

. "$HOME/.local/bin/env"
