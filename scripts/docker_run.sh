#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="chan"
IMAGE_NAME="chan"

docker run \
  --name "${CONTAINER_NAME}" \
  -e HOST_USER_ID="$(id -u)" \
  -e HOST_GROUP_ID="$(id -g)" \
  -e HOST_USER_NAME="$(whoami)" \
  -v "$(pwd):/workspace" \
  -v /mnt/sda1:/mnt/sda1 \
  -v /mnt/nvme1n1:/mnt/nvme1n1 \
  -v "$HOME/.cache:/home/$(whoami)/.cache" \
  -v "$(pwd)/.gitconfig:/home/$(whoami)/.gitconfig" \
  -v "$(pwd)/.claude:/home/$(whoami)/.claude" \
  -v "$HOME/.npm-global:/home/$(whoami)/.npm-global" \
  --gpus all \
  --ipc=host \
  --network=host \
  -w /workspace \
  -it \
  "${IMAGE_NAME}"