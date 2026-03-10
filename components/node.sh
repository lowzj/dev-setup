#!/usr/bin/env bash

node_phase_packages() {
  local _platform="$1"
  local _pkg_manager="$2"

  pkg_spec_print node node node,npm,corepack
  pkg_spec_print pnpm pnpm pnpm
  return 0
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
