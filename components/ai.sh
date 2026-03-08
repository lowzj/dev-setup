#!/usr/bin/env bash

ai_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local verbose="$3"
  local failed=0

  if ! is_command_available codex; then
    if ! node_install_global_cli "$dry_run" "$verbose" codex "@openai/codex"; then
      failed=1
    fi
  fi

  if ! is_command_available claude; then
    if ! node_install_global_cli "$dry_run" "$verbose" claude "@anthropic-ai/claude-code"; then
      failed=1
    fi
  fi

  return "$failed"
}
