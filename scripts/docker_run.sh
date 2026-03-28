#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="claude-$(whoami)"
IMAGE_NAME="claude-agent"

docker run \
  --name "${CONTAINER_NAME}" \
  --hostname "${CONTAINER_NAME}" \
  -e HOST_USER_ID="$(id -u)" \
  -e HOST_GROUP_ID="$(id -g)" \
  -e HOST_USER_NAME="$(whoami)" \
  -v "$HOME/.claude:/home/$(whoami)/.claude" \
  -v "$HOME/.ssh:/home/$(whoami)/.ssh:ro" \
  -v "$HOME/.gitconfig:/home/$(whoami)/.gitconfig:ro" \
  -v "$HOME/.cache:/home/$(whoami)/.cache" \
  -v "$(pwd):/workspace" \
  --gpus all \
  --ipc=host \
  -w /workspace \
  -it \
  "${IMAGE_NAME}"
