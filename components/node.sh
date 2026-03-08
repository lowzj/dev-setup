#!/usr/bin/env bash

node_phase_packages() {
  local platform="$1"
  local pkg_manager="$2"
  local effective_pkg_manager="$pkg_manager"

  if [[ "$platform" == "macos" && "$effective_pkg_manager" == "none" ]]; then
    effective_pkg_manager="brew"
  fi

  case "$effective_pkg_manager" in
    brew)
      pkg_spec_print node node node,npm,corepack
      pkg_spec_print pnpm pnpm pnpm
      ;;
    apt)
      pkg_spec_print node nodejs node,nodejs
      ;;
    dnf)
      pkg_spec_print node nodejs node,nodejs,npm,corepack
      ;;
    *)
      return 0
      ;;
  esac
}

node_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local verbose="$3"

  if is_command_available pnpm; then
    return 0
  fi

  node_install_pnpm "$dry_run" "$verbose"
}
