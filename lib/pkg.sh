#!/usr/bin/env bash

PKG_UPDATED=0
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

pkg_spec_print() {
  local logical="$1"
  local pkg="${2:-}"
  local checks="${3:-}"

  printf '%s\t%s\t%s\n' "$logical" "$pkg" "$checks"
}

pkg_specs_dedup() {
  awk 'NF && !seen[$0]++'
}

pkg_run_as_root_if_needed() {
  if [[ "${EUID:-$(id -u)}" -eq 0 || "${HAS_SUDO:-0}" -eq 0 ]]; then
    run_cmd "$@"
  else
    run_cmd sudo "$@"
  fi
}

pkg_ensure_index_updated() {
  if [[ "$PKG_UPDATED" -eq 1 ]]; then
    return 0
  fi

  case "$PKG_MANAGER" in
    brew)
      log_info "Updating Homebrew index"
      run_cmd brew update
      ;;
    apt)
      log_info "Updating apt index"
      pkg_run_as_root_if_needed apt-get update
      ;;
    dnf)
      log_info "Updating dnf index"
      pkg_run_as_root_if_needed dnf makecache -y
      ;;
    *)
      log_warn "No supported package manager available"
      return 1
      ;;
  esac

  PKG_UPDATED=1
}

pkg_install_one() {
  local pkg="$1"

  case "$PKG_MANAGER" in
    brew)
      run_cmd brew install "$pkg"
      ;;
    apt)
      pkg_run_as_root_if_needed env DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
      ;;
    dnf)
      pkg_run_as_root_if_needed dnf install -y "$pkg"
      ;;
    *)
      return 1
      ;;
  esac
}

pkg_bootstrap_homebrew() {
  local installer=""

  if [[ "$PLATFORM" != "macos" ]]; then
    return 1
  fi

  if find_brew_bin >/dev/null 2>&1; then
    bootstrap_homebrew_runtime_env || true
    PKG_MANAGER="brew"
    return 0
  fi

  if ! is_command_available curl; then
    log_error "curl is required to install Homebrew on macOS"
    return 1
  fi

  log_info "Installing Homebrew via official installer"
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would run: NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL $HOMEBREW_INSTALL_URL)\""
    PKG_MANAGER="brew"
    return 0
  fi

  installer="$(curl -fsSL "$HOMEBREW_INSTALL_URL")" || {
    log_error "Failed to download Homebrew installer"
    return 1
  }

  if ! env NONINTERACTIVE=1 /bin/bash -c "$installer"; then
    log_error "Homebrew installer failed"
    return 1
  fi

  if ! bootstrap_homebrew_runtime_env; then
    log_error "Homebrew installed but brew is still not available in PATH"
    return 1
  fi

  PKG_MANAGER="brew"
  PKG_UPDATED=0
}

pkg_ensure_manager_available() {
  if [[ "$PKG_MANAGER" != "none" ]]; then
    return 0
  fi

  if [[ "$PLATFORM" == "macos" ]]; then
    pkg_bootstrap_homebrew || return 1
  fi

  if [[ "$PKG_MANAGER" == "none" ]]; then
    log_error "No package manager available. Supported: brew/apt/dnf"
    return 1
  fi
}

pkg_any_command_available() {
  local checks_csv="$1"
  local check=""

  for check in ${checks_csv//,/ }; do
    if is_command_available "$check"; then
      return 0
    fi
  done

  return 1
}

pkg_install_specs_stream() {
  local logical=""
  local pkg=""
  local checks=""
  local line_seen=0

  pkg_ensure_manager_available || return 1

  while IFS=$'\t' read -r logical pkg checks; do
    if [[ -z "$logical" && -z "$pkg" && -z "$checks" ]]; then
      continue
    fi

    if [[ "$line_seen" -eq 0 ]]; then
      pkg_ensure_index_updated || return 1
      line_seen=1
    fi

    if [[ -z "$logical" ]]; then
      logical="${pkg:-unknown}"
    fi

    if [[ -n "$checks" ]] && pkg_any_command_available "$checks"; then
      log_info "$logical already installed, skipping"
      continue
    fi

    if [[ -z "$pkg" ]]; then
      log_warn "No package mapping for '$logical' on $PKG_MANAGER, skipping"
      continue
    fi

    log_info "Installing $logical ($pkg via $PKG_MANAGER)"
    if ! pkg_install_one "$pkg"; then
      log_warn "Install failed for $logical ($pkg), continuing"
    fi
  done
}

pkg_install_specs_text() {
  local specs="$1"

  if [[ -z "$specs" ]]; then
    return 0
  fi

  pkg_install_specs_stream <<<"$specs"
}
