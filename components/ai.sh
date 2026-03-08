#!/usr/bin/env bash

ai_phase_install() {
  local failed=0

  if ! is_command_available codex; then
    if ! node_install_global_cli codex "@openai/codex"; then
      failed=1
    fi
  fi

  if ! is_command_available claude; then
    if ! node_install_global_cli claude "@anthropic-ai/claude-code"; then
      failed=1
    fi
  fi

  return "$failed"
}
