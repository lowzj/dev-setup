#!/usr/bin/env bash

node_phase_packages() {
  case "$PKG_MANAGER" in
    brew)
      echo "node|node|node,npm,corepack pnpm|pnpm|pnpm"
      ;;
    apt)
      echo "node|nodejs|node,nodejs"
      ;;
    dnf)
      echo "node|nodejs|node,nodejs,npm,corepack"
      ;;
    *)
      echo ""
      ;;
  esac
}

node_phase_install() {
  if is_command_available pnpm; then
    return 0
  fi

  node_install_pnpm
}
