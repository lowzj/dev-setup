# dev-setup

A component-based development bootstrap CLI for macOS.

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

`./dev-setup doctor` reports package-manager readiness and, on macOS, whether Xcode Command Line Tools are installed and whether Homebrew bootstrap can run.
`./dev-setup component <name>` and `./dev-setup install packages --component <name>` automatically include declared component dependencies.

## Components

- `core`: install core CLI tools (`git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fd`, `fzf`, `bat`, `eza`, `zellij`, `curl`, `gh`, `jq`).
- `shell`: append a managed block into `~/.zshrc`, install `starship` when needed, and configure ASCII-friendly prompt and aliases.
- `git`: apply global git defaults and aliases.
- `nvim`: install LazyVim starter into `~/.config/nvim` with static gutter defaults.
- `mise`: create `~/.config/mise/config.toml`.
- `runtime`: install language/runtime tools (`go`, `mise`, `rustup`, `uv`) using package-manager installs where available and vendor installers otherwise.
- `node`: install Node runtime tooling and bootstrap `pnpm`.
- `ai`: install AI CLIs (`codex`, `claude`).

## Platform support matrix

| Platform | Package manager | Status |
| --- | --- | --- |
| macOS | Homebrew (`brew`) | Supported |

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

Run the macOS temp-home smoke test on the host or inside a macOS VM:

```bash
scripts/smoke/macos-temp-home.sh --dry-run
scripts/smoke/macos-temp-home.sh
```

The macOS smoke test:
- requires macOS
- requires Xcode Command Line Tools
- creates a temporary `HOME`
- runs `./dev-setup doctor` and `./dev-setup apply all`
- reruns `./dev-setup apply all` against the same temporary `HOME`
- writes logs to `.tmp/smoke/`
- removes the temp `HOME` on success and keeps it on failure

Real macOS runs install packages on the current system. If Homebrew is missing, `dev-setup` bootstraps it automatically. Use a disposable macOS VM or dedicated test machine for non-dry-run execution.

If Xcode Command Line Tools are missing, install them first:

```bash
xcode-select --install
```

For first-run validation in a macOS VM snapshot that has Xcode Command Line Tools:

```bash
scripts/smoke/macos-first-run.sh
```

That script:
- requires macOS
- requires Xcode Command Line Tools
- uses the current `HOME`
- bootstraps `brew` automatically when missing
- warns if the current `HOME` already contains dev-setup-managed config
- runs `./dev-setup doctor`, `./dev-setup apply all`, and a repeat `./dev-setup apply all`
- writes logs to `.tmp/smoke/`

For the combined `macOS VM + temp HOME` workflow, see [docs/macos-vm-workflow.md](docs/macos-vm-workflow.md).

## Troubleshooting

- Platform support: this repository supports macOS only.
- Permissions: Homebrew bootstrap may prompt for administrator privileges depending on the target prefix and machine state.
- Network: package manager indexes and remote install scripts require internet access.
- Missing packages: some tools are installed via vendor scripts or npm/pnpm fallback when Homebrew is not the final install path (for example `starship`, `mise`, `uv`, `pnpm`).
- Node tooling: the `node` component installs `node` first and then bootstraps `pnpm` using Corepack or the official standalone installer.
- PATH issues after script-based install: open a new shell or source your shell config to refresh command lookup.
