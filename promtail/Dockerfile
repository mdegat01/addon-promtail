ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64
ARG BUILD_ARCH=amd64

# https://github.com/mdegat01/promtail-journal/releases
FROM ghcr.io/mdegat01/promtail-journal/${BUILD_ARCH}:1.0.1 as build_promtail

# https://hub.docker.com/_/alpine
FROM alpine:3.13.5 as build_yq
# https://github.com/mikefarah/yq/releases
ENV YQ_VERSION 4.9.5

RUN set -eux; \
    apk update; \
    apk add --no-cache --virtual .build-deps \
        tar=1.34-r0 \
        curl=7.77.0-r0 \
    ; \
    APKARCH="$(apk --print-arch)"; \
    case "${APKARCH}" in \
        x86_64)  BINARCH='amd64' ;; \
        armhf)   BINARCH='arm' ;; \
        armv7)   BINARCH='arm' ;; \
        aarch64) BINARCH='arm64' ;; \
        *) echo >&2 "error: unsupported architecture (${APKARCH})"; exit 1 ;; \
    esac; \
    curl -J -L -o /tmp/yq.tar.gz \
        "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${BINARCH}.tar.gz"; \
    tar -xf /tmp/yq.tar.gz -C /usr/bin; \
    mv /usr/bin/yq_linux_${BINARCH} /usr/bin/yq; \
    chmod a+x /usr/bin/yq; \
    rm /tmp/yq.tar.gz;

# https://github.com/hassio-addons/addon-debian-base/releases
FROM ${BUILD_FROM}:4.2.1

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
        libsystemd-dev=247.3-5~bpo10+1 \
        ; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

# Add promtail
COPY --from=build_promtail /usr/bin/promtail /usr/bin/promtail
RUN promtail --version

# Add yq
COPY --from=build_yq /usr/bin/yq /usr/bin/yq
RUN yq --version

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
