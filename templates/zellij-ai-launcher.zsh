#!/usr/bin/env zsh
set -euo pipefail

typeset -a ai_labels
typeset -a ai_commands

add_cli() {
  local label="$1"
  local command_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    ai_labels+=("$label")
    ai_commands+=("$command_name")
  fi
}

add_cli "Codex" "codex"
add_cli "Claude" "claude"
add_cli "Aider" "aider"
add_cli "Aichat" "aichat"

if [[ -n "${ZELLIJ_AI_CLI:-}" ]]; then
  if command -v "$ZELLIJ_AI_CLI" >/dev/null 2>&1; then
    exec "$ZELLIJ_AI_CLI"
  fi

  printf 'Requested AI CLI not found: %s\n' "$ZELLIJ_AI_CLI"
fi

if (( ${#ai_commands[@]} == 0 )); then
  printf 'No supported AI CLI found. Starting zsh instead.\n'
  exec zsh -i
fi

if (( ${#ai_commands[@]} == 1 )); then
  exec "${ai_commands[1]}"
fi

printf 'Available AI CLIs:\n'
PS3='Select AI CLI: '
select label in "${ai_labels[@]}" "zsh shell"; do
  if [[ -z "${label:-}" ]]; then
    printf 'Invalid selection.\n'
    continue
  fi

  if [[ "$label" == "zsh shell" ]]; then
    exec zsh -i
  fi

  exec "${ai_commands[$REPLY]}"
done
