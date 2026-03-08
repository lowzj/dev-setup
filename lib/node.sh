#!/usr/bin/env bash

node_prepare_pnpm_home() {
  local pnpm_home="${PNPM_HOME:-$HOME/.local/share/pnpm}"

  export PNPM_HOME="$pnpm_home"
  ensure_dir "$PNPM_HOME" || return 1

  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *)
      export PATH="$PNPM_HOME:$PATH"
      ;;
  esac
}

node_pnpm_env_file() {
  printf '%s\n' "${PNPM_HOME:-$HOME/.local/share/pnpm}/dev-setup-pnpm-env"
}

node_install_pnpm_standalone() {
  local pnpm_env_file=""

  node_prepare_pnpm_home || return 1
  pnpm_env_file="$(node_pnpm_env_file)"

  log_info "Installing pnpm via standalone script"
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://get.pnpm.io/install.sh | env ENV=$pnpm_env_file SHELL=$(command -v sh) sh -"
    return 0
  fi

  if ! is_command_available node && ! is_command_available nodejs; then
    log_warn "pnpm standalone install requires Node.js"
    return 1
  fi

  if ! curl -fsSL https://get.pnpm.io/install.sh | env ENV="$pnpm_env_file" SHELL="$(command -v sh)" sh -; then
    log_warn "pnpm standalone install failed"
    return 1
  fi

  return 0
}

node_install_pnpm() {
  if is_command_available pnpm; then
    log_info "pnpm already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    if is_command_available corepack; then
      log_info "Would run: corepack enable && corepack prepare pnpm@latest --activate"
    elif is_command_available node || is_command_available nodejs; then
      log_info "Would run: curl -fsSL https://get.pnpm.io/install.sh | env ENV=$(node_pnpm_env_file) SHELL=$(command -v sh) sh -"
    elif is_command_available npm; then
      log_info "Would run: npm install -g pnpm"
    else
      log_info "Would install pnpm via corepack, standalone script, or npm fallback if package install does not provide it"
    fi
    return 0
  fi

  if is_command_available corepack; then
    log_info "Installing pnpm via corepack"
    if run_cmd corepack enable && run_cmd corepack prepare pnpm@latest --activate; then
      return 0
    fi
    log_warn "corepack pnpm activation failed"
  fi

  if is_command_available node || is_command_available nodejs; then
    if node_install_pnpm_standalone; then
      return 0
    fi
  fi

  if is_command_available npm; then
    log_info "Installing pnpm via npm"
    if run_cmd npm install -g pnpm; then
      return 0
    fi
    log_warn "npm pnpm installation failed"
  fi

  log_warn "pnpm install fallback unavailable (missing corepack/node/npm)"
  return 1
}

node_install_global_cli() {
  local cli_name="$1"
  local npm_package="$2"

  if is_command_available "$cli_name"; then
    log_info "$cli_name already installed"
    return 0
  fi

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    if is_command_available pnpm; then
      log_info "Would run: pnpm add -g $npm_package"
    elif is_command_available npm; then
      log_info "Would run: npm install -g $npm_package"
    else
      log_info "Would install $cli_name via pnpm or npm"
    fi
    return 0
  fi

  if is_command_available pnpm; then
    node_prepare_pnpm_home || return 1
    log_info "Installing $cli_name via pnpm"
    if run_cmd pnpm add -g "$npm_package"; then
      return 0
    fi
    log_warn "pnpm installation failed for $cli_name"
  fi

  if is_command_available npm; then
    log_info "Installing $cli_name via npm"
    if run_cmd npm install -g "$npm_package"; then
      return 0
    fi
    log_warn "npm installation failed for $cli_name"
  fi

  log_warn "$cli_name install fallback unavailable (missing pnpm/npm)"
  return 1
}
