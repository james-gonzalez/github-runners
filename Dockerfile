FROM ubuntu:24.04

ARG RUNNER_VERSION=2.333.0
ARG RUNNER_HASH=7ce6b3fd8f879797fcc252c2918a23e14a233413dc6e6ab8e0ba8768b5d54475

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    jq \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

# Create non-root runner user
RUN useradd -m runner

WORKDIR /home/runner/actions-runner

# Download and verify official GitHub runner package
RUN curl -o actions-runner.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && echo "${RUNNER_HASH}  actions-runner.tar.gz" | shasum -a 256 -c \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && ./bin/installdependencies.sh

COPY runner-entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh \
    && chown -R runner:runner /home/runner

USER runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]
