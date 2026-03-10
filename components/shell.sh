#!/usr/bin/env bash

shell_phase_packages() {
  local _platform="$1"
  local _pkg_manager="$2"

  pkg_spec_print starship starship starship
  pkg_spec_print direnv direnv direnv
  return 0
}

shell_install_starship() {
  local dry_run="$1"
  local verbose="$2"

  if is_command_available starship; then
    log_info "starship already installed"
    return 0
  fi

  log_info "Installing starship via install script"
  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir $HOME/.local/bin"
    return 0
  fi

  ensure_dir "$dry_run" "$verbose" "$HOME/.local/bin" || return 1
  if ! curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin"; then
    log_warn "starship install script failed"
    return 1
  fi
}

shell_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local verbose="$3"
  local failed=0

  if ! is_command_available starship; then
    if ! shell_install_starship "$dry_run" "$verbose"; then
      failed=1
    fi
  fi

  return "$failed"
}

shell_phase_configure() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
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
fi

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
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

  append_managed_block "$force" "$dry_run" "$verbose" "$zshrc" "$begin" "$end" "$block"
}
