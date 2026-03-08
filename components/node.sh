#!/usr/bin/env bash

node_phase_packages() {
  case "$PKG_MANAGER" in
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
  if is_command_available pnpm; then
    return 0
  fi

  node_install_pnpm
}
