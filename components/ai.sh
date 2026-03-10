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

ai_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local verbose="$3"
  local failed=0

  if ! ai_cli_is_available codex; then
    if ! node_install_global_cli "$dry_run" "$verbose" codex "@openai/codex" "/Applications/Codex.app/Contents/Resources/codex"; then
      failed=1
    fi
  fi

  if ! ai_cli_is_available claude; then
    if ! node_install_global_cli "$dry_run" "$verbose" claude "@anthropic-ai/claude-code"; then
      failed=1
    fi
  fi

  return "$failed"
}
