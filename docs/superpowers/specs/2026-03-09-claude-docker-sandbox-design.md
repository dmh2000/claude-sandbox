# Claude Code Docker Sandbox — Design Spec

**Date:** 2026-03-09

## Overview

A Docker-based sandbox that runs Claude Code in an isolated environment. The host filesystem is protected — Claude can only read/write the single bind-mounted project directory (`/workspace`). The user retains full access to that same directory from the host (e.g., via VS Code).

## Goals

- Claude cannot modify, create, or remove files outside the bind-mounted workspace
- The user can read and edit `/workspace` files from the host normally
- Authentication is handled fresh inside the container each session (subscription or API key)
- The Docker image is pre-built and reusable; not rebuilt on every launch

## Files

```
sandbox/
├── Dockerfile        # reusable image definition
├── run.sh            # launch script
└── .dockerignore     # excludes unnecessary files from build context
```

## Dockerfile

- Base image: `ubuntu:24.04` (current LTS)
- Installs: `curl`, `git`, `ca-certificates`, Node.js 20 LTS (via NodeSource), `@anthropic-ai/claude-code` (global npm install)
- `WORKDIR /workspace`
- No default `CMD` — shell provided at runtime by `run.sh`

## run.sh

- Checks `docker images -q claude-sandbox`; builds image automatically if not found
- Accepts optional `--rebuild` flag to force image rebuild
- Intended to be run from inside the user's project directory — `$PWD` is bind-mounted

Docker run flags:
| Flag | Purpose |
|------|---------|
| `--rm` | Delete container on exit, no leftover state |
| `-it` | Interactive terminal |
| `--read-only` | Container root filesystem is immutable |
| `--tmpfs /tmp` | Writable temp dir for Node.js/tools |
| `--tmpfs /root` | Writable home dir for Claude Code auth/config (ephemeral) |
| `-v "$PWD":/workspace` | Bind-mount current host directory |
| `-w /workspace` | Set working directory inside container |

## .dockerignore

Excludes `run.sh`, `Dockerfile`, `.git`, `prompts/`, and `docs/` from the build context.

## User Workflow

1. `cd /path/to/project`
2. `./path/to/run.sh` — builds image if needed, drops into bash shell at `/workspace`
3. Run `claude` inside the container and authenticate (subscription or API key)
4. Claude Code session runs; auth is lost when container exits
5. Files edited by Claude are visible immediately in VS Code on the host

## Security Properties

- Host filesystem outside `$PWD` is completely inaccessible to the container
- Container root is read-only; Claude cannot persist changes to container internals
- No host credentials or config are passed into the container
- `--rm` ensures no container state persists between sessions
