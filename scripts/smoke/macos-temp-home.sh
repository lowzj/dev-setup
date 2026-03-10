#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

TEST_HOME=""
KEEP_HOME=0
RERUN=1
DRY_RUN=0
FORCE=0
VERBOSE=0
LABEL="macos-temp-home"
LOG_DIR="$ROOT_DIR/.tmp/smoke"
RUN_ID=""
HOME_OWNED=0
FAILED=0

# shellcheck source=lib/detect.sh
source "$ROOT_DIR/lib/detect.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/smoke/macos-temp-home.sh [--home <path>] [--keep-home] [--no-rerun] [--dry-run] [--force] [--verbose] [--label <name>]

Behavior:
  - Requires macOS
  - Creates a temporary HOME unless --home is provided
  - Fails early if Xcode Command Line Tools are not installed
  - Runs bash syntax checks, doctor, and ./dev-setup apply all with the temporary HOME
  - By default reruns ./dev-setup apply all against the same HOME to verify repeat execution
  - Writes detailed logs to .tmp/smoke/
  - Deletes the temporary HOME on success; preserves it on failure or when --keep-home is set

Notes:
  - Real runs install packages on the current macOS system
  - Homebrew is bootstrapped automatically when missing
  - Intended for use inside a disposable macOS VM or dedicated test machine
EOF
}

timestamp() {
  date +%Y%m%d%H%M%S
}

slugify() {
  printf '%s\n' "$1" | tr '/:.' '-' | tr -cd '[:alnum:]-'
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --home)
        shift
        TEST_HOME="${1:-}"
        ;;
      --keep-home)
        KEEP_HOME=1
        ;;
      --no-rerun)
        RERUN=0
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --force)
        FORCE=1
        ;;
      --verbose)
        VERBOSE=1
        ;;
      --label)
        shift
        LABEL="${1:-}"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf '[ERROR] Unknown option: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    printf '[ERROR] This smoke test only runs on macOS\n' >&2
    exit 1
  fi
}

preflight() {
  if ! is_xcode_clt_available; then
    printf '[ERROR] Xcode Command Line Tools are required for macOS validation.\n' >&2
    print_xcode_clt_install_help
    printf '[ERROR] Install them before running this smoke test.\n' >&2
    exit 1
  fi

  if ! command -v brew >/dev/null 2>&1; then
    printf '[INFO] Homebrew is not installed. dev-setup will bootstrap it during apply.\n'
  fi
}

prepare_home() {
  if [[ -n "$TEST_HOME" ]]; then
    mkdir -p "$TEST_HOME"
  else
    TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dev-setup-home.XXXXXX")"
    HOME_OWNED=1
  fi

  mkdir -p "$TEST_HOME/.config" "$TEST_HOME/.local/bin"
}

cleanup() {
  if [[ "$HOME_OWNED" -ne 1 ]]; then
    return 0
  fi

  if [[ "$KEEP_HOME" -eq 1 || "$FAILED" -eq 1 ]]; then
    printf '[INFO] Temporary HOME kept: %s\n' "$TEST_HOME"
    return 0
  fi

  rm -rf "$TEST_HOME"
}

apply_args() {
  local args=()

  if [[ "$DRY_RUN" -eq 1 ]]; then
    args+=(--dry-run)
  fi

  if [[ "$FORCE" -eq 1 ]]; then
    args+=(--force)
  fi

  if [[ "$VERBOSE" -eq 1 ]]; then
    args+=(--verbose)
  fi

  if [[ "${#args[@]}" -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${args[*]}"
}

run_logged_phase() {
  local phase="$1"
  local log_file="$LOG_DIR/${RUN_ID}-${phase}.log"
  local extra_args="$2"

  mkdir -p "$LOG_DIR"
  printf '[INFO] Log file: %s\n' "$log_file"

  if ! (
    cd "$ROOT_DIR"
    export HOME="$TEST_HOME"
    export USER="${USER:-$(id -un)}"
    export LOGNAME="${LOGNAME:-$USER}"
    export SHELL="${SHELL:-/bin/zsh}"

    bash -n dev-setup lib/*.sh components/*.sh scripts/smoke/*.sh
    ./dev-setup doctor
    ./dev-setup apply all $extra_args
  ) >"$log_file" 2>&1; then
    FAILED=1
    printf '[ERROR] Phase failed: %s\n' "$phase" >&2
    printf '[ERROR] Tail of %s:\n' "$log_file" >&2
    tail -n 80 "$log_file" >&2 || true
    return 1
  fi

  printf '[INFO] Phase completed: %s\n' "$phase"
}

run_initial_apply() {
  run_logged_phase initial "$(apply_args)"
}

run_rerun_apply() {
  local args

  args="$(apply_args)"

  mkdir -p "$LOG_DIR"
  printf '[INFO] Log file: %s\n' "$LOG_DIR/${RUN_ID}-rerun.log"

  if ! (
    cd "$ROOT_DIR"
    export HOME="$TEST_HOME"
    export USER="${USER:-$(id -un)}"
    export LOGNAME="${LOGNAME:-$USER}"
    export SHELL="${SHELL:-/bin/zsh}"

    ./dev-setup apply all $args
  ) >"$LOG_DIR/${RUN_ID}-rerun.log" 2>&1; then
    FAILED=1
    printf '[ERROR] Phase failed: rerun\n' >&2
    printf '[ERROR] Tail of %s:\n' "$LOG_DIR/${RUN_ID}-rerun.log" >&2
    tail -n 80 "$LOG_DIR/${RUN_ID}-rerun.log" >&2 || true
    return 1
  fi

  printf '[INFO] Phase completed: rerun\n'
}

main() {
  parse_args "$@"
  ensure_macos
  preflight
  prepare_home
  trap cleanup EXIT

  RUN_ID="$(slugify "$LABEL")-$(timestamp)"

  printf '[INFO] Temporary HOME: %s\n' "$TEST_HOME"
  printf '[INFO] Running initial apply\n'
  run_initial_apply

  if [[ "$RERUN" -eq 1 ]]; then
    printf '[INFO] Running repeat apply\n'
    run_rerun_apply
  fi
}

main "$@"
