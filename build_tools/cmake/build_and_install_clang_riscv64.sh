#!/bin/bash
#
# Wrapper script around building cmake. This script should be called once
# for the initial build, remaining builds can be invoked with
#
# ```console`
# cmake --build ./build/llvm-project --target all
# cmake --build ./build/llvm-project --target install

set -xeuo pipefail

REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel)}"
cd "${REPO_DIR}"

# Respect user settings, but default to the locations provided by the project.
LLVM_DIR="${LLVM_ROOT_DIR:-$REPO_DIR/third_party/llvm-project}"
LLVM_SRC_DIR="${LLVM_SRC_DIR:-$LLVM_DIR/llvm}"
LLVM_BUILD_DIR="${LLVM_BUILD_DIR:-$REPO_DIR/build/llvm-project}"
LLVM_INSTALL_DIR="${LLVM_INSTALL_DIR:-/opt/llvm.riscv}"

CMAKE_BIN="${CMAKE_BIN:-$(which cmake)}"

if [[ -d "${LLVM_BUILD_DIR}" ]]; then
  echo "Build directory '${LLVM_BUILD_DIR}' already exists. Will use cached results there."
else
  echo "Build directory '${LLVM_BUILD_DIR}' does not already exist. Creating a new one."
  mkdir -p "${LLVM_BUILD_DIR}"
fi

echo "Important versions"
"${CMAKE_BIN}" --version
ninja --version

declare -a CMAKE_ARGS=(
  "-S" "${LLVM_SRC_DIR}"
  "-B" "${LLVM_BUILD_DIR}"
  "-G" "Ninja"

  ## Generic cmake options
  "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
  "-DCMAKE_INSTALL_PREFIX=${LLVM_INSTALL_DIR}"

  ## LLVM cmake options
  # Build with assertions enabled.
  "-DLLVM_ENABLE_ASSERTIONS=ON"
  # Build clang with support for RISCV codegen.
  "-DLLVM_ENABLE_PROJECTS=${LLVM_ENABLE_PROJECTS:-clang}"
  "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD:-RISCV}"
  # Build as shared library so that upstream gnu toolchain link against our clang version.
  "-DLLVM_BUILD_LLVM_DYLIB=ON"
  "-DLLVM_LINK_LLVM_DYLIB=ON"
  "-DLLVM_ENABLE_UNWIND_TABLES=OFF"
  "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
  # Build with large ccache enabled.
  # Enables build dir discard/rebuilds without paying huge build costs.
  "-DLLVM_CCACHE_BUILD=ON"
  "-DLLVM_CCACHE_MAXSIZE=30G"
  "-DLLVM_CCACHE_DIR=${LLVM_CCACHE_DIR:-/ccache/llvm.riscv}"
)

echo "Configuring cmake"
echo "------------"
"$CMAKE_BIN" "${CMAKE_ARGS[@]}"

echo "Building 'all'"
echo "------------"
"$CMAKE_BIN" --build "${LLVM_BUILD_DIR}"

echo "Building 'install'"
echo "------------------"
sudo "${CMAKE_BIN}" --build "${LLVM_BUILD_DIR}" --target install
