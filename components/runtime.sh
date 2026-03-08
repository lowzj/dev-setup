#!/usr/bin/env bash

runtime_phase_packages() {
  local platform="$1"
  local pkg_manager="$2"
  local effective_pkg_manager="$pkg_manager"

  if [[ "$platform" == "macos" && "$effective_pkg_manager" == "none" ]]; then
    effective_pkg_manager="brew"
  fi

  case "$effective_pkg_manager" in
    brew)
      pkg_spec_print go go go
      pkg_spec_print mise mise mise
      pkg_spec_print uv uv uv
      ;;
    apt)
      pkg_spec_print go golang go
      ;;
    dnf)
      pkg_spec_print go golang go
      pkg_spec_print uv uv uv
      ;;
    *)
      return 0
      ;;
  esac
}

runtime_install_mise() {
  local dry_run="$1"

  if is_command_available mise; then
    log_info "mise already installed"
    return 0
  fi

  log_info "Installing mise via install script"
  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://mise.run | sh"
    return 0
  fi

  if ! curl -fsSL https://mise.run | sh; then
    log_warn "mise install script failed"
    return 1
  fi
}

runtime_install_rustup() {
  local dry_run="$1"

  if is_command_available rustup; then
    log_info "rustup already installed"
    return 0
  fi

  log_info "Installing rustup via install script"
  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://sh.rustup.rs | sh -s -- -y"
    return 0
  fi

  if ! curl -fsSL https://sh.rustup.rs | sh -s -- -y; then
    log_warn "rustup install script failed"
    return 1
  fi
}

runtime_install_uv() {
  local dry_run="$1"

  if is_command_available uv; then
    log_info "uv already installed"
    return 0
  fi

  log_info "Installing uv via install script"
  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://astral.sh/uv/install.sh | sh"
    return 0
  fi

  if ! curl -fsSL https://astral.sh/uv/install.sh | sh; then
    log_warn "uv install script failed"
    return 1
  fi
}

runtime_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local _verbose="$3"
  local failed=0

  if ! is_command_available mise; then
    if ! runtime_install_mise "$dry_run"; then
      failed=1
    fi
  fi

  if ! is_command_available rustup; then
    if ! runtime_install_rustup "$dry_run"; then
      failed=1
    fi
  fi

  if ! is_command_available uv; then
    if ! runtime_install_uv "$dry_run"; then
      failed=1
    fi
  fi

  return "$failed"
}
