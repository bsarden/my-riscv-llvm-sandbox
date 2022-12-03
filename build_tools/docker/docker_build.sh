#!/bin/bash
#
# Script to build our experiment container

set -xeuo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
cd "${REPO_ROOT}"

DOCKER_BIN="${DOCKER_BIN:-$(which docker)}"
DOCKERFILE_DIR="${DOCKERFILE_DIR:-$REPO_ROOT/build_tools/docker/dockerfiles}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-$DOCKERFILE_DIR/riscv.Dockerfile}"
# Respect user setting, but default to lightweight `docker` directory.
DOCKER_CONTEXT_DIR="${DOCKER_CONTEXT_DIR:-$REPO_ROOT/build_tools/docker}"

IMAGE_NAME="${IMAGE_NAME:-riscv-llvm-sandbox}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
IMAGE_SLUG="${IMAGE_NAME}:${IMAGE_TAG}"

# Print versions
"${DOCKER_BIN}" --version

echo "Building Dockerfile: ${DOCKERFILE_PATH}"
"${DOCKER_BIN}" \
  build -f "${DOCKERFILE_PATH}" \
  --build-arg UID=$(id -u) \
  --build-arg GID=$(id -g) \
  -t "${IMAGE_SLUG}" \
  "${DOCKER_CONTEXT_DIR}" "$@"
