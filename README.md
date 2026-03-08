# dev-setup

A component-based development bootstrap CLI for macOS and Linux.

## Install and run

```bash
chmod +x ./dev-setup
./dev-setup help
```

## Commands

```bash
./dev-setup help
./dev-setup doctor
./dev-setup list components
./dev-setup apply all [--force] [--dry-run] [--verbose]
./dev-setup component <core|shell|git|nvim|mise|runtime|node|ai> [--force] [--dry-run] [--verbose]
./dev-setup install packages [--component <name>] [--dry-run] [--verbose]
```

## Components

- `core`: install core CLI tools (`git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fd`, `fzf`, `bat`, `eza`, `curl`).
- `shell`: append a managed block into `~/.zshrc`, install `starship` when needed, and configure guarded init and aliases.
- `git`: apply global git defaults and aliases.
- `nvim`: install LazyVim starter into `~/.config/nvim`.
- `mise`: create `~/.config/mise/config.toml`.
- `runtime`: install language/runtime tools (`go`, `mise`, `rustup`, `uv`) using package-manager installs where available and vendor installers otherwise.
- `node`: install Node runtime tooling and bootstrap `pnpm`.
- `ai`: install AI CLIs (`codex`, `claude`).

## Platform support matrix

| Platform | Package manager | Status |
| --- | --- | --- |
| macOS | Homebrew (`brew`) | Supported |
| Linux (Debian/Ubuntu family) | `apt-get` | Supported |
| Linux (Fedora/RHEL family) | `dnf` | Supported |

## `--force` and `--dry-run`

- `--dry-run`: prints planned actions and does not modify files or run installs.
- `--force`: allows overwrite/replace behavior for components that protect existing config by default.

Default behavior is safe: existing user config is skipped with warnings.

## Templates

- `templates/mise.toml.example`
- `templates/envrc.example`

Copy them into your project as needed:

```bash
cp templates/mise.toml.example /path/to/project/mise.toml
cp templates/envrc.example /path/to/project/.envrc
```

## Smoke Tests

Run real containerized smoke tests and keep the container running for inspection:

```bash
scripts/smoke/ubuntu.sh --name dev-setup-ubuntu-smoke
scripts/smoke/fedora.sh --name dev-setup-fedora-smoke
```

Both commands:
- create a fresh container with this repo mounted at `/workspace`
- run `bash -n`, `./dev-setup doctor`, and `./dev-setup apply all`
- rerun `./dev-setup apply all` to verify repeat execution
- leave the container running
- write full command output to `.tmp/smoke/<container>-{initial,rerun}.log`

## Troubleshooting

- Permissions: if package install needs root, the script uses `sudo` when available.
- Network: package manager indexes and remote install scripts require internet access.
- Missing packages: some tools are installed via vendor scripts or npm/pnpm fallback when distro packages are unavailable (for example `starship`, `mise`, `uv`, `pnpm`).
- Node tooling: on Linux, the `node` component installs `nodejs` first and then bootstraps `pnpm` using Corepack or the official standalone installer.
- PATH issues after script-based install: open a new shell or source your shell config to refresh command lookup.
