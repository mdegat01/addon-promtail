# https://github.com/hassio-addons/addon-debian-base/releases
ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:4.1.3

# https://github.com/grafana/loki/releases
FROM golang:1.16.2-buster as build_loki
ENV LOKI_VERSION 2.2.0

# Must build binary from source on system with journal support. Published binaries on release do not include this.
RUN set -eux; \
    echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -qy --no-install-recommends \ 
        -t buster-backports \
        libsystemd-dev=247.3-3~bpo10+1 \
        ; \
    curl -J -L -o /tmp/loki.tar.gz "https://github.com/grafana/loki/archive/refs/tags/v${LOKI_VERSION}.tar.gz"; \
    mkdir -p /src; \
    tar -xf /tmp/loki.tar.gz -C /src; \
    mv "/src/loki-${LOKI_VERSION}" /src/loki;

WORKDIR /src/loki
RUN make BUILD_IN_CONTAINER=false promtail


# hadolint ignore=DL3006
FROM $BUILD_FROM

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


# Add promtail & yq
ARG BUILD_ARCH=amd64
COPY bin/yq_linux_${BUILD_ARCH} /usr/bin/yq
COPY --from=build_loki /src/loki/cmd/promtail/promtail /usr/bin/promtail

RUN set -eux; \
    yq --version; \
    promtail --version;

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
