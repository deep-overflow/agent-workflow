# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Docker + Bash automation project for rapidly setting up Claude Code environments on shared GPU servers. It provides containerized isolation with host UID/GID mapping so multiple users share a server without permission conflicts.

## Key Commands

```bash
# Build Docker image
docker build -t chan docker/

# Launch container (GPU, volume mounts, host network)
bash scripts/docker_run.sh

# Re-enter stopped container
docker start -ai chan

# Deploy statusline + Slack-notification hooks inside container
cp scripts/statusline.sh ~/.claude/statusline.sh
cp scripts/notify-slack.sh ~/.claude/notify-slack.sh
cp scripts/pretool-cache.sh ~/.claude/pretool-cache.sh
chmod +x ~/.claude/*.sh
```

There is no build/lint/test suite — this is a shell + Docker project. Validate changes by
running the scripts directly (e.g. `bash -n scripts/foo.sh` to syntax-check) and by rebuilding
the image. The in-container setup (settings.json merge, hook wiring, env vars) is performed by
pointing Claude Code at `docs/SETTINGS.md`, not by a script.

## Architecture

The workflow is: `docker_run.sh` → `Dockerfile` (CUDA 12.8 + Node.js 22 + Claude Code CLI) → `entrypoint.sh` (UID/GID mapping via gosu) → interactive bash shell.

- **`docker/Dockerfile`** — Image based on `nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04`. Installs Node.js 22, Claude Code CLI (`@anthropic-ai/claude-code`), uv 0.8.12, and system tools.
- **`docker/entrypoint.sh`** — Creates a container user matching the host UID/GID, then drops privileges with `gosu`.
- **`scripts/docker_run.sh`** — Launches the container with `--gpus all`, `--ipc=host`, `--network=host`, and volume mounts for `/workspace`, `.claude`, `.gitconfig`, `.cache`, and data drives.
- **`scripts/statusline.sh`** — Pure bash script for Claude Code custom status line (model, context usage, tokens, git diff, rate limits). Deployed to `~/.claude/statusline.sh`.

### Slack notification hooks

A two-script hook system surfaces Claude Code activity to Slack. Both read hook-event JSON from
stdin and require the `SLACK_WEBHOOK_URL` env var (scripts no-op silently if it is unset).

- **`scripts/pretool-cache.sh`** — wired to the `PreToolUse` hook. Caches the most recent
  tool name + input to `/tmp/claude-last-tool-${SESSION_ID}.json` so the approval notification
  can show *what* is being approved.
- **`scripts/notify-slack.sh`** — wired to both `Stop` (✅ 작업 완료, includes the last assistant
  message) and `Notification` (🔐 승인 요청, reads the cached tool from `pretool-cache.sh`) hooks.
  Builds a Slack Block Kit payload labelled with server (`$USER`), dir, and session title (the
  `customTitle` from the transcript JSONL, falling back to the first 8 chars of the session id).

The exact `settings.json` hook wiring lives in `docs/SETTINGS.md`.

## Volume Mounts

Mounts are defined in `scripts/docker_run.sh`. Note that `.claude`, `.gitconfig` (and, per the
codex plan, `.codex`) are mounted from the **repo dir** `$(pwd)`, while `.cache` and `.npm-global`
come from `$HOME`. The `/mnt/*` data drives are machine-specific and are being generalized out
(see `docs/plans/2026-06-24_codex-and-generalize.md`).

| Host | Container | Purpose |
|---|---|---|
| `$(pwd)` | `/workspace` | Working directory |
| `$(pwd)/.claude` | `~/.claude` | Claude Code auth, settings, memory, hooks |
| `$(pwd)/.gitconfig` | `~/.gitconfig` | Git config |
| `$HOME/.cache` | `~/.cache` | pip/uv cache |
| `$HOME/.npm-global` | `~/.npm-global` | Persists globally-installed CLIs (claude, codex) |
| `/mnt/sda1`, `/mnt/nvme1n1` | same | Machine-specific data drives |

## Docs

- **`docs/DOCKER.md`** — Docker environment setup guide (Korean)
- **`docs/SETTINGS.md`** — Claude Code settings.json + statusline setup instructions
- **`docs/RULES.md`** — Research workflow rules intended for `~/.claude/CLAUDE.md` (global Claude Code config for VLA research workflows, experiment reporting, paper review conventions). Deployed with `cp docs/RULES.md ~/.claude/CLAUDE.md`.
- **`docs/plans/`** — Dated, approved implementation plans (`YYYY-MM-DD_topic.md`). Per `RULES.md`, a plan `.md` is written and approved *before* any non-trivial implementation; this directory is that record.

## Notes

- Python packages: use `uv`, not pip.
- All work happens inside Docker containers — do not modify the host environment.
- If the Docker image needs new packages, update the Dockerfile rather than installing inside the container.
- README and docs are written in Korean.
- For non-trivial changes, write an approved plan in `docs/plans/` first (see `docs/RULES.md`); do not commit unless explicitly asked.
