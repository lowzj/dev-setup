#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RERUN=1
DRY_RUN=0
FORCE=0
VERBOSE=0
LABEL="macos-first-run"
LOG_DIR="$ROOT_DIR/.tmp/smoke"
RUN_ID=""

# shellcheck source=lib/detect.sh
source "$ROOT_DIR/lib/detect.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/smoke/macos-first-run.sh [--no-rerun] [--dry-run] [--force] [--verbose] [--label <name>]

Behavior:
  - Requires macOS
  - Uses the current user HOME as-is
  - Fails early if Xcode Command Line Tools are not installed
  - Warns if the current HOME already contains dev-setup-managed config
  - Runs bash syntax checks, doctor, and ./dev-setup apply all
  - By default reruns ./dev-setup apply all to verify repeat execution
  - Writes detailed logs to .tmp/smoke/

Notes:
  - Intended for a disposable macOS VM snapshot with Xcode Command Line Tools
  - Homebrew is bootstrapped automatically when missing
  - For fast iteration on a disposable user home, use scripts/smoke/macos-temp-home.sh
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
    printf '[ERROR] Install them in the VM snapshot first, then rerun this script.\n' >&2
    exit 1
  fi

  if [[ -f "$HOME/.zshrc" || -d "$HOME/.config/nvim" || -f "$HOME/.config/mise/config.toml" ]]; then
    printf '[WARN] Current HOME already contains dev-setup-related config.\n' >&2
    printf '[WARN] This is no longer a clean first-run environment. Use macos-temp-home.sh for iteration.\n' >&2
  fi

  if ! command -v brew >/dev/null 2>&1; then
    printf '[INFO] Homebrew is not installed. dev-setup will bootstrap it during apply.\n'
  fi
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
    bash -n dev-setup lib/*.sh components/*.sh scripts/smoke/*.sh
    ./dev-setup doctor
    ./dev-setup apply all $extra_args
  ) >"$log_file" 2>&1; then
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
  run_logged_phase rerun "$args"
}

main() {
  parse_args "$@"
  ensure_macos
  preflight

  RUN_ID="$(slugify "$LABEL")-$(timestamp)"

  printf '[INFO] HOME: %s\n' "$HOME"
  printf '[INFO] Running initial apply\n'
  run_initial_apply

  if [[ "$RERUN" -eq 1 ]]; then
    printf '[INFO] Running repeat apply\n'
    run_rerun_apply
  fi
}

main "$@"
