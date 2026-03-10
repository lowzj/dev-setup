#!/usr/bin/env bash

fonts_default_nerd_font_cask() {
  printf '%s\n' "${DEV_SETUP_NERD_FONT_CASK:-font-jetbrains-mono-nerd-font}"
}

fonts_default_nerd_font_family() {
  case "$(fonts_default_nerd_font_cask)" in
    font-jetbrains-mono-nerd-font)
      printf '%s\n' "JetBrainsMono Nerd Font Mono"
      ;;
    font-meslo-lg-nerd-font)
      printf '%s\n' "MesloLGS Nerd Font Mono"
      ;;
    *)
      printf '%s\n' "the installed Nerd Font family"
      ;;
  esac
}

fonts_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local verbose="$3"
  local platform="$4"
  local pkg_manager="$5"
  local _has_sudo="$6"
  local cask=""
  local family=""

  cask="$(fonts_default_nerd_font_cask)"
  family="$(fonts_default_nerd_font_family)"

  pkg_ensure_manager_available "$platform" pkg_manager "$dry_run" "$verbose" || return 1

  if [[ "$pkg_manager" != "brew" ]]; then
    log_error "fonts component requires Homebrew on macOS"
    return 1
  fi

  if brew list --cask "$cask" >/dev/null 2>&1; then
    log_info "$family already installed, skipping"
    return 0
  fi

  log_info "Installing $family via Homebrew cask ($cask)"
  run_cmd "$dry_run" "$verbose" brew install --cask "$cask" || return 1
  log_info "Set your terminal font to $family to render Neovim icons correctly"
}
