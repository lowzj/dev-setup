#!/usr/bin/env bash

mise_phase_configure() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
  local cfg_dir="$HOME/.config/mise"
  local cfg_file="$cfg_dir/config.toml"
  local content=""

  ensure_dir "$dry_run" "$verbose" "$cfg_dir"

  content="$(cat <<'CFG'
[settings]
idiomatic_version_file_enable_tools = ["python", "node", "go", "rust"]
CFG
)"

  write_file_with_policy "$force" "$dry_run" "$verbose" "$cfg_file" "$content"
}
