#!/usr/bin/env bash

core_phase_packages() {
  case "$PKG_MANAGER" in
    brew)
      echo "git|git|git zsh|zsh|zsh tmux|tmux|tmux neovim|neovim|nvim ripgrep|ripgrep|rg fd|fd|fd,fdfind fzf|fzf|fzf bat|bat|bat,batcat eza|eza|eza curl|curl|curl"
      ;;
    apt|dnf)
      echo "git|git|git zsh|zsh|zsh tmux|tmux|tmux neovim|neovim|nvim ripgrep|ripgrep|rg fd|fd-find|fd,fdfind fzf|fzf|fzf bat|bat|bat,batcat eza|eza|eza curl|curl|curl"
      ;;
    *)
      echo ""
      ;;
  esac
}
