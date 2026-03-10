#!/usr/bin/env bash

core_phase_packages() {
  local _platform="$1"
  local _pkg_manager="$2"

  pkg_spec_print git git git
  pkg_spec_print zsh zsh zsh
  pkg_spec_print tmux tmux tmux
  pkg_spec_print neovim neovim nvim
  pkg_spec_print ripgrep ripgrep rg
  pkg_spec_print fd fd fd
  pkg_spec_print fzf fzf fzf
  pkg_spec_print bat bat bat
  pkg_spec_print eza eza eza
  pkg_spec_print curl curl curl
  pkg_spec_print gh gh gh
  pkg_spec_print jq jq jq
  return 0
}
