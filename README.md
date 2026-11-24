# Dotfiles

Shell, git and AI agent config for my Mac, and setup scripts that run automatically in VS Code dev containers and GitHub Codespaces.

## Layout

```
Brewfile             Homebrew formulae, casks and Mac App Store apps
install.sh           Entry point: symlinks config/ into $HOME, then branches by OS
install-macos.sh     Homebrew + Brewfile + Claude Code
install-linux.sh     apt packages, GitHub CLI, nvm/Node, Claude Code, OpenCode
macos-defaults.sh    macOS system preferences (run by hand)
config/              The files that get symlinked into $HOME
test/                Docker check that install.sh works on a clean Linux box
```

## Setup on a Mac

```bash
git clone https://github.com/saya6k/dotfiles.git ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

`install.sh` is safe to re-run. Any real file it is about to replace with a symlink
is moved to `<name>.bak` first, and an existing Oh My Zsh install is left alone.

`install.sh` also installs a Claude Code hook (`config/claude/hooks/korean-guard.py`)
that sends a reply back for a Korean rewrite when it comes out mostly in English. It adds
`Stop` and `PreToolUse` entries to `~/.claude/settings.json` if they are not there yet. It is a
Korean port of [claude-code-japanese-guard](https://github.com/minorun365/claude-code-japanese-guard)
(Apache-2.0). Set `KOREAN_GUARD_DISABLE=1` to turn it off for `claude -p` scripts.

System preferences are not applied automatically:

```bash
./macos-defaults.sh
```

## Using with dev containers

Tell VS Code to use this repository and it gets installed into every new dev container.

Git author details are not in this repo, so pass them via environment variables:

```json
{
  "dotfiles.repository": "saya6k/dotfiles",
  "remote.containers.dotfiles.repository": "saya6k/dotfiles",
  "terminal.integrated.env.linux": {
    "GIT_COMMITTER_NAME": "Your Name",
    "GIT_COMMITTER_EMAIL": "your@email.com",
    "GIT_AUTHOR_NAME": "Your Name",
    "GIT_AUTHOR_EMAIL": "your@email.com"
  }
}
```

## Using with GitHub Codespaces

Nothing. Just works.

## Machine-local files (not in this repo)

| File | What goes in it |
| --- | --- |
| `~/.gitconfig.local` | `user.name` and `user.email`. Created by `install.sh`, which carries the values over from a pre-existing `~/.gitconfig`. |
| `~/.env` | API keys (`DEEPSEEK_API_KEY`, `ZAI_API_KEY`, …). Sourced by `.zshrc` if present. |
| `~/.zshrc-local` | Symlink to `config/.zshrc-local.macos` or `.linux`, picked by `install.sh`. |

## Maintenance

```bash
brew bundle dump --force --no-vscode    # refresh Brewfile after installing apps
brew update && brew upgrade             # keep packages current
./test/run_test                         # verify install.sh on a clean Linux image
```
