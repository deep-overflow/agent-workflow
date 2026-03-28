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

# Deploy statusline inside container
cp scripts/statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
```

## Architecture

The workflow is: `docker_run.sh` → `Dockerfile` (CUDA 12.8 + Node.js 22 + Claude Code CLI) → `entrypoint.sh` (UID/GID mapping via gosu) → interactive bash shell.

- **`docker/Dockerfile`** — Image based on `nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04`. Installs Node.js 22, Claude Code CLI (`@anthropic-ai/claude-code`), uv 0.8.12, and system tools.
- **`docker/entrypoint.sh`** — Creates a container user matching the host UID/GID, then drops privileges with `gosu`.
- **`scripts/docker_run.sh`** — Launches the container with `--gpus all`, `--ipc=host`, `--network=host`, and volume mounts for `/workspace`, `.claude`, `.gitconfig`, `.cache`, and data drives.
- **`scripts/statusline.sh`** — Pure bash script for Claude Code custom status line (model, context usage, tokens, git diff, rate limits). Deployed to `~/.claude/statusline.sh`.

## Volume Mounts

| Host | Container | Purpose |
|---|---|---|
| `$(pwd)` | `/workspace` | Working directory |
| `~/.claude` | `~/.claude` | Claude Code auth, settings, memory |
| `~/.gitconfig` | `~/.gitconfig` | Git config |
| `~/.cache` | `~/.cache` | pip/uv cache |
| `/media/data{1,2,3}` | same | Shared data drives |

## Docs

- **`docs/DOCKER.md`** — Docker environment setup guide (Korean)
- **`docs/SETTINGS.md`** — Claude Code settings.json + statusline setup instructions
- **`docs/RULES.md`** — Research workflow rules intended for `~/.claude/CLAUDE.md` (global Claude Code config for VLA research workflows, experiment reporting, paper review conventions)

## Notes

- Python packages: use `uv`, not pip.
- All work happens inside Docker containers — do not modify the host environment.
- If the Docker image needs new packages, update the Dockerfile rather than installing inside the container.
- README and docs are written in Korean.
