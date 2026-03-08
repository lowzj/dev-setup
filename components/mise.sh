#!/usr/bin/env bash

mise_phase_configure() {
  local cfg_dir="$HOME/.config/mise"
  local cfg_file="$cfg_dir/config.toml"
  local content=""

  ensure_dir "$cfg_dir"

  content="$(cat <<'CFG'
[settings]
idiomatic_version_file_enable_tools = ["python", "node", "go", "rust"]
CFG
)"

  write_file_with_policy "$cfg_file" "$content"
}
