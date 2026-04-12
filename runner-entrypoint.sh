#!/bin/bash
set -e

REPO_URL="${REPO_URL}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
LABELS="${LABELS:-self-hosted,k8s}"
GITHUB_PAT="${GITHUB_PAT}"

if [ -z "$GITHUB_PAT" ]; then
  echo "ERROR: GITHUB_PAT environment variable is required" >&2
  exit 1
fi

if [ -z "$REPO_URL" ]; then
  echo "ERROR: REPO_URL environment variable is required" >&2
  exit 1
fi

# Extract owner/repo from REPO_URL (handles https://github.com/owner/repo)
REPO_PATH=$(echo "$REPO_URL" | sed 's|https://github.com/||')

echo "Fetching fresh registration token for ${REPO_PATH}..."
REGISTRATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO_PATH}/actions/runners/registration-token" \
  | jq -r .token)

if [ -z "$REGISTRATION_TOKEN" ] || [ "$REGISTRATION_TOKEN" = "null" ]; then
  echo "ERROR: Failed to fetch registration token — check GITHUB_PAT permissions (repo scope required)" >&2
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

# Fetch a fresh removal token and deregister cleanly on shutdown
cleanup() {
  echo "Fetching removal token and deregistering runner..."
  REMOVAL_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO_PATH}/actions/runners/remove-token" \
    | jq -r .token)
  ./config.sh remove --token "$REMOVAL_TOKEN" || true
}
trap cleanup EXIT INT TERM

echo "Starting runner..."
./run.sh
