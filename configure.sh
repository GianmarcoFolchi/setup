#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

log()  { printf '→ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*" >&2; }
die()  { printf '✗ %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

setup_brew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

maybe_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

verify_prerequisites() {
  local ok=true

  if [[ ! -d "$DOTFILES_DIR" ]]; then
    warn "Bare repo not found at $DOTFILES_DIR — run install.sh first"
    ok=false
  fi

  for cmd in nvim tmux zsh git; do
    if ! have "$cmd"; then
      warn "$cmd not found on PATH — run install.sh first"
      ok=false
    fi
  done

  if [[ "$ok" == false ]]; then
    die "Prerequisites missing. Run install.sh before configure.sh."
  fi

  log "Prerequisites verified"
}

install_omz_plugin() {
  local name="$1"
  local repo="$2"
  local target="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"

  if [[ -d "$target" ]]; then
    log "$name already installed"
    return
  fi

  log "Installing $name..."
  git clone "$repo" "$target"
}

install_omz_plugins() {
  install_omz_plugin "zsh-syntax-highlighting" \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"

  install_omz_plugin "zsh-autosuggestions" \
    "https://github.com/zsh-users/zsh-autosuggestions"

  install_omz_plugin "you-should-use" \
    "https://github.com/MichaelAquilina/zsh-you-should-use.git"
}

set_default_shell() {
  local zsh_path
  zsh_path="$(which zsh)"

  if [[ "$SHELL" == *zsh ]]; then
    log "Default shell is already zsh"
    return
  fi

  log "Setting default shell to zsh..."

  if [[ "$(uname -s)" == "Linux" ]]; then
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
      log "Adding $zsh_path to /etc/shells..."
      echo "$zsh_path" | maybe_sudo tee -a /etc/shells > /dev/null
    fi
  fi

  if chsh -s "$zsh_path" 2>/dev/null; then
    log "Default shell set to zsh"
  else
    warn "chsh failed — change your shell manually: chsh -s $zsh_path"
  fi
}

install_tpm_and_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [[ ! -d "$tpm_dir" ]]; then
    log "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  else
    log "TPM already installed"
  fi

  log "Installing Tmux plugins..."
  "$tpm_dir/bin/install_plugins" || warn "TPM plugin install had issues — run Prefix + I in tmux to retry"
}

sync_nvim_plugins() {
  log "Syncing Neovim plugins via lazy-lock.json..."
  if nvim --headless "+Lazy! restore" +qa 2>/dev/null; then
    log "Neovim plugins synced"
  else
    warn "Neovim plugin sync had issues — open nvim and run :Lazy restore manually"
  fi
}

print_summary() {
  local zsh_path
  zsh_path="$(which zsh 2>/dev/null || echo "zsh")"

  echo ""
  log "Configuration complete."
  echo ""
  echo "  Open a new terminal or run: exec $zsh_path -l"
  echo ""
  echo "  Note: The first time you open nvim, Mason will auto-install"
  echo "  LSP servers and formatters. This takes ~2 minutes and requires"
  echo "  internet access. Subsequent launches are instant."
  echo ""
}

main() {
  setup_brew_path
  verify_prerequisites
  install_omz_plugins
  set_default_shell
  install_tpm_and_plugins
  sync_nvim_plugins
  print_summary
}

main "$@"
