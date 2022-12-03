#!/bin/bash
#
# Builds and runs the benchmarks using our different compiler toolchains.

set -xeuo pipefail

REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel)}"
cd "${REPO_DIR}"

LLVM_INSTALL_DIR="${LLVM_INSTALL_DIR:-/opt/llvm.riscv}"
CLANG_CC_BIN="${CLANG_CXX_BIN:-$LLVM_INSTALL_DIR/bin/clang}"
CLANG_CXX_BIN="${CLANG_CXX_BIN:-$LLVM_INSTALL_DIR/bin/clang++}"
CLANG_AR_BIN="${CLANG_CXX_BIN:-$LLVM_INSTALL_DIR/bin/llvm-ar}"

# WORKAROUND: Point `qemu-user-static` to the right crosstools.
export QEMU_LD_PREFIX=/usr/riscv64-linux-gnu

function run_concurrentqueue() {
  cq_dir=${REPO_DIR}/third_party/concurrentqueue
  cq_build_dir="${cq_dir}/build"
  cq_install_dir="${cq_dir}/install"

  echo ":::: Building `third_party/concurrentqueue`"
  for target_triple in riscv64-unknown-linux-gnu; do
    mkdir -p $cq_install_dir/$target_triple
    pushd $cq_dir
      rm -rf "${cq_build_dir}/bin/benchmarks"

      # Useful copts for debugging llvm ir:
      #   EXTRA_COPTS="--target=${target_triple} -mllvm -print-after-all" \
      #   EXTRA_COPTS="--target=${target_triple} -mllvm -print-after=<pass_name>" \
      declare -a RISCV_EXTRA_COPTS=(
        "--target=${target_triple}"
        # We have to link the atomics support explicitly for gnu libstdc++
        "-latomic"
      )
      CC="${CLANG_CC_BIN}" \
      CXX="${CLANG_CXX_BIN}" \
      AR="${CLANG_AR_BIN}" \
      EXTRA_COPTS="${RISCV_EXTRA_COPTS[@]}" \
        make -C $cq_build_dir benchmarks

      cp -r $cq_build_dir/bin $cq_install_dir/$target_triple
    popd

    echo ":::: Running `third_party/concurrentqueue` benchmarks"
    benchmarks_bin="${cq_install_dir}/$target_triple/bin/benchmarks"
    # for bmk in balanced heavy_concurrent; do
    for bmk in heavy_concurrent spmc mpsc; do
      echo ":::: Benchmark - ${bmk}"
      "${benchmarks_bin}" --run ${bmk}
    done
  done
}

run_concurrentqueue
