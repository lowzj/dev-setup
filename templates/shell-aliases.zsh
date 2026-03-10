# Common shell aliases managed by dev-setup.

_dev_setup_editor_app_name() {
  case "$1" in
    vscode|code)
      printf '%s\n' "Visual Studio Code"
      ;;
    insiders|vscode-insiders|code-insiders)
      printf '%s\n' "Visual Studio Code - Insiders"
      ;;
    cursor)
      printf '%s\n' "Cursor"
      ;;
    windsurf)
      printf '%s\n' "Windsurf"
      ;;
    codium|vscodium)
      printf '%s\n' "VSCodium"
      ;;
    *)
      return 1
      ;;
  esac
}

_dev_setup_editor_bundle_id() {
  local editor="$1"
  local app_name=""
  local bundle_id=""

  app_name="$(_dev_setup_editor_app_name "$editor")" || return 1
  bundle_id="$(osascript -e "id of app \"$app_name\"" 2>/dev/null || true)"
  if [[ -n "$bundle_id" ]]; then
    printf '%s\n' "$bundle_id"
    return 0
  fi

  case "$editor" in
    vscode|code)
      printf '%s\n' "com.microsoft.VSCode"
      ;;
    insiders|vscode-insiders|code-insiders)
      printf '%s\n' "com.microsoft.VSCodeInsiders"
      ;;
    *)
      return 1
      ;;
  esac
}

vimkeys() {
  local editor="${1:-}"
  local mode="${2:-enable}"
  local bundle_id=""
  local target=""

  if [[ -z "$editor" ]]; then
    printf 'usage: vimkeys <vscode|insiders|cursor|windsurf|codium|all|bundle-id> [enable|disable|reset]\n' >&2
    return 1
  fi

  if [[ "$editor" == "all" ]]; then
    local item=""
    for item in vscode insiders cursor windsurf codium; do
      vimkeys "$item" "$mode" || true
    done
    return 0
  fi

  if [[ "$editor" == *.* ]]; then
    bundle_id="$editor"
    target="$editor"
  else
    bundle_id="$(_dev_setup_editor_bundle_id "$editor")" || {
      printf 'Unknown editor or app not found: %s\n' "$editor" >&2
      return 1
    }
    target="$editor"
  fi

  case "$mode" in
    enable|on|repeat|vim)
      defaults write "$bundle_id" ApplePressAndHoldEnabled -bool false
      printf 'Enabled Vim-style key repeat for %s (%s). Restart the app.\n' "$target" "$bundle_id"
      ;;
    disable|off|hold)
      defaults write "$bundle_id" ApplePressAndHoldEnabled -bool true
      printf 'Enabled macOS press-and-hold for %s (%s). Restart the app.\n' "$target" "$bundle_id"
      ;;
    reset|default)
      defaults delete "$bundle_id" ApplePressAndHoldEnabled >/dev/null 2>&1 || true
      printf 'Reset ApplePressAndHoldEnabled for %s (%s). Restart the app.\n' "$target" "$bundle_id"
      ;;
    *)
      printf 'Unknown mode: %s\n' "$mode" >&2
      return 1
      ;;
  esac
}

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=never'
  alias ll='eza -lah --group-directories-first --icons=never'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

if command -v git >/dev/null 2>&1; then
  alias g='git'
  alias gs='git status -sb'
  alias ga='git add'
  alias gaa='git add -A'
  alias gc='git commit'
  alias gcm='git commit -m'
  alias gca='git commit --amend'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gl='git pull --rebase'
  alias gp='git push'
fi

if command -v zellij >/dev/null 2>&1; then
  alias zvs='zellij --layout vscode'
fi
