ARG BUILD_FROM

# https://hub.docker.com/r/grafana/promtail
# https://github.com/grafana/loki/releases
FROM grafana/promtail:2.2.0 as build

# hadolint ignore=DL3006
FROM $BUILD_FROM
ARG BUILD_ARCH=amd64

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
        libsystemd-dev=247.3-1~bpo10+1 \
        ; \
    update-ca-certificates; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

# Add promtail
COPY --from=build /usr/bin/promtail /usr/bin/promtail

# yq is used to merge YAML files
# https://github.com/mikefarah/yq/releases
ENV YQ_VERSION 4.6.1

# Add yq (and its dependency, jq)
RUN set -eux; \
    apt-get install -qy --no-install-recommends \
        jq=1.5+dfsg-2+b1 \
        ; \
    case "$BUILD_ARCH" in \
        amd64)  BINARCH='amd64' ;; \
        armhf)   BINARCH='arm' ;; \
        armv7)   BINARCH='arm' ;; \
        aarch64) BINARCH='arm64' ;; \
        *) echo >&2 "error: unsupported architecture ($BUILD_ARCH)"; exit 1 ;;\
    esac; \
    curl -J -L -o /tmp/yq.tar.gz "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${BINARCH}.tar.gz"; \
    tar -xf /tmp/yq.tar.gz -C /usr/bin; \
    mv /usr/bin/yq_linux_${BINARCH} /usr/bin/yq; \
    chmod a+x /usr/bin/yq; \
    rm -rf /tmp/*;

COPY rootfs /
RUN set -eux; \
    mkdir -p /data/promtail;
WORKDIR /data/promtail