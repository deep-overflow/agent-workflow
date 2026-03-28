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
  -v /media/data1:/media/data1 \
  -v /media/data2:/media/data2 \
  -v /media/data3:/media/data3 \
  -v "$HOME/.cache:/home/$(whoami)/.cache" \
  -v "$(pwd)/.gitconfig_docker:/home/$(whoami)/.gitconfig:ro" \
  --gpus all \
  --ipc=host \
  --network=host \
  -v /etc/localtime:/etc/localtime:ro \
  -w /workspace \
  -it \
  "${IMAGE_NAME}"
