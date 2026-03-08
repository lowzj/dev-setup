#!/usr/bin/env bash

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

log_debug() {
  local verbose="$1"
  shift

  if [[ "$verbose" -eq 1 ]]; then
    printf '[DEBUG] %s\n' "$*"
  fi
}

print_cmd() {
  local out=""
  local arg=""
  for arg in "$@"; do
    if [[ -z "$out" ]]; then
      out="$(printf '%q' "$arg")"
    else
      out="$out $(printf '%q' "$arg")"
    fi
  done
  printf '+ %s\n' "$out"
}

run_cmd() {
  local dry_run="$1"
  local verbose="$2"
  shift 2

  if [[ "$dry_run" -eq 1 ]]; then
    print_cmd "$@"
    return 0
  fi

  if [[ "$verbose" -eq 1 ]]; then
    print_cmd "$@"
  fi
  "$@"
}

ensure_dir() {
  local dry_run="$1"
  local verbose="$2"
  local dir="$3"

  if [[ -d "$dir" ]]; then
    return 0
  fi

  run_cmd "$dry_run" "$verbose" mkdir -p "$dir"
}

managed_block_exists() {
  local dir="$1"
  local begin_marker="$2"

  grep -Fq "$begin_marker" "$dir" 2>/dev/null
}

prepend_path_if_missing() {
  local dir="$1"

  if [[ -z "$dir" ]]; then
    return 0
  fi

  case ":$PATH:" in
    *":$dir:"*) ;;
    *)
      export PATH="$dir:$PATH"
      ;;
  esac
}

find_brew_bin() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
    return 0
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' /usr/local/bin/brew
    return 0
  fi

  return 1
}

bootstrap_homebrew_runtime_env() {
  local brew_bin=""
  local brew_prefix=""

  brew_bin="$(find_brew_bin)" || return 1
  brew_prefix="$(cd "$(dirname "$brew_bin")/.." && pwd)"

  prepend_path_if_missing "$brew_prefix/bin"
  prepend_path_if_missing "$brew_prefix/sbin"

  eval "$("$brew_bin" shellenv)"
}

bootstrap_local_tool_paths() {
  if find_brew_bin >/dev/null 2>&1; then
    bootstrap_homebrew_runtime_env || true
  fi

  export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
  prepend_path_if_missing "$PNPM_HOME"
  prepend_path_if_missing "$HOME/.local/bin"
  prepend_path_if_missing "$HOME/.cargo/bin"
}

timestamp() {
  date +%Y%m%d%H%M%S
}

backup_path() {
  local dry_run="$1"
  local verbose="$2"
  local path="$3"

  if [[ ! -e "$path" ]]; then
    return 0
  fi

  local backup="${path}.bak.$(timestamp)"
  log_info "Backing up $path -> $backup"
  run_cmd "$dry_run" "$verbose" mv "$path" "$backup"
}

backup_copy_path() {
  local dry_run="$1"
  local verbose="$2"
  local path="$3"

  if [[ ! -e "$path" ]]; then
    return 0
  fi

  local backup="${path}.bak.$(timestamp)"
  log_info "Backing up $path -> $backup"
  run_cmd "$dry_run" "$verbose" cp "$path" "$backup"
}

remove_managed_block() {
  local file="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local tmp_file="$file.devsetup.tmp"

  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { skip=1; next }
    $0 == end { skip=0; next }
    !skip { print }
  ' "$file" >"$tmp_file"
  mv "$tmp_file" "$file"
}

append_managed_block() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
  local file="$4"
  local begin_marker="$5"
  local end_marker="$6"
  local content="$7"

  if [[ ! -f "$file" ]]; then
    if [[ "$dry_run" -eq 1 ]]; then
      print_cmd touch "$file"
    else
      touch "$file"
    fi
  fi

  if managed_block_exists "$file" "$begin_marker"; then
    if [[ "$force" -ne 1 ]]; then
      log_info "Managed block already exists in $file, skipping"
      return 0
    fi

    if [[ "$dry_run" -eq 1 ]]; then
      log_info "Would replace managed block in $file"
      return 0
    fi

    backup_copy_path "$dry_run" "$verbose" "$file" || return 1
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would append managed block to $file"
    return 0
  fi

  if managed_block_exists "$file" "$begin_marker"; then
    remove_managed_block "$file" "$begin_marker" "$end_marker"
  fi

  {
    printf '\n%s\n' "$begin_marker"
    printf '%s\n' "$content"
    printf '%s\n' "$end_marker"
  } >>"$file"

  log_info "Managed block appended to $file"
}

write_file_with_policy() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
  local file="$4"
  local content="$5"

  if [[ -e "$file" && "$force" -ne 1 ]]; then
    log_warn "$file exists, skipping (use --force to overwrite)"
    return 0
  fi

  if [[ -e "$file" && "$force" -eq 1 ]]; then
    backup_path "$dry_run" "$verbose" "$file"
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would write $file"
    return 0
  fi

  printf '%s\n' "$content" >"$file"
  log_info "Wrote $file"
}

is_command_available() {
  command -v "$1" >/dev/null 2>&1
}
