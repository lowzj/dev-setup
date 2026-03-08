#!/usr/bin/env bash

registry_rows() {
  cat <<'EOF'
core|Install core CLI tools (no dotfile changes)|packages
shell|Configure zsh managed block, starship, and shell aliases|packages,install,configure
git|Set global Git defaults and aliases|configure
nvim|Install LazyVim starter config into ~/.config/nvim|configure
mise|Create ~/.config/mise/config.toml and provide project templates|configure
runtime|Install language/runtime tools (go, mise, rustup, uv)|packages,install
node|Install Node runtime and pnpm tooling|packages,install
ai|Install AI CLIs (codex, claude)|install
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
  IFS='|' read -r _ description _ <<<"$row"
  printf '%s\n' "$description"
}

registry_component_phases_csv() {
  local row=""
  local phases=""

  row="$(registry_component_row "$1")" || return 1
  IFS='|' read -r _ _ phases <<<"$row"
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

registry_component_run_phase() {
  local component="$1"
  local phase="$2"
  local fn=""
  local package_specs=""

  case "$phase" in
    packages)
      package_specs="$(registry_component_package_specs "$component")" || return 1
      package_specs="$(join_unique_words "$package_specs")"
      if [[ -z "$package_specs" ]]; then
        return 0
      fi

      # shellcheck disable=SC2086
      pkg_install_specs $package_specs
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
