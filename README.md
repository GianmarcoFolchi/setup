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

The dotfiles clone URL is auto-detected from your `gh auth` session. It always clones via HTTPS using the `gh` credential helper. After checkout, if your `.ssh/config` contains a GitHub host alias (e.g. `github.com-personal`) and SSH connectivity works, the remote is automatically switched to SSH.

## SSH Keys (Optional)

If you use SSH to push to GitHub (e.g. on a work laptop with multiple GitHub accounts), copy your SSH keys to the new machine **before** running `install.sh`:

```bash
# From your existing machine — copy keys to the new one
scp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub user@new-machine:~/.ssh/

# On the new machine — set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

The install script will:
1. Clone dotfiles via HTTPS (always works after `gh auth login`)
2. Check out your `.ssh/config` from dotfiles
3. Test if the SSH alias in `.ssh/config` can connect to GitHub
4. If SSH works, switch the remote to SSH automatically
5. If SSH doesn't work, keep HTTPS and print instructions for switching later

If you only use HTTPS (e.g. personal laptop), skip this — everything works without SSH keys.
