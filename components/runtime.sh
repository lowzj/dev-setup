#!/usr/bin/env bash

runtime_phase_packages() {
  case "$PKG_MANAGER" in
    brew)
      echo "go|go|go mise|mise|mise uv|uv|uv"
      ;;
    apt)
      echo "go|golang|go"
      ;;
    dnf)
      echo "go|golang|go uv|uv|uv"
      ;;
    *)
      echo ""
      ;;
  esac
}

runtime_install_mise() {
  if is_command_available mise; then
    log_info "mise already installed"
    return 0
  fi

  log_info "Installing mise via install script"
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://mise.run | sh"
    return 0
  fi

  if ! curl -fsSL https://mise.run | sh; then
    log_warn "mise install script failed"
    return 1
  fi
}

runtime_install_rustup() {
  if is_command_available rustup; then
    log_info "rustup already installed"
    return 0
  fi

  log_info "Installing rustup via install script"
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://sh.rustup.rs | sh -s -- -y"
    return 0
  fi

  if ! curl -fsSL https://sh.rustup.rs | sh -s -- -y; then
    log_warn "rustup install script failed"
    return 1
  fi
}

runtime_install_uv() {
  if is_command_available uv; then
    log_info "uv already installed"
    return 0
  fi

  log_info "Installing uv via install script"
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://astral.sh/uv/install.sh | sh"
    return 0
  fi

  if ! curl -fsSL https://astral.sh/uv/install.sh | sh; then
    log_warn "uv install script failed"
    return 1
  fi
}

runtime_phase_install() {
  local failed=0

  if ! is_command_available mise; then
    if ! runtime_install_mise; then
      failed=1
    fi
  fi

  if ! is_command_available rustup; then
    if ! runtime_install_rustup; then
      failed=1
    fi
  fi

  if ! is_command_available uv; then
    if ! runtime_install_uv; then
      failed=1
    fi
  fi

  return "$failed"
}
