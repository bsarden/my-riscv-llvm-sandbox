#!/bin/bash
#
# Wrapper around `docker run` command to match `Flow` expectations.

set -euo pipefail

# It's convenient to have the paths inside the container match the paths
# outside. This creates an issue, however, because we pass around CMake build
# directories, which use absolute paths, so it's important that the paths match
# between runners. Doing things this way allows runners to change their working
# directory and enables local reproduction of issues.
DOCKER_HOST_WORKDIR="${DOCKER_HOST_WORKDIR:-$(pwd)}"
DOCKER_CONTAINER_WORKDIR="${DOCKER_CONTAINER_WORKDIR:-/work}"

# Setup a volume for ccache contents, so we don't lose build context on
# container restarts.
DOCKER_CCACHE_DIR="${DOCKER_CCACHE_DIR:-/scratch/docker-ccache}"

# Sets up files and environment to enable running scripts in docker.
# In particular, does some shenanigans to enable running with the current user.
# Requires that DOCKER_HOST_WORKDIR and DOCKER_HOST_TMPDIR have been set
function docker_run() {
  DOCKER_RUN_ARGS=(
    --mount="type=bind,source=${DOCKER_HOST_WORKDIR},dst=${DOCKER_CONTAINER_WORKDIR}"
    --workdir="${DOCKER_CONTAINER_WORKDIR}"
  )

  # Add any runtime data dependencies from the main host
  DOCKER_RUN_ARGS+=(
    --mount="type=bind,source=${DOCKER_CCACHE_DIR},dst=/ccache"
  )

  # Delete the container after the run is complete.
  DOCKER_RUN_ARGS+=(--rm)

  # Run as the current user and group (so that perms of outfiles match the user).
  DOCKER_RUN_ARGS+=(--user="$(id -u):$(id -g)")

  # For debugging
  DOCKER_RUN_ARGS+=(-it)
  DOCKER_RUN_ARGS+=(--entrypoint "/bin/bash")

  # DREAM: Give the container a RAM disk for the current working directory.
  # DOCKER_RUN_ARGS+=(
  #   --mount="type=tmpfs,dest=/dev/shm"
  #   --env SANDBOX_BASE=/dev/shm
  # )
  docker run "${DOCKER_RUN_ARGS[@]?}" "$@"
}

if [[ -d "${DOCKER_CCACHE_DIR}" ]]; then
  echo "Reusing ccache directory '${DOCKER_CCACHE_DIR}' for caching build artifacts."
else
  echo "Compilation artifact cache directory '${DOCKER_CCACHE_DIR}' does not already exist. Creating a new one."
  mkdir -p "${DOCKER_CCACHE_DIR}"
fi

docker_run "$@"
