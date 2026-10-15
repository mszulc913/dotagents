FROM docker/sandbox-templates:shell

ARG UV_VERSION=0.7.13

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        pkg-config curl make jq ripgrep \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://maki.sh/install.sh | env MAKI_INSTALL_DIR=/usr/local/bin sh
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

USER agent
RUN uv python install 3.13
