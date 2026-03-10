# macOS VM Workflow

This repository targets macOS only and cannot create a macOS VM by itself.

Current constraint: macOS validation still requires Xcode Command Line Tools. Homebrew is bootstrapped automatically when missing.

Use this workflow when you want both:

- a clean macOS system boundary
- fast iteration on user-home configuration logic

## Recommended layout

Create two VM snapshots:

1. `clt-ready`
   - fresh macOS install
   - Xcode Command Line Tools installed
   - no user-level dev environment applied yet

2. `devtools`
   - based on `clt-ready`
   - Homebrew already installed
   - `git` available
   - this repository cloned locally

Use `clt-ready` for full bootstrap verification. Use `devtools` for repeated smoke runs.

## First-run validation from `clt-ready`

Boot the `clt-ready` snapshot and run:

```bash
cd /path/to/dev-setup
scripts/smoke/macos-first-run.sh
```

This validates:

- Homebrew path detection
- Homebrew bootstrap when missing
- first package installation
- first-time config creation
- rerun idempotency against the same user home

If `~/.zshrc`, `~/.config/nvim`, or `~/.config/mise/config.toml` already exist, `macos-first-run.sh` warns that the VM is no longer a clean first-run environment.

## High-frequency validation from `devtools`

Boot the `devtools` snapshot and run:

```bash
cd /path/to/dev-setup
scripts/smoke/macos-temp-home.sh
```

That script:

- creates a temporary `HOME`
- runs `./dev-setup doctor`
- runs `./dev-setup apply all`
- reruns `./dev-setup apply all`
- writes logs to `.tmp/smoke/`

This is the fast path for checking:

- `~/.zshrc` managed block behavior
- `~/.config/nvim` handling
- `~/.config/mise/config.toml` handling
- PATH bootstrap behavior
- repeat execution behavior

## Useful variants

Dry-run only:

```bash
scripts/smoke/macos-temp-home.sh --dry-run
```

Keep the temporary home for inspection:

```bash
scripts/smoke/macos-temp-home.sh --keep-home
```

Use a fixed home directory while iterating on rerun behavior:

```bash
scripts/smoke/macos-temp-home.sh --home /tmp/dev-setup-home --keep-home
```

Tag log files for a specific VM snapshot:

```bash
scripts/smoke/macos-temp-home.sh --label devtools-snapshot-a
```

## Log files

Each run writes:

- `.tmp/smoke/<label>-<timestamp>-initial.log`
- `.tmp/smoke/<label>-<timestamp>-rerun.log`

On success, auto-created temp homes are deleted. On failure, they are preserved.

## Practical cadence

Use this sequence:

1. Edit scripts locally
2. Run `scripts/smoke/macos-temp-home.sh --dry-run`
3. Run `scripts/smoke/macos-temp-home.sh`
4. If behavior changes around system bootstrap, revert to the `clt-ready` snapshot and rerun `scripts/smoke/macos-first-run.sh`

That keeps expensive VM resets for system-level changes and uses temp-home runs for fast iteration.
