#!/bin/bash
#
# Builds and runs the benchmarks using our different compiler toolchains.

set -xeuo pipefail

REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel)}"
cd "${REPO_DIR}"

LLVM_INSTALL_DIR="${LLVM_INSTALL_DIR:-/opt/llvm.aarch64-darwin}"
CLANG_CC_BIN="${CLANG_CXX_BIN:-$LLVM_INSTALL_DIR/bin/clang}"
CLANG_CXX_BIN="${CLANG_CXX_BIN:-$LLVM_INSTALL_DIR/bin/clang++}"
CLANG_AR_BIN="${CLANG_CXX_BIN:-$LLVM_INSTALL_DIR/bin/llvm-ar}"

# Since we are overriding the stdlib location with our newer version of clang++/libc++,
# the `-nostdlib++` also removes the implicit pointer to the macos sysroot location.
# As a result, we explicitly expose the sysroot location.
export SDKROOT=$(xcodebuild -version -sdk macosx Path)

function run_concurrentqueue() {
  cq_dir=${REPO_DIR}/third_party/concurrentqueue
  cq_build_dir="${cq_dir}/build"
  cq_install_dir="${cq_dir}/install"

  echo ":::: Building `third_party/concurrentqueue`"
  for target_triple in arm64-apple-darwin22.1.0-clang16-ref; do
    mkdir -p $cq_install_dir/$target_triple
    pushd $cq_dir
      rm -rf "${cq_build_dir}/bin/benchmarks"

      declare -a DARWIN_EXTRA_COPTS=(
        # Ingore implicit xcode vendored stdlib
        "-nostdinc++" "-nostdlib++"
        # Include our new clang system headers.
        "-isystem ${LLVM_INSTALL_DIR}/include/c++/v1"
        # Link against our libc++ install instead of the implicit xcode vendored libc++
        "-L ${LLVM_INSTALL_DIR}/lib" "-lc++"
        "-Wl,-rpath,${LLVM_INSTALL_DIR}/lib"
        # Target our host platform.
        "--target=${target_triple}"
      )

      # Useful copts for debugging llvm ir:
      #   EXTRA_COPTS="--target=${target_triple} -mllvm -print-after-all" \
      #   EXTRA_COPTS="--target=${target_triple} -mllvm -print-after=<pass_name>" \
      CC="${CLANG_CC_BIN}" \
      CXX="${CLANG_CXX_BIN}" \
      AR="${CLANG_AR_BIN}" \
      EXTRA_COPTS="${DARWIN_EXTRA_COPTS[@]}" \
        make -C $cq_build_dir benchmarks

      cp -r $cq_build_dir/bin $cq_install_dir/$target_triple
    popd

    echo ":::: Running `third_party/concurrentqueue` benchmarks"
    benchmarks_bin="${cq_install_dir}/$target_triple/bin/benchmarks"
    for bmk in heavy_concurrent spmc mpsc; do
      echo ":::: Benchmark - ${bmk}"
      "${benchmarks_bin}" --run ${bmk}
    done
  done
}

run_concurrentqueue
