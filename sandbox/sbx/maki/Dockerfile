FROM docker/sandbox-templates:shell

ARG UV_VERSION=0.7.13

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential pkg-config libcairo2-dev libgirepository1.0-dev \
        curl make jq ripgrep \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://maki.sh/install.sh | env MAKI_INSTALL_DIR=/usr/local/bin sh
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

USER agent
RUN uv python install 3.13
