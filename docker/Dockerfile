# Tiny Data Sync test container
ARG TARGETPLATFORM
FROM --platform=$TARGETPLATFORM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       ca-certificates \
       curl \
       git \
       rsync \
    make \
    && rm -rf /var/lib/apt/lists/*

ARG BATS_VERSION=1.11.0
RUN git clone --depth 1 --branch v${BATS_VERSION} https://github.com/bats-core/bats-core.git /usr/local/src/bats-core \
    && /usr/local/src/bats-core/install.sh /usr/local \
    && rm -rf /usr/local/src/bats-core

WORKDIR /workspace
COPY . /workspace

ENV TD_HOME=/workspace
ENV PATH="/workspace/bin:$PATH"

CMD ["bats", "tests"]
