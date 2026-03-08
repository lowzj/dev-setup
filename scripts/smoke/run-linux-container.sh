#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

IMAGE=""
NAME=""
RECREATE=0
RERUN=1
LOG_DIR="$ROOT_DIR/.tmp/smoke"

usage() {
  cat <<'EOF'
Usage:
  scripts/smoke/run-linux-container.sh --image <image> [--name <container>] [--recreate] [--no-rerun]

Behavior:
  - Creates a persistent Linux container with the repo mounted at /workspace
  - Runs bash syntax checks, doctor, and a real ./dev-setup apply all
  - By default reruns ./dev-setup apply all to verify repeat execution
  - Leaves the container running for inspection
  - Stores detailed logs under .tmp/smoke/
EOF
}

docker_bin() {
  if command -v docker >/dev/null 2>&1; then
    command -v docker
    return 0
  fi

  if [[ -x "$HOME/.orbstack/bin/docker" ]]; then
    printf '%s\n' "$HOME/.orbstack/bin/docker"
    return 0
  fi

  return 1
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
      --image)
        shift
        IMAGE="${1:-}"
        ;;
      --name)
        shift
        NAME="${1:-}"
        ;;
      --recreate)
        RECREATE=1
        ;;
      --no-rerun)
        RERUN=0
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

ensure_container() {
  local docker="$1"

  if [[ -z "$NAME" ]]; then
    NAME="dev-setup-$(slugify "$IMAGE")-$(timestamp)"
  fi

  if "$docker" container inspect "$NAME" >/dev/null 2>&1; then
    if [[ "$RECREATE" -ne 1 ]]; then
      printf '[ERROR] Container already exists: %s\n' "$NAME" >&2
      printf '[ERROR] Use --recreate or choose a different --name.\n' >&2
      exit 1
    fi
    "$docker" rm -f "$NAME" >/dev/null
  fi

  "$docker" run -d \
    --name "$NAME" \
    -v "$ROOT_DIR:/workspace" \
    -w /workspace \
    "$IMAGE" \
    sleep infinity >/dev/null
}

run_logged_phase() {
  local docker="$1"
  local phase="$2"
  local command="$3"
  local log_file="$LOG_DIR/${NAME}-${phase}.log"

  mkdir -p "$LOG_DIR"

  printf '[INFO] Log file: %s\n' "$log_file"

  if ! "$docker" exec "$NAME" bash -lc "$command" >"$log_file" 2>&1; then
    printf '[ERROR] Phase failed: %s\n' "$phase" >&2
    printf '[ERROR] Tail of %s:\n' "$log_file" >&2
    tail -n 80 "$log_file" >&2 || true
    return 1
  fi

  printf '[INFO] Phase completed: %s\n' "$phase"
}

run_initial_apply() {
  local docker="$1"

  run_logged_phase "$docker" initial '
    export DEBIAN_FRONTEND=noninteractive
    cd /workspace
    bash -n dev-setup lib/*.sh components/*.sh
    ./dev-setup doctor
    ./dev-setup apply all
  '
}

run_rerun_apply() {
  local docker="$1"

  run_logged_phase "$docker" rerun '
    cd /workspace
    ./dev-setup apply all
  '
}

main() {
  local docker=""

  parse_args "$@"

  if [[ -z "$IMAGE" ]]; then
    printf '[ERROR] --image is required\n' >&2
    usage >&2
    exit 2
  fi

  docker="$(docker_bin)" || {
    printf '[ERROR] docker not found in PATH and OrbStack docker not detected\n' >&2
    exit 1
  }

  ensure_container "$docker"

  printf '[INFO] Created container: %s\n' "$NAME"
  printf '[INFO] Image: %s\n' "$IMAGE"
  printf '[INFO] Running initial apply\n'
  run_initial_apply "$docker"

  if [[ "$RERUN" -eq 1 ]]; then
    printf '[INFO] Running repeat apply\n'
    run_rerun_apply "$docker"
  fi

  printf '[INFO] Container kept running: %s\n' "$NAME"
  printf '[INFO] Inspect with: %s exec -it %s bash\n' "$docker" "$NAME"
}

main "$@"
