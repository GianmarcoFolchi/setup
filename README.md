# Setup

Cross-platform dev environment bootstrap for macOS and Linux. Installs Neovim, Tmux, Zsh, and tooling via Homebrew on both platforms.

## Quick Start

### 1. Install prerequisites

```bash
curl -fsSL https://raw.githubusercontent.com/GianmarcoFolchi/setup/master/bootstrap.sh | bash
```

### 2. Authenticate with GitHub

```bash
gh auth login
```

### 3. Install tools and configure

```bash
curl -fsSL https://raw.githubusercontent.com/GianmarcoFolchi/setup/master/install.sh | bash && \
curl -fsSL https://raw.githubusercontent.com/GianmarcoFolchi/setup/master/configure.sh | bash
```

## What Each Script Does

| Script | Purpose |
|--------|---------|
| `bootstrap.sh` | Installs git, curl, gh, and build tools via the native package manager |
| `install.sh` | Clones dotfiles, installs Homebrew, installs all packages, installs Oh My Zsh |
| `configure.sh` | Installs OMZ plugins, TPM + tmux plugins, syncs Neovim plugins via lazy-lock.json, sets zsh as default shell |

All scripts are idempotent — safe to re-run.

## Re-running

```bash
curl -fsSL https://raw.githubusercontent.com/GianmarcoFolchi/setup/master/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/GianmarcoFolchi/setup/master/configure.sh | bash
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTFILES_REPO_URL` | auto-detected via `gh auth` | Override to skip auto-detection |
| `DOTFILES_DIR` | `$HOME/dotfiles` | Where to clone the bare repo |
| `DOTFILES_BRANCH` | `master` | Branch to checkout |
| `NONINTERACTIVE` | unset | Set to `1` to skip all prompts |

The dotfiles clone URL is auto-detected from your `gh auth` session. It always clones via HTTPS using the `gh` credential helper. After checkout, if your `.ssh/config` contains a GitHub host alias (e.g. `github.com-personal`), the remote is automatically switched to use it for subsequent SSH operations.
