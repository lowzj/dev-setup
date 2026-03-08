#!/usr/bin/env bash

core_phase_packages() {
  local platform="$1"
  local pkg_manager="$2"
  local effective_pkg_manager="$pkg_manager"

  if [[ "$platform" == "macos" && "$effective_pkg_manager" == "none" ]]; then
    effective_pkg_manager="brew"
  fi

  case "$effective_pkg_manager" in
    brew)
      pkg_spec_print git git git
      pkg_spec_print zsh zsh zsh
      pkg_spec_print tmux tmux tmux
      pkg_spec_print neovim neovim nvim
      pkg_spec_print ripgrep ripgrep rg
      pkg_spec_print fd fd fd,fdfind
      pkg_spec_print fzf fzf fzf
      pkg_spec_print bat bat bat,batcat
      pkg_spec_print eza eza eza
      pkg_spec_print curl curl curl
      ;;
    apt|dnf)
      pkg_spec_print git git git
      pkg_spec_print zsh zsh zsh
      pkg_spec_print tmux tmux tmux
      pkg_spec_print neovim neovim nvim
      pkg_spec_print ripgrep ripgrep rg
      pkg_spec_print fd fd-find fd,fdfind
      pkg_spec_print fzf fzf fzf
      pkg_spec_print bat bat bat,batcat
      pkg_spec_print eza eza eza
      pkg_spec_print curl curl curl
      ;;
    *)
      return 0
      ;;
  esac
}
