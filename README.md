# my-llvm-sandbox

A collection of boostrap scripts to get a working riscv toolchain on a pinned version 
of LLVM. Useful for academic studies / quick projects.

## Getting Started

Setting up your dev environment.

```shell
git submodule update --init --recursive
python3 -m venv my-llvm-sandbox.venv
source my-llvm-sandbox.venv/bin/activate
python3 -m pip install -r requirements.txt
pre-commit install
```

Requirements: GCC and a (relatively recent) python version. We tested this
project on Ubuntu 20.04 and Apple Silicon (for testing weak memory model atomi
performance) with python3.7+.

You will also need `docker` as we rely on docker to build the different compiler
toolchains required for this project in isolation.

## Building

### Building for RISCV (64Bit)

To build this project for riscv64, we use isolated `docker` containers so that
we have better control over the compiler toolchains used. `Ubuntu` kindly packages
the `risv-gnu-toolchain` for us as a debian package. We can rely on the heavy lifting
that the Ubuntu folks have done, by building our `clang` version and linking against
their provided `libstdc++` implementation.

Here are instructions for building with the riscv64 toolchain.

```shell
# Build the `riscv-llvm-sandbox:latest` docker image
./build_tools/docker/docker_build.sh
# Drop into a container as `parch-user` with your uid/gid.
./build_tools/docker/docker_run.sh riscv-llvm-sandbox:latest
# Build and install our forked version of llvm/clang
./build_tools/cmake/build_and_install_clang_riscv64.sh
```

### Building for Apple Silicon (M1)

Since no `docker` containers with blessed toolchains are provided for
`aarch64-darwin` platforms we must build our own. Also `docker` containers are
notoriously slow on MacOS (due to poor sandboxing capabilities provided by the
MacOS kernel). Below are instructions for building/installing our forked clang
on your local Apple Silicon Machine.

```shell
# Build and install our forked version of llvm/clang (at /opt/llvm.aarch64-darwin)
./build_tools/cmake/build_and_install_clang_aarch64_darwin.sh
```

## Testing

To check if your toolchains are working, run the following commands.

Fom inside your riscv64 container.

```shell
cmake -GNinja -S . -B build/
ninja -C build
./build_tools/benchmarks/run_benchmarks_on_riscv64.sh
```
