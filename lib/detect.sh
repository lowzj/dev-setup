#!/usr/bin/env bash

detect_platform() {
  local uname_s
  uname_s="$(uname -s)"

  case "$uname_s" in
    Darwin)
      PLATFORM="macos"
      ;;
    Linux)
      PLATFORM="linux"
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
    return
  fi

  if [[ "$PLATFORM" == "linux" ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      PKG_MANAGER="apt"
      return
    fi
    if command -v dnf >/dev/null 2>&1; then
      PKG_MANAGER="dnf"
      return
    fi
    if command -v brew >/dev/null 2>&1; then
      PKG_MANAGER="brew"
      return
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
