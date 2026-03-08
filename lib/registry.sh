#!/usr/bin/env bash

registry_rows() {
  cat <<'EOF'
core|Install core CLI tools (no dotfile changes)|packages|
shell|Configure zsh managed block, starship, and shell aliases|packages,install,configure|
git|Set global Git defaults and aliases|configure|
nvim|Install LazyVim starter config into ~/.config/nvim|configure|core
mise|Create ~/.config/mise/config.toml and provide project templates|configure|
runtime|Install language/runtime tools (go, mise, rustup, uv)|packages,install|core
node|Install Node runtime and pnpm tooling|packages,install|core
ai|Install AI CLIs (codex, claude)|install|node
EOF
}

registry_components() {
  local name=""

  while IFS='|' read -r name _; do
    printf '%s\n' "$name"
  done < <(registry_rows)
}

registry_component_usage() {
  local output=""
  local name=""

  while IFS='|' read -r name _; do
    if [[ -z "$output" ]]; then
      output="$name"
    else
      output="$output|$name"
    fi
  done < <(registry_rows)

  printf '%s\n' "$output"
}

registry_component_row() {
  local target="$1"
  local row=""
  local name=""

  while IFS= read -r row; do
    IFS='|' read -r name _ <<<"$row"
    if [[ "$name" == "$target" ]]; then
      printf '%s\n' "$row"
      return 0
    fi
  done < <(registry_rows)

  return 1
}

registry_component_exists() {
  registry_component_row "$1" >/dev/null 2>&1
}

registry_component_description() {
  local row=""
  local description=""

  row="$(registry_component_row "$1")" || return 1
  IFS='|' read -r _ description _ _ <<<"$row"
  printf '%s\n' "$description"
}

registry_component_phases_csv() {
  local row=""
  local phases=""

  row="$(registry_component_row "$1")" || return 1
  IFS='|' read -r _ _ phases _ <<<"$row"
  printf '%s\n' "$phases"
}

registry_component_phases() {
  local phases_csv=""

  phases_csv="$(registry_component_phases_csv "$1")" || return 1
  printf '%s\n' "${phases_csv//,/ }"
}

registry_component_has_phase() {
  local component="$1"
  local phase="$2"
  local phases_csv=""

  phases_csv="$(registry_component_phases_csv "$component")" || return 1
  case ",$phases_csv," in
    *",$phase,"*)
      return 0
      ;;
  esac

  return 1
}

registry_component_dependencies_csv() {
  local row=""
  local dependencies=""

  row="$(registry_component_row "$1")" || return 1
  IFS='|' read -r _ _ _ dependencies <<<"$row"
  printf '%s\n' "$dependencies"
}

registry_component_dependencies() {
  local dependencies_csv=""

  dependencies_csv="$(registry_component_dependencies_csv "$1")" || return 1
  printf '%s\n' "${dependencies_csv//,/ }"
}

registry_list_contains() {
  local haystack="$1"
  local needle="$2"

  case "$haystack" in
    *$'\n'"$needle"$'\n'*)
      return 0
      ;;
  esac

  return 1
}

REGISTRY_RESOLVED_COMPONENTS=$'\n'
REGISTRY_VISITING_COMPONENTS=$'\n'

registry_visit_component() {
  local component="$1"
  local dependency=""

  if ! registry_component_exists "$component"; then
    log_error "Unknown component in dependency graph: $component"
    return 1
  fi

  if registry_list_contains "$REGISTRY_RESOLVED_COMPONENTS" "$component"; then
    return 0
  fi

  if registry_list_contains "$REGISTRY_VISITING_COMPONENTS" "$component"; then
    log_error "Circular component dependency detected at: $component"
    return 1
  fi

  REGISTRY_VISITING_COMPONENTS="${REGISTRY_VISITING_COMPONENTS}${component}"$'\n'

  for dependency in $(registry_component_dependencies "$component"); do
    if [[ -z "$dependency" ]]; then
      continue
    fi
    registry_visit_component "$dependency" || return 1
  done

  REGISTRY_VISITING_COMPONENTS="${REGISTRY_VISITING_COMPONENTS//$'\n'"$component"$'\n'/$'\n'}"
  REGISTRY_RESOLVED_COMPONENTS="${REGISTRY_RESOLVED_COMPONENTS}${component}"$'\n'
}

registry_resolve_components_order() {
  local component=""

  REGISTRY_RESOLVED_COMPONENTS=$'\n'
  REGISTRY_VISITING_COMPONENTS=$'\n'

  for component in "$@"; do
    if [[ -z "$component" ]]; then
      continue
    fi
    registry_visit_component "$component" || return 1
  done

  printf '%s' "$REGISTRY_RESOLVED_COMPONENTS" | sed '/^$/d'
}

registry_source_components() {
  local components_dir="$1"
  local component=""
  local file=""

  for component in $(registry_components); do
    file="$components_dir/$component.sh"
    if [[ ! -f "$file" ]]; then
      log_error "Missing component file: $file"
      return 1
    fi

    # shellcheck disable=SC1090
    source "$file"
  done
}

registry_component_package_function() {
  printf '%s\n' "${1}_phase_packages"
}

registry_component_phase_function() {
  printf '%s\n' "${1}_phase_${2}"
}

registry_component_package_specs() {
  local component="$1"
  local fn=""

  if ! registry_component_has_phase "$component" packages; then
    return 0
  fi

  fn="$(registry_component_package_function "$component")"
  if ! declare -F "$fn" >/dev/null 2>&1; then
    log_error "Component $component is missing package phase handler: $fn"
    return 1
  fi

  "$fn"
}

registry_component_package_specs_deduped() {
  local component="$1"
  local specs=""

  specs="$(registry_component_package_specs "$component")" || return 1
  if [[ -z "$specs" ]]; then
    return 0
  fi

  printf '%s\n' "$specs" | pkg_specs_dedup
}

registry_component_run_phase() {
  local component="$1"
  local phase="$2"
  local fn=""
  local package_specs=""

  case "$phase" in
    packages)
      package_specs="$(registry_component_package_specs_deduped "$component")" || return 1
      if [[ -z "$package_specs" ]]; then
        return 0
      fi

      pkg_install_specs_text "$package_specs"
      ;;
    install|configure)
      fn="$(registry_component_phase_function "$component" "$phase")"
      if ! declare -F "$fn" >/dev/null 2>&1; then
        log_error "Component $component is missing phase handler: $fn"
        return 1
      fi
      "$fn"
      ;;
    *)
      log_error "Unknown component phase: $phase"
      return 1
      ;;
  esac
}

registry_component_apply() {
  local component="$1"
  local phase=""

  log_info "Applying component: $component"

  for phase in $(registry_component_phases "$component"); do
    if ! registry_component_run_phase "$component" "$phase"; then
      return 1
    fi
  done
}
