#!/usr/bin/env bash

zellij_phase_configure() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
  local _platform="$4"
  local _pkg_manager="$5"
  local _has_sudo="$6"
  local config_dir="$HOME/.config/zellij"
  local layouts_dir="$config_dir/layouts"
  local scripts_dir="$config_dir/scripts"
  local layout_template="$ROOT_DIR/templates/zellij-vscode-layout.kdl"
  local launcher_template="$ROOT_DIR/templates/zellij-ai-launcher.zsh"
  local layout_target="$layouts_dir/vscode.kdl"
  local launcher_target="$scripts_dir/dev-setup-ai-launcher.zsh"
  local layout_content=""
  local launcher_content=""

  if [[ ! -f "$layout_template" ]]; then
    log_error "Missing Zellij layout template: $layout_template"
    return 1
  fi

  if [[ ! -f "$launcher_template" ]]; then
    log_error "Missing Zellij launcher template: $launcher_template"
    return 1
  fi

  ensure_dir "$dry_run" "$verbose" "$config_dir" || return 1
  ensure_dir "$dry_run" "$verbose" "$layouts_dir" || return 1
  ensure_dir "$dry_run" "$verbose" "$scripts_dir" || return 1

  launcher_content="$(cat "$launcher_template")"
  write_file_with_policy "$force" "$dry_run" "$verbose" "$launcher_target" "$launcher_content" || return 1
  run_cmd "$dry_run" "$verbose" chmod 755 "$launcher_target" || return 1

  layout_content="$(cat "$layout_template")"
  layout_content="${layout_content//__AI_LAUNCHER__/$launcher_target}"
  write_file_with_policy "$force" "$dry_run" "$verbose" "$layout_target" "$layout_content" || return 1
}
