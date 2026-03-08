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
  if [[ "${VERBOSE:-0}" -eq 1 ]]; then
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
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    print_cmd "$@"
    return 0
  fi

  if [[ "${VERBOSE:-0}" -eq 1 ]]; then
    print_cmd "$@"
  fi
  "$@"
}

ensure_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    return 0
  fi
  run_cmd mkdir -p "$dir"
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

bootstrap_local_tool_paths() {
  export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
  prepend_path_if_missing "$PNPM_HOME"
  prepend_path_if_missing "$HOME/.local/bin"
  prepend_path_if_missing "$HOME/.cargo/bin"
}

timestamp() {
  date +%Y%m%d%H%M%S
}

backup_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 0
  fi

  local backup="${path}.bak.$(timestamp)"
  log_info "Backing up $path -> $backup"
  run_cmd mv "$path" "$backup"
}

append_managed_block() {
  local file="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local content="$4"

  if [[ ! -f "$file" ]]; then
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
      print_cmd touch "$file"
    else
      touch "$file"
    fi
  fi

  if grep -Fq "$begin_marker" "$file" 2>/dev/null; then
    log_info "Managed block already exists in $file, skipping"
    return 0
  fi

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would append managed block to $file"
    return 0
  fi

  {
    printf '\n%s\n' "$begin_marker"
    printf '%s\n' "$content"
    printf '%s\n' "$end_marker"
  } >>"$file"

  log_info "Managed block appended to $file"
}

write_file_with_policy() {
  local file="$1"
  local content="$2"

  if [[ -e "$file" && "${FORCE:-0}" -ne 1 ]]; then
    log_warn "$file exists, skipping (use --force to overwrite)"
    return 0
  fi

  if [[ -e "$file" && "${FORCE:-0}" -eq 1 ]]; then
    backup_path "$file"
  fi

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    log_info "Would write $file"
    return 0
  fi

  printf '%s\n' "$content" >"$file"
  log_info "Wrote $file"
}

is_command_available() {
  command -v "$1" >/dev/null 2>&1
}

join_unique_words() {
  local words="$*"
  local uniq=""
  local word=""

  for word in $words; do
    if [[ -z "$word" ]]; then
      continue
    fi
    case " $uniq " in
      *" $word "*) ;;
      *) uniq="$uniq $word" ;;
    esac
  done

  printf '%s\n' "${uniq# }"
}
