#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-git@github.com-personal:GianmarcoFolchi/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-master}"
SETUP_REPO_URL="https://raw.githubusercontent.com/GianmarcoFolchi/setup/master"

log()  { printf '→ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*" >&2; }
die()  { printf '✗ %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

dotgit() {
  git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

clone_dotfiles() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    log "Bare repo already exists at $DOTFILES_DIR — skipping clone"
    return
  fi

  log "Cloning bare repo..."
  git clone --bare "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
  dotgit config --local status.showUntrackedFiles no

  log "Checking out $DOTFILES_BRANCH..."
  if dotgit checkout "$DOTFILES_BRANCH" 2>/dev/null; then
    log "Checkout complete"
    return
  fi

  local backup="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
  mkdir -p "$backup"
  log "Backing up conflicting files to $backup"

  dotgit checkout "$DOTFILES_BRANCH" 2>&1 \
    | grep -E '^\s' \
    | awk '{print $1}' \
    | while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        [[ -e "$HOME/$path" ]] || continue
        mkdir -p "$backup/$(dirname "$path")"
        mv "$HOME/$path" "$backup/$path"
      done

  dotgit checkout "$DOTFILES_BRANCH"
  log "Checkout complete (conflicts backed up to $backup)"
}

setup_brew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  setup_brew_path

  if have brew; then
    log "Homebrew already installed: $(brew --version | head -1)"
    return
  fi

  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  setup_brew_path

  if ! have brew; then
    die "Homebrew installation succeeded but brew is not on PATH"
  fi

  log "Homebrew installed: $(brew --version | head -1)"
}

install_packages() {
  log "Installing packages via brew bundle..."

  local tmpfile
  tmpfile="$(mktemp)"
  trap 'rm -f "$tmpfile"' RETURN

  cat > "$tmpfile" <<'BREWFILE'
brew "git"
brew "curl"
brew "wget"
brew "neovim"
brew "tmux"
brew "zsh"
brew "fzf"
brew "ripgrep"
brew "fd"
brew "bat"
brew "zoxide"
brew "yazi"
brew "htop"
brew "trash-cli"
brew "lazygit"
brew "tree-sitter"
BREWFILE

  brew bundle --no-lock --file="$tmpfile"
  log "Packages installed"
}

check_nvim_version() {
  if ! have nvim; then
    warn "Neovim not found on PATH after install"
    return
  fi

  local nvim_version
  nvim_version="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"

  if [[ "$(printf '%s\n' "0.11.0" "$nvim_version" | sort -V | head -1)" != "0.11.0" ]]; then
    warn "Neovim $nvim_version is below 0.11.0 — LazyVim may not work correctly"
  else
    log "Neovim $nvim_version (meets LazyVim requirement)"
  fi
}

install_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Oh My Zsh already installed"
    return
  fi

  log "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log "Oh My Zsh installed"
}

install_clipboard_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    return
  fi

  if have xclip || have wl-copy; then
    log "Clipboard tool already available"
    return
  fi

  if have brew; then
    log "Installing xclip for Neovim clipboard support..."
    brew install xclip 2>/dev/null || warn "Could not install xclip via brew — install manually for clipboard support"
  fi
}

print_summary() {
  echo ""
  log "Install complete."
  echo ""

  if have nvim; then echo "  neovim:  $(nvim --version | head -1)"; fi
  if have tmux; then echo "  tmux:    $(tmux -V)"; fi
  if have zsh;  then echo "  zsh:     $(zsh --version)"; fi

  echo ""
  log "Next: configure plugins and shell:"
  echo "    curl -fsSL ${SETUP_REPO_URL}/configure.sh | bash"
  echo ""
}

main() {
  clone_dotfiles
  install_homebrew
  install_packages
  check_nvim_version
  install_ohmyzsh
  install_clipboard_linux
  print_summary
}

main "$@"
