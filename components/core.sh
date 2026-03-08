#!/usr/bin/env bash

core_phase_packages() {
  case "$PKG_MANAGER" in
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
