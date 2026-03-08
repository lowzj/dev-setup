#!/usr/bin/env bash

git_set_config() {
  local key="$1"
  local value="$2"
  local existing=""

  existing="$(git config --global --get "$key" 2>/dev/null || true)"

  if [[ -n "$existing" && "$existing" != "$value" && "${FORCE:-0}" -ne 1 ]]; then
    log_warn "git config $key already set to '$existing', skipping (use --force to override)"
    return 0
  fi

  if [[ "$existing" == "$value" ]]; then
    log_debug "git config $key already desired value"
    return 0
  fi

  run_cmd git config --global "$key" "$value"
}

git_phase_configure() {
  git_set_config init.defaultBranch main
  git_set_config pull.rebase true
  git_set_config rebase.autostash true
  git_set_config alias.st "status -sb"
  git_set_config alias.co checkout
  git_set_config alias.br branch
  git_set_config alias.lg "log --oneline --graph --decorate --all"
}
