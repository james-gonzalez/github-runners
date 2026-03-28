#!/bin/bash
set -e

REPO_URL="${REPO_URL}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
LABELS="${LABELS:-self-hosted,k8s}"
REGISTRATION_TOKEN="${REGISTRATION_TOKEN}"

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo "ERROR: REGISTRATION_TOKEN environment variable is required" >&2
  exit 1
fi

if [ -z "$REPO_URL" ]; then
  echo "ERROR: REPO_URL environment variable is required" >&2
  exit 1
fi

cd /home/runner/actions-runner

echo "Configuring runner for ${REPO_URL}..."
./config.sh \
  --url "$REPO_URL" \
  --token "$REGISTRATION_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$LABELS" \
  --unattended \
  --replace

# Deregister cleanly on shutdown
cleanup() {
  echo "Deregistering runner..."
  ./config.sh remove --token "$REGISTRATION_TOKEN" || true
}
trap cleanup EXIT INT TERM

echo "Starting runner..."
./run.sh
