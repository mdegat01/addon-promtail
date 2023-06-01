ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:6.2.7
ARG BUILD_ARCH=amd64

# https://github.com/mdegat01/promtail-journal/releases
#FROM ghcr.io/mdegat01/promtail-journal/${BUILD_ARCH}:1.6.0 as build_promtail

# https://github.com/hassio-addons/addon-debian-base/releases
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

ARG BUILD_ARCH=amd64
# https://github.com/mikefarah/yq/releases
ARG YQ_VERSION=4.27.3

# Add yq and tzdata (required for the timestamp stage)
RUN echo "deb http://deb.debian.org/debian bullseye-backports main" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -t bullseye-backports -qy libsystemd-dev
RUN set -eux; \
    apt-get update; \
    apt-get install -qy --no-install-recommends \ 
        tar=1.34+dfsg-1 \
        ; \
    update-ca-certificates; \
    \
    case "${BUILD_ARCH}" in \
        amd64)  BINARCH='amd64' ;; \
        armhf)   BINARCH='arm' ;; \
        armv7)   BINARCH='arm' ;; \
        aarch64) BINARCH='arm64' ;; \
        *) echo >&2 "error: unsupported architecture (${APKARCH})"; exit 1 ;; \
    esac; \
    curl -s -J -L -o /tmp/yq.tar.gz \
        "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${BINARCH}.tar.gz"; \
    tar -xf /tmp/yq.tar.gz -C /usr/bin; \
    mv /usr/bin/yq_linux_${BINARCH} /usr/bin/yq; \
    chmod a+x /usr/bin/yq; \
    rm /tmp/yq.tar.gz; \
    yq --version; \
    \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

# Add promtail
COPY --from=grafana/promtail:latest /usr/bin/promtail /usr/bin/promtail
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
