FROM ubuntu:22.04

# Don't prompt on installs
ENV DEBIAN_FRONTEND noninteractive

# Get GNU toolchain for riscv64 prebuilt by Ubuntu.
RUN apt-get update && apt-get install -y --no-install-recommends \
      binutils-riscv64-linux-gnu \
      g++-riscv64-linux-gnu \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Get LLVM build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
      binutils \
      bzip2 \
      ccache \
      less \
      cmake \
      curl \
      g++-multilib \
      gcc-multilib \
      gdb \
      git \
      gzip \
      libedit-dev \
      libncurses5-dev \
      make \
      ninja-build \
      python-is-python3 \
      python3 \
      python3 \
      python3-dev \
      python3-pip \
      python3-setuptools \
      sed \
      sudo \
      unzip  \
      qemu-user-static \
      zip \
      zlib1g-dev \
      && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Add a user and set them up for passwordless sudo. We're using the same user
# ID and group numbers as the host system. This allows us to give the
# user ownership of files and directories in any mounts we're going to add
# without needing to change ownership which would also affect the host system.
# Note the use of the --no-log-init option for useradd. This is a workaround to
# [a bug](https://github.com/moby/moby/issues/5419) relating to how large UIDs
# are handled.
ARG UID=1000
ARG GID=1000
ARG UNAME=riscv-sandbox-user
RUN groupadd --gid ${GID} ${UNAME} && \
    useradd --create-home --no-log-init --uid ${UID} --gid ${UNAME} \
        ${UNAME} && \
    echo "${UNAME} ALL=(ALL:ALL) NOPASSWD:ALL" | tee -a /etc/sudoers

USER ${UNAME}

WORKDIR /work
