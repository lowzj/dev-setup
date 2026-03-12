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

pkg_ensure_index_updated() {
  local pkg_manager="$1"
  local _has_sudo="$2"
  local dry_run="$3"
  local verbose="$4"

  if [[ "$PKG_UPDATED" -eq 1 ]]; then
    return 0
  fi

  case "$pkg_manager" in
    brew)
      log_info "Updating Homebrew index"
      run_cmd "$dry_run" "$verbose" brew update </dev/null
      ;;
    *)
      log_warn "No supported package manager available"
      return 1
      ;;
  esac

  PKG_UPDATED=1
}

pkg_install_one() {
  local pkg_manager="$1"
  local _has_sudo="$2"
  local dry_run="$3"
  local verbose="$4"
  local pkg="$5"

  case "$pkg_manager" in
    brew)
      run_cmd "$dry_run" "$verbose" brew install "$pkg" </dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

pkg_bootstrap_homebrew() {
  local pkg_manager_var="$1"
  local dry_run="$2"
  local verbose="$3"
  local installer=""

  if find_brew_bin >/dev/null 2>&1; then
    bootstrap_homebrew_runtime_env || true
    eval "$pkg_manager_var='brew'"
    return 0
  fi

  if ! is_command_available curl; then
    log_error "curl is required to install Homebrew on macOS"
    return 1
  fi

  log_info "Installing Homebrew via official installer"
  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would run: NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL $HOMEBREW_INSTALL_URL)\""
    eval "$pkg_manager_var='brew'"
    return 0
  fi

  installer="$(curl -fsSL "$HOMEBREW_INSTALL_URL")" || {
    log_error "Failed to download Homebrew installer"
    return 1
  }

  if ! env NONINTERACTIVE=1 /bin/bash -c "$installer" </dev/null; then
    log_error "Homebrew installer failed"
    return 1
  fi

  if ! bootstrap_homebrew_runtime_env; then
    log_error "Homebrew installed but brew is still not available in PATH"
    return 1
  fi

  eval "$pkg_manager_var='brew'"
  PKG_UPDATED=0
}

pkg_ensure_manager_available() {
  local platform="$1"
  local pkg_manager_var="$2"
  local dry_run="$3"
  local verbose="$4"
  local current_pkg_manager="${!pkg_manager_var}"

  if [[ "$current_pkg_manager" != "none" ]]; then
    return 0
  fi

  if [[ "$platform" == "macos" ]]; then
    pkg_bootstrap_homebrew "$pkg_manager_var" "$dry_run" "$verbose" || return 1
    return 0
  fi

  log_error "No package manager available. Supported: brew"
  return 1
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
  local platform="$1"
  local pkg_manager_var="$2"
  local has_sudo="$3"
  local dry_run="$4"
  local verbose="$5"
  local logical=""
  local pkg=""
  local checks=""
  local line_seen=0
  local failed=0
  local failed_items=""
  local current_pkg_manager="${!pkg_manager_var}"
  local manager_ready=0

  while IFS=$'\t' read -r logical pkg checks; do
    if [[ -z "$logical" && -z "$pkg" && -z "$checks" ]]; then
      continue
    fi

    if [[ -z "$logical" ]]; then
      logical="${pkg:-unknown}"
    fi

    if [[ -n "$checks" ]] && pkg_any_command_available "$checks"; then
      log_info "$logical already installed, skipping"
      continue
    fi

    if [[ -z "$pkg" ]]; then
      log_warn "No package mapping for '$logical' on $current_pkg_manager, skipping"
      continue
    fi

    if [[ "$manager_ready" -eq 0 ]]; then
      pkg_ensure_manager_available "$platform" "$pkg_manager_var" "$dry_run" "$verbose" || return 1
      current_pkg_manager="${!pkg_manager_var}"
      manager_ready=1
    fi

    if [[ "$line_seen" -eq 0 ]]; then
      pkg_ensure_index_updated "$current_pkg_manager" "$has_sudo" "$dry_run" "$verbose" || return 1
      line_seen=1
    fi

    log_info "Installing $logical ($pkg via $current_pkg_manager)"
    if ! pkg_install_one "$current_pkg_manager" "$has_sudo" "$dry_run" "$verbose" "$pkg"; then
      log_warn "Install failed for $logical ($pkg), continuing"
      failed=1
      if [[ -z "$failed_items" ]]; then
        failed_items="$logical"
      else
        failed_items="$failed_items, $logical"
      fi
    fi
  done

  if [[ "$failed" -eq 1 ]]; then
    log_error "Package installation failed for: $failed_items"
    return 1
  fi
}

pkg_install_specs_text() {
  local platform="$1"
  local pkg_manager_var="$2"
  local has_sudo="$3"
  local dry_run="$4"
  local verbose="$5"
  local specs="$6"

  if [[ -z "$specs" ]]; then
    return 0
  fi

  pkg_install_specs_stream "$platform" "$pkg_manager_var" "$has_sudo" "$dry_run" "$verbose" <<<"$specs"
}
