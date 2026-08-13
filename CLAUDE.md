# Repository Guidelines

## Project Structure & Module Organization
- `Brewfile` lists Homebrew packages, casks, and Mac App Store apps.
- `install.sh` bootstraps a machine: symlinks `config/` into `$HOME`, then branches by OS.
- `install-macos.sh` macOS-specific bootstrap actions. Sourced by `install.sh`.
- `install-linux.sh` Linux-specific bootstrap actions (dev containers / Codespaces). Sourced by `install.sh`.
- `macos-defaults.sh` applies macOS system preferences. Run by hand, never from `install.sh`.
- `config/` holds every dotfile source that gets symlinked into `$HOME`.
- `test/` builds a dev container image and runs `install.sh` inside it.
- `README.md` documents setup, maintenance, and the expected layout.

## Build, Test, and Development Commands
- `./install.sh` sets up a machine (symlinks, Homebrew + Brewfile on macOS, apt/nvm/gh on Linux).
- `./macos-defaults.sh` applies macOS preferences (Finder, Dock, keyboard, etc.).
- `./test/run_test` builds `test/Dockerfile.test` and runs `install.sh` on a clean Linux image.
- `brew bundle dump --force --no-vscode` updates `Brewfile` after app changes.
- `brew update && brew upgrade` keeps Homebrew packages current.

## Coding Style & Naming Conventions
- Match existing file style in the directory you edit.
- Prefer concise, descriptive names for scripts and aliases; keep shell functions lowercase.
- Use POSIX-friendly shell where reasonable; add a brief comment for non-obvious steps.
- No formal formatter is configured; keep indentation consistent with nearby lines.

## Testing Guidelines
- No automated test suite beyond `test/run_test`.
- `install.sh` must stay idempotent: re-running it on a configured machine should not
  destroy anything. Use the `link()` helper so real files get backed up to `.bak`.
- Validate macOS changes by running the relevant script and checking the resulting symlinks.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits (examples: `feat: add codex installer step`, `refactor: simplified new branch alias`).
- Keep commits focused (one logical change per commit).
- PRs should describe the change, list commands run (if any), and note any manual steps needed.

## Security & Configuration Tips
- This repository is public. Never commit secrets, tokens, private keys, or personal
  identity: `user.name`/`user.email` live in `~/.gitconfig.local`, API keys in `~/.env`.
  Neither file is tracked here.
- Dotfiles are symlinked into `$HOME`; verify changes in both the repo and the target file.
