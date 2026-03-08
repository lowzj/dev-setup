#!/usr/bin/env bash

git_set_config() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
  local key="$4"
  local value="$5"
  local existing=""

  existing="$(git config --global --get "$key" 2>/dev/null || true)"

  if [[ -n "$existing" && "$existing" != "$value" && "$force" -ne 1 ]]; then
    log_warn "git config $key already set to '$existing', skipping (use --force to override)"
    return 0
  fi

  if [[ "$existing" == "$value" ]]; then
    log_debug "$verbose" "git config $key already desired value"
    return 0
  fi

  run_cmd "$dry_run" "$verbose" git config --global "$key" "$value"
}

git_phase_configure() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"

  git_set_config "$force" "$dry_run" "$verbose" init.defaultBranch main
  git_set_config "$force" "$dry_run" "$verbose" pull.rebase true
  git_set_config "$force" "$dry_run" "$verbose" rebase.autostash true
  git_set_config "$force" "$dry_run" "$verbose" alias.st "status -sb"
  git_set_config "$force" "$dry_run" "$verbose" alias.co checkout
  git_set_config "$force" "$dry_run" "$verbose" alias.br branch
  git_set_config "$force" "$dry_run" "$verbose" alias.lg "log --oneline --graph --decorate --all"
}
