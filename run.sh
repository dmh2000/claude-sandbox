#!/usr/bin/env bash
set -euo pipefail

# Preflight check
if ! command -v docker &>/dev/null; then
  echo "Error: docker is not installed or not in PATH." >&2
  exit 1
fi

IMAGE_NAME="claude-sandbox"

# Parse flags
REBUILD=false
for arg in "$@"; do
  case "$arg" in
    --rebuild) REBUILD=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# Build image if it doesn't exist or --rebuild was passed
if $REBUILD || [ -z "$(docker images -q "$IMAGE_NAME" 2>/dev/null)" ]; then
  echo "Building image '$IMAGE_NAME'..."
  docker build -t "$IMAGE_NAME" -f - . <<'DOCKERFILE'
FROM ubuntu:24.04

# Prevent interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Default working directory
WORKDIR /workspace
DOCKERFILE
fi

echo "Starting Claude sandbox. Your workspace: $PWD"
echo "Run 'claude' inside the container to start Claude Code."
echo ""

docker run --rm -it \
  --read-only \
  --tmpfs /tmp:exec \
  --tmpfs /root \
  -v "$PWD":/workspace \
  -w /workspace \
  "$IMAGE_NAME" \
  bash
