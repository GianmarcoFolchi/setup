#!/usr/bin/env bash
set -euo pipefail

SETUP_REPO_URL="https://raw.githubusercontent.com/GianmarcoFolchi/setup/main"

log()  { printf '→ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*" >&2; }
die()  { printf '✗ %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

detect_pkg_family() {
  case "$(uname -s)" in
    Darwin) echo "brew"; return ;;
  esac

  if [[ ! -r /etc/os-release ]]; then
    echo "unknown"; return
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  case "${ID:-}" in
    ubuntu|debian|pop|linuxmint)      echo "apt"    ;;
    fedora|rhel|centos|rocky|alma)    echo "dnf"    ;;
    arch|manjaro|endeavouros)         echo "pacman" ;;
    alpine)                           echo "apk"    ;;
    opensuse*)                        echo "zypper" ;;
    *)
      case "${ID_LIKE:-}" in
        *debian*)        echo "apt"    ;;
        *fedora*|*rhel*) echo "dnf"    ;;
        *arch*)          echo "pacman" ;;
        *)               echo "unknown" ;;
      esac ;;
  esac
}

install_linux_prerequisites() {
  local family="$1"

  log "Detected package family: $family"

  case "$family" in
    apt)
      sudo apt-get update -y
      sudo apt-get install -y git curl build-essential
      ;;
    dnf)
      sudo dnf install -y git curl gcc gcc-c++ make
      ;;
    pacman)
      sudo pacman -Sy --needed --noconfirm git curl base-devel
      ;;
    apk)
      sudo apk add --no-cache git curl build-base
      ;;
    zypper)
      sudo zypper refresh
      sudo zypper install -y git curl gcc gcc-c++ make
      ;;
    *)
      die "Unknown Linux distro. Install git, curl, and a C compiler manually, then re-run."
      ;;
  esac

  install_gh_cli "$family"
}

install_gh_cli() {
  local family="$1"

  if have gh; then
    log "gh already installed: $(gh --version | head -1)"
    return
  fi

  log "Installing GitHub CLI..."

  case "$family" in
    apt)
      sudo mkdir -p -m 755 /etc/apt/keyrings
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli-stable.list > /dev/null
      sudo apt-get update -y
      sudo apt-get install -y gh
      ;;
    dnf)
      sudo dnf install -y 'dnf-command(config-manager)'
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      sudo dnf install -y gh
      ;;
    pacman)
      sudo pacman -S --needed --noconfirm github-cli
      ;;
    apk)
      sudo apk add --no-cache github-cli
      ;;
    zypper)
      sudo zypper install -y gh
      ;;
    *)
      warn "Could not install gh automatically. Install it manually: https://cli.github.com/"
      ;;
  esac
}

setup_macos() {
  if xcode-select -p &>/dev/null; then
    log "Xcode Command Line Tools already installed"
  else
    log "Installing Xcode Command Line Tools..."
    xcode-select --install
    log "Waiting for Xcode CLT installation to complete..."
    until xcode-select -p &>/dev/null; do
      sleep 5
    done
  fi

  if ! have gh; then
    if have brew; then
      log "Installing GitHub CLI via Homebrew..."
      brew install gh
    else
      log "Installing GitHub CLI..."
      curl -fsSL https://cli.github.com/packages/Homebrew/gh.rb > /dev/null 2>&1 || true
      warn "gh not found and Homebrew not yet installed. Install gh after running install.sh, or authenticate via SSH key."
    fi
  fi
}

verify() {
  local ok=true

  for cmd in git curl; do
    if have "$cmd"; then
      log "$cmd: $($cmd --version | head -1)"
    else
      warn "$cmd is not installed"
      ok=false
    fi
  done

  if have gh; then
    log "gh: $(gh --version | head -1)"
  else
    warn "gh is not installed — you can authenticate via SSH key instead"
  fi

  if [[ "$ok" == false ]]; then
    die "Missing prerequisites. Fix the issues above and re-run."
  fi
}

print_next_steps() {
  echo ""
  log "Prerequisites installed."
  echo ""
  log "Step 1: Authenticate with GitHub:"
  echo "    gh auth login"
  echo ""
  log "Step 2: Run this to install everything:"
  echo "    curl -fsSL ${SETUP_REPO_URL}/install.sh | bash && curl -fsSL ${SETUP_REPO_URL}/configure.sh | bash"
  echo ""
}

main() {
  local os
  os="$(uname -s)"

  log "Detecting OS..."

  case "$os" in
    Darwin)
      log "macOS detected"
      setup_macos
      ;;
    Linux)
      log "Linux detected"
      local family
      family="$(detect_pkg_family)"
      install_linux_prerequisites "$family"
      ;;
    *)
      die "Unsupported OS: $os"
      ;;
  esac

  verify
  print_next_steps
}

main "$@"
