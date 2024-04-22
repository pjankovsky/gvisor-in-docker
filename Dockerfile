# amd64
FROM index.docker.io/azul/zulu-openjdk@sha256:4c5778b99d7326decc0859deee88a197819d740e4ab09f00e451400824f83dc3
# arm64
#FROM index.docker.io/azul/zulu-openjdk@sha256:c5621616a42c3e0083961ad6ec99756590854ee9a22a3351c69117101d0fc073

# adapted heavily from:
# - https://github.com/docker-library/docker/blob/e73d98fe46a0a7b99be6ce69cc6406ff5a7d94a0/26/cli/Dockerfile
# - https://github.com/docker-library/docker/blob/e73d98fe46a0a7b99be6ce69cc6406ff5a7d94a0/26/dind/Dockerfile

# install as much as possible early
RUN apt-get update \
    && apt-get install -y \
    wget \
    vim \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    iproute2 \
    tini \
    btrfs-progs \
    e2fsprogs \
    git \
    iptables \
    openssl \
    pigz \
    uidmap \
    xfsprogs \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*
# Excluded zfs-dkms since it is VERY slow to build and we probably won't use zfs

# prepare docker and gvisor repos
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && curl -fsSL https://gvisor.dev/archive.key | gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" | tee /etc/apt/sources.list.d/gvisor.list > /dev/null

# install docker first, then gvisor
RUN apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && apt-get install -y runsc \
    && rm -rf /var/lib/apt/lists/*


ENV DOCKER_TLS_CERTDIR=/certs

# misc configuration
RUN mkdir /certs /certs/client \
    && chmod 1777 /certs /certs/client \
    && mkdir -p /usr/local/sbin/.iptables-legacy \
    && for f in iptables iptables-save iptables-restore ip6tables ip6tables-save ip6tables-restore; do \
        b=$(echo "$f" | sed 's/tables/tables-legacy/'); \
        ln -svT "/sbin/$b" "/usr/local/sbin/.iptables-legacy/${f}"; \
    done \
    && addgroup --system dockremap \
	&& adduser --system --ingroup dockremap dockremap \
	&& echo 'dockremap:165536:65536' >> /etc/subuid \
	&& echo 'dockremap:165536:65536' >> /etc/subgid \
    && cp /usr/bin/tini-static /usr/local/bin/docker-init \
    && echo '{"ip": "127.0.0.1"}' > /etc/docker/daemon.json \
    && runsc install -- -ignore-cgroups

# needed?
# VOLUME /var/lib/docker

COPY start-docker.sh lockdown-networking.sh /

ENTRYPOINT ["/start-docker.sh"]
CMD []