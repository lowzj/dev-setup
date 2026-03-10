#!/usr/bin/env bash

is_xcode_clt_available() {
  command -v xcode-select >/dev/null 2>&1 && xcode-select -p >/dev/null 2>&1
}

print_xcode_clt_install_help() {
  printf '%s\n' 'Install Xcode Command Line Tools with: xcode-select --install' >&2
}

detect_platform() {
  local uname_s
  uname_s="$(uname -s)"

  case "$uname_s" in
    Darwin)
      PLATFORM="macos"
      ;;
    *)
      PLATFORM="unknown"
      ;;
  esac
}

detect_pkg_manager() {
  PKG_MANAGER="none"

  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v brew >/dev/null 2>&1; then
      PKG_MANAGER="brew"
    fi
  fi
}

detect_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    HAS_SUDO=1
  else
    HAS_SUDO=0
  fi
}

detect_environment() {
  detect_platform
  detect_pkg_manager
  detect_sudo
}
