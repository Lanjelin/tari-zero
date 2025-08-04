ARG TARI_TAG=4.9.0

# === Stage 1: Download, verify and extract ===
FROM debian:bookworm-slim AS builder

ARG TARI_TAG
ARG tari_url="https://github.com/tari-project/tari/releases/download/$TARI_TAG/"


RUN apt update && apt-get install -y \
      unzip wget ca-certificates binutils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN tari_zip="tari_suite-${TARI_TAG#v}-d9b1c0d-linux-x86_64.zip" && \
    wget "$tari_url$tari_zip" && \
    wget "$tari_url$tari_zip.sha256" && \
    sha256sum "$tari_zip.sha256" --check || { echo "Hash mismatch!"; exit 1; } && \
    unzip "$tari_zip"

COPY extract-deps.sh /build/extract-deps.sh
RUN chmod +x extract-deps.sh && \
    /build/extract-deps.sh /build/minotari_console_wallet /out && \
    /build/extract-deps.sh /build/minotari_merge_mining_proxy /out && \
    /build/extract-deps.sh /build/minotari_miner /out && \
    /build/extract-deps.sh /build/minotari_node /out && \
    /build/extract-deps.sh /build/minotari_node-metrics /out

# Adding a few symlinks
WORKDIR /out/bin
RUN ln -s minotari_console_wallet wallet && \
    ln -s minotari_merge_mining_proxy merge_mining_proxy && \
    ln -s minotari_miner miner && \
    ln -s minotari_node node && \
    ln -s minotari_node node-metrics

# === Stage 2: Build an entrypoint ===
FROM alpine AS builder-entry

RUN apk add --no-cache make gcc g++ musl-dev binutils autoconf automake libtool pkgconfig check-dev file patch

WORKDIR /src

COPY entrypoint.c .

RUN gcc -Os -static -o entrypoint entrypoint.c

# === Stage 3: Minimal runtime ===
FROM scratch
ARG TARI_TAG

COPY --from=builder /build/libminotari_mining_helper_ffi.so /bin/libminotari_mining_helper_ffi.so

COPY --from=builder /out/bin /bin
COPY --from=builder /out/lib /lib
COPY --from=builder /out/usr /usr
COPY --from=builder /out/lib64 /lib64

COPY --from=builder-entry /src/entrypoint /entrypoint

LABEL org.opencontainers.image.title="tari-zero" \
      org.opencontainers.image.description="A rootless, distroless, from-scratch Docker image for running the tools from tari suite." \
      org.opencontainers.image.url="https://ghcr.io/lanjelin/tari-zero" \
      org.opencontainers.image.source="https://github.com/Lanjelin/tari-zero" \
      org.opencontainers.image.documentation="https://github.com/Lanjelin/tari-zero" \
      org.opencontainers.image.version="$TARI_TAG" \
      org.opencontainers.image.authors="Lanjelin" \
      org.opencontainers.image.licenses="GPL-3"

USER 1000:1000
ENTRYPOINT ["/entrypoint"]
