# Claude Sandbox Docker Script

This repository provides a `sandbox.sh` script to quickly set up and enter an isolated Docker-based environment for running **Claude Code**.

## Purpose

The `sandbox.sh` script automates the creation and execution of a secure sandbox. It ensures that Claude Code runs in a controlled environment where it only has write access to your current working directory, protecting your host system's root filesystem and other sensitive areas.

## Prerequisites

- **Docker**: Must be installed and available in your system's `PATH`.
- **Bash**: The script is written for the Bash shell.

## Usage

To start the sandbox, run:

```bash
./sandbox.sh
```

### Rebuilding the Image

If you want to force a rebuild of the Docker image (e.g., to update dependencies or the Claude Code CLI), use the `--rebuild` flag:

```bash
./sandbox.sh --rebuild
```

## How It Works

The script performs the following steps:

1.  **Preflight Check**: Verifies that `docker` is installed.
2.  **Image Construction**: 
    - If the `claude-sandbox` image doesn't exist (or `--rebuild` is passed), the script builds it using an internal Dockerfile.
    - **Base Image**: `ubuntu:24.04` (LTS).
    - **Dependencies**: Installs `curl`, `git`, `ca-certificates`, and **Node.js 20 LTS**.
    - **Claude Code**: Installs the `@anthropic-ai/claude-code` CLI globally via `npm`.
3.  **Container Execution**: Launches a new container with the following security-hardened configuration:
    - `--rm`: Automatically removes the container when you exit the shell.
    - `-it`: Runs in interactive mode with a TTY.
    - `--read-only`: Mounts the container's root filesystem as read-only.
    - `--tmpfs /tmp:exec`: Provides a writable, in-memory `/tmp` directory with execution permissions.
    - `--tmpfs /root`: Provides a writable, in-memory `/root` directory for configuration files.
    - `-v "$PWD":/workspace`: Mounts your current host directory to `/workspace` inside the container.
    - `-w /workspace`: Sets the initial working directory to `/workspace`.

## Security Features

- **Isolation**: Claude Code only sees the files in the directory where you launched `sandbox.sh`.
- **Read-Only Root**: Prevents any modifications to the underlying container system files.
- **Ephemeral State**: Changes made outside of `/workspace` (in `/tmp` or `/root`) are stored in RAM and discarded immediately when the container exits.

## Running Claude

Once the script starts, you will be dropped into a Bash shell inside the container. To start Claude Code, simply run:

```bash
claude
```
