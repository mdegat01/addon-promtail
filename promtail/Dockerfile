# https://github.com/hassio-addons/addon-debian-base/releases
ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:4.1.3

# Grafana builds promtail images for amd64, arm and arm64 with journal support
# Binary can be pulled from them for each arch we support but need a mapping
# Won't just work since they don't tag any with `linux/arm/v6` (i.e. `armhf`)
# amd64 -> amd64, armv7 & armhf -> arm, aarch64 -> arm64
# Note: build.json can't really do this, workflows modified to set this arg
ARG BUILD_IMAGE_ARCH=amd64

# https://github.com/grafana/loki/releases
ARG PROMTAIL_VERSION=2.2.0

# https://hub.docker.com/r/grafana/promtail
FROM grafana/promtail:${PROMTAIL_VERSION}-${BUILD_IMAGE_ARCH} as build

# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# tzdata required for the timestamp stage to work
# Backports repo required to get a libsystemd version 246 or newer which is required to handle journal +ZSTD compression
RUN set -eux; \
    echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -qy --no-install-recommends \ 
        tzdata=2021a-0+deb10u1 \
        ca-certificates=20200601~deb10u2 \
        ; \
    apt-get install -qy --no-install-recommends \
        -t buster-backports \ 
        libsystemd-dev=247.3-3~bpo10+1 \
        ; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

# Add yq
ARG BUILD_ARCH=amd64
COPY bin/yq_linux_${BUILD_ARCH} /usr/bin/yq
RUN yq --version

# Add promtail
COPY --from=build /usr/bin/promtail /usr/bin/promtail
# See https://github.com/grafana/loki/blob/v2.2.0/cmd/promtail/Dockerfile.arm32#L21
RUN [[ ${BUILD_ARCH} =~ armv7|armhf ]] \
    && [ ! -f /lib/ld-linux-armhf.so.3 ] \
    && echo RE-LINKING LD-LINUX-ARMHF.SO.3 \
    && ln -s /lib/ld-linux.so.3 /lib/ld-linux-armhf.so.3
RUN promtail --version

COPY rootfs /
WORKDIR /data/promtail

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="mdegat01" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="mdegat01's Home Assistant Add-ons" \
    org.opencontainers.image.authors="mdegat01" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/mdegat01/hassio-addons" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
