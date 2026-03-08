#!/usr/bin/env bash

shell_phase_packages() {
  case "$PKG_MANAGER" in
    brew)
      echo "starship|starship|starship direnv|direnv|direnv"
      ;;
    apt|dnf)
      echo "direnv|direnv|direnv"
      ;;
    *)
      echo ""
      ;;
  esac
}

shell_install_starship() {
  if is_command_available starship; then
    log_info "starship already installed"
    return 0
  fi

  log_info "Installing starship via install script"
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir $HOME/.local/bin"
    return 0
  fi

  ensure_dir "$HOME/.local/bin" || return 1
  if ! curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin"; then
    log_warn "starship install script failed"
    return 1
  fi
}

shell_phase_install() {
  local failed=0

  if ! is_command_available starship; then
    if ! shell_install_starship; then
      failed=1
    fi
  fi

  return "$failed"
}

shell_phase_configure() {
  local zshrc="$HOME/.zshrc"
  local begin="# >>> dev-setup shell >>>"
  local end="# <<< dev-setup shell <<<"
  local block=""

  block="$(cat <<'BLOCK'
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
export PATH="$PNPM_HOME:$HOME/.local/bin:$PATH"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
fi

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
elif command -v fdfind >/dev/null 2>&1; then
  alias find='fdfind'
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
BLOCK
)"

  append_managed_block "$zshrc" "$begin" "$end" "$block"
}
