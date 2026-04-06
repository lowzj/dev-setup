#!/usr/bin/env bash

shell_phase_packages() {
  local _platform="$1"
  local _pkg_manager="$2"

  pkg_spec_print starship starship starship
  pkg_spec_print direnv direnv direnv
  pkg_spec_print zoxide zoxide zoxide
  pkg_spec_print zsh-autosuggestions zsh-autosuggestions /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh,/opt/homebrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh,/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh,/usr/local/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  pkg_spec_print fzf-tab fzf-tab /opt/homebrew/share/fzf-tab/fzf-tab.zsh,/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh,/usr/local/share/fzf-tab/fzf-tab.zsh,/usr/local/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh,/opt/homebrew/share/fzf-tab/fzf-tab.plugin.zsh,/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.plugin.zsh,/usr/local/share/fzf-tab/fzf-tab.plugin.zsh,/usr/local/opt/fzf-tab/share/fzf-tab/fzf-tab.plugin.zsh
  return 0
}

shell_install_starship() {
  local dry_run="$1"
  local verbose="$2"

  if is_command_available starship; then
    log_info "starship already installed"
    return 0
  fi

  log_info "Installing starship via install script"
  if [[ "$dry_run" -eq 1 ]]; then
    log_info "Would run: curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir $HOME/.local/bin"
    return 0
  fi

  ensure_dir "$dry_run" "$verbose" "$HOME/.local/bin" || return 1
  if ! curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin"; then
    log_warn "starship install script failed"
    return 1
  fi
}

shell_phase_install() {
  local _force="$1"
  local dry_run="$2"
  local verbose="$3"
  local failed=0

  if ! is_command_available starship; then
    if ! shell_install_starship "$dry_run" "$verbose"; then
      failed=1
    fi
  fi

  return "$failed"
}

shell_phase_configure() {
  local force="$1"
  local dry_run="$2"
  local verbose="$3"
  local zshrc="$HOME/.zshrc"
  local config_dir="$HOME/.config/dev-setup"
  local starship_config="$config_dir/starship.toml"
  local aliases_template="$ROOT_DIR/templates/shell-aliases.zsh"
  local aliases_config="$config_dir/aliases.zsh"
  local begin="# >>> dev-setup shell >>>"
  local end="# <<< dev-setup shell <<<"
  local block=""
  local starship_content=""
  local aliases_content=""

  starship_content="$(cat <<'STARSHIP'
add_newline = false
format = "$directory$git_branch$character"

[directory]
truncate_to_repo = false

[git_branch]
symbol = "git:"
format = " on [$symbol$branch]($style)"

[character]
success_symbol = "> "
error_symbol = "> "
vimcmd_symbol = "> "
STARSHIP
)"

  if [[ ! -f "$aliases_template" ]]; then
    log_error "Missing shell aliases template: $aliases_template"
    return 1
  fi

  ensure_dir "$dry_run" "$verbose" "$config_dir" || return 1
  write_file_with_policy "$force" "$dry_run" "$verbose" "$starship_config" "$starship_content" || return 1
  aliases_content="$(cat "$aliases_template")"
  write_file_with_policy "$force" "$dry_run" "$verbose" "$aliases_config" "$aliases_content" || return 1

  block="$(cat <<'BLOCK'
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
export PATH="$PNPM_HOME:$HOME/.local/bin:$PATH"

dev_setup_source_first() {
  local candidate=""

  for candidate in "$@"; do
    if [[ -n "$candidate" && -f "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done

  return 1
}

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

for completions_dir in \
  /opt/homebrew/share/zsh/site-functions \
  /usr/local/share/zsh/site-functions \
  /Applications/OrbStack.app/Contents/Resources/completions/zsh
do
  if [[ -d "$completions_dir" ]]; then
    fpath=("$completions_dir" $fpath)
  fi
done
typeset -U fpath

export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/dev-setup/starship.toml}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

autoload -Uz compinit
mkdir -p "$XDG_CACHE_HOME/zsh"
compinit -i -d "$XDG_CACHE_HOME/zsh/.zcompdump"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

if [[ "${TERM:-}" != "dumb" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border
zstyle ':fzf-tab:*' switch-group '<' '>'

dev_setup_source_first \
  "${HOMEBREW_PREFIX:-}/share/fzf-tab/fzf-tab.zsh" \
  "${HOMEBREW_PREFIX:-}/share/fzf-tab/fzf-tab.plugin.zsh" \
  /opt/homebrew/share/fzf-tab/fzf-tab.zsh \
  /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh \
  /opt/homebrew/share/fzf-tab/fzf-tab.plugin.zsh \
  /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.plugin.zsh \
  /usr/local/share/fzf-tab/fzf-tab.zsh \
  /usr/local/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh \
  /usr/local/share/fzf-tab/fzf-tab.plugin.zsh \
  /usr/local/opt/fzf-tab/share/fzf-tab/fzf-tab.plugin.zsh

if ! (( $+functions[_docker] )) && command -v docker >/dev/null 2>&1; then
  source <(docker completion zsh)
fi

if ! (( $+functions[_kubectl] )) && command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi

if [[ -f "$HOME/.config/dev-setup/aliases.zsh" ]]; then
  source "$HOME/.config/dev-setup/aliases.zsh"
fi

HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

dev_setup_source_first \
  "${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /opt/homebrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh

unset -f dev_setup_source_first
BLOCK
)"

  append_managed_block "$force" "$dry_run" "$verbose" "$zshrc" "$begin" "$end" "$block"
}
