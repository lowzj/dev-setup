# Common shell aliases managed by dev-setup.

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

if command -v zellij >/dev/null 2>&1; then
  alias zvs='zellij --layout vscode'
fi
