#!/usr/bin/env bash

PKG_UPDATED=0

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

pkg_install_specs() {
  local spec=""
  local logical=""
  local pkg=""
  local checks=""

  if [[ "$PKG_MANAGER" == "none" ]]; then
    log_error "No package manager available. Supported: brew/apt/dnf"
    return 1
  fi

  pkg_ensure_index_updated || return 1

  for spec in "$@"; do
    if [[ -z "$spec" ]]; then
      continue
    fi

    IFS='|' read -r logical pkg checks <<< "$spec"

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
