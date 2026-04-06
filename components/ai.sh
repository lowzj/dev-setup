#!/usr/bin/env bash

ai_cli_is_available() {
  local cli_name="$1"
  local cli_path=""

  cli_path="$(command -v "$cli_name" 2>/dev/null || true)"
  if [[ -z "$cli_path" ]]; then
    return 1
  fi

  case "$cli_name:$cli_path" in
    codex:/Applications/Codex.app/Contents/Resources/codex)
      return 1
      ;;
  esac

  return 0
}

ai_brew_cask_is_installed() {
  local cask_name="$1"

  brew list --cask "$cask_name" >/dev/null 2>&1
}

ai_cli_looks_like_node_install() {
  local cli_name="$1"
  local npm_package="$2"
  local cli_path=""
  local link_target=""

  cli_path="$(command -v "$cli_name" 2>/dev/null || true)"
  if [[ -z "$cli_path" ]]; then
    return 1
  fi

  link_target="$(readlink "$cli_path" 2>/dev/null || true)"
  case "$cli_path:$link_target" in
    *"/node_modules/$npm_package/"*|*"../lib/node_modules/$npm_package/"*)
      return 0
      ;;
  esac

  return 1
}

ai_remove_legacy_node_cli() {
  local dry_run="$1"
  local verbose="$2"
  local cli_name="$3"
  local npm_package="$4"

  if ! ai_cli_looks_like_node_install "$cli_name" "$npm_package"; then
    return 0
  fi

  if is_command_available npm; then
    log_info "Removing legacy npm install for $cli_name ($npm_package)"
    run_cmd "$dry_run" "$verbose" npm uninstall -g "$npm_package" </dev/null || return 1
    return 0
  fi

  log_error "Found legacy node install for $cli_name but npm is unavailable for cleanup"
  return 1
}

ai_install_brew_cask() {
  local platform="$1"
  local pkg_manager="$2"
  local dry_run="$3"
  local verbose="$4"
  local logical_name="$5"
  local cask_name="$6"

  pkg_ensure_manager_available "$platform" pkg_manager "$dry_run" "$verbose" || return 1

  if [[ "$pkg_manager" != "brew" ]]; then
    log_error "AI CLI install requires Homebrew on macOS"
    return 1
  fi

  log_info "Installing $logical_name via Homebrew cask ($cask_name)"
  run_cmd "$dry_run" "$verbose" brew install --cask "$cask_name" </dev/null
}

ai_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local verbose="$3"
  local platform="$4"
  local pkg_manager="$5"
  local _has_sudo="$6"
  local failed=0

  if ! ai_brew_cask_is_installed codex; then
    if ! ai_remove_legacy_node_cli "$dry_run" "$verbose" codex "@openai/codex"; then
      failed=1
    elif ! ai_install_brew_cask "$platform" "$pkg_manager" "$dry_run" "$verbose" codex codex; then
      failed=1
    fi
  fi

  if ! ai_brew_cask_is_installed claude-code; then
    if ! ai_remove_legacy_node_cli "$dry_run" "$verbose" claude "@anthropic-ai/claude-code"; then
      failed=1
    elif ! ai_install_brew_cask "$platform" "$pkg_manager" "$dry_run" "$verbose" claude claude-code; then
      failed=1
    fi
  fi

  return "$failed"
}
