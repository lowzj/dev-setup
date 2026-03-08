#!/usr/bin/env bash

nvim_phase_configure() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
  local nvim_dir="$HOME/.config/nvim"
  local parent_dir="$HOME/.config"

  ensure_dir "$dry_run" "$verbose" "$parent_dir"

  if [[ -d "$nvim_dir" ]] && [[ -n "$(ls -A "$nvim_dir" 2>/dev/null)" ]]; then
    if [[ "$force" -ne 1 ]]; then
      log_warn "$nvim_dir exists and is non-empty, skipping (use --force to replace)"
      return 0
    fi

    backup_path "$dry_run" "$verbose" "$nvim_dir"
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would clone LazyVim starter into $nvim_dir"
    return 0
  fi

  if [[ -d "$nvim_dir" ]]; then
    rm -rf "$nvim_dir"
  fi

  git clone https://github.com/LazyVim/starter "$nvim_dir"
  rm -rf "$nvim_dir/.git"
  log_info "Neovim config initialized at $nvim_dir"
}
