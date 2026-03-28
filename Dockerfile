FROM ubuntu:24.04

ARG RUNNER_VERSION=2.333.0
ARG RUNNER_HASH_AMD64=7ce6b3fd8f879797fcc252c2918a23e14a233413dc6e6ab8e0ba8768b5d54475
ARG RUNNER_HASH_ARM64=b5697062a13f63b44f869de9369638a7039677b9e0f87e47a6001a758c0d09bf

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies + .NET runtime requirements for GitHub runner
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    jq \
    git \
    ca-certificates \
    libssl3 \
    libicu74 \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# Install kubectl (arch-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then KUBECTL_ARCH="amd64"; else KUBECTL_ARCH="arm64"; fi && \
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/${KUBECTL_ARCH}/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

# Create non-root runner user
RUN useradd -m runner

WORKDIR /home/runner/actions-runner

# Download and verify official GitHub runner package (arch-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
      RUNNER_ARCH="x64" && RUNNER_HASH="${RUNNER_HASH_AMD64}"; \
    else \
      RUNNER_ARCH="arm64" && RUNNER_HASH="${RUNNER_HASH_ARM64}"; \
    fi && \
    curl -o actions-runner.tar.gz -L \
      https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && echo "${RUNNER_HASH}  actions-runner.tar.gz" | shasum -a 256 -c \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh

COPY runner-entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh \
    && chown -R runner:runner /home/runner

USER runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]
