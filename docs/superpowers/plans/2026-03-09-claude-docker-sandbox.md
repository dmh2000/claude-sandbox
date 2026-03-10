# Claude Code Docker Sandbox Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a reusable Docker sandbox that confines Claude Code to a single bind-mounted workspace directory, with a pre-built image and a simple launch script.

**Architecture:** A `Dockerfile` builds a reusable Ubuntu 24.04 image with Node.js 20 and Claude Code CLI installed. A `sandbox.sh` script checks for the image, builds it if missing, then launches an interactive bash container with a read-only root filesystem and only `$PWD` bind-mounted as `/workspace`.

**Tech Stack:** Docker, Ubuntu 24.04, Node.js 20 (NodeSource), `@anthropic-ai/claude-code` (npm)

---

## Chunk 1: Project Files

All files are created in the repo root: `/home/dmh2000/projects/sandbox/`

### Task 1: Create `.dockerignore`

**Files:**
- Create: `.dockerignore` (repo root)

- [ ] **Step 1: Create `.dockerignore`**

```
.git
.dockerignore
Dockerfile
sandbox.sh
docs/
prompts/
CLAUDE.md
```

Note: `.dockerignore` and `CLAUDE.md` are added beyond the spec minimum — both are correct to exclude from the image build context.

- [ ] **Step 2: Verify it exists**

```bash
cat .dockerignore
```
Expected: file contents printed, no error.

- [ ] **Step 3: Commit**

```bash
git init  # if not already a repo
git add .dockerignore
git commit -m "feat: add .dockerignore for sandbox image build"
```

---

### Task 2: Create `Dockerfile`

**Files:**
- Create: `Dockerfile` (repo root)

- [ ] **Step 1: Write the Dockerfile**

```dockerfile
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
```

- [ ] **Step 2: Build the image to verify the Dockerfile is valid**

```bash
docker build -t claude-sandbox .
```
Expected: build completes successfully, ending with a line like `Successfully tagged claude-sandbox:latest`. This may take several minutes on first run.

- [ ] **Step 3: Verify Claude Code is installed in the image**

```bash
docker run --rm claude-sandbox claude --version
```
Expected: prints a version string, e.g. `claude 1.x.x`.

- [ ] **Step 4: Commit**

```bash
git add Dockerfile
git commit -m "feat: add Dockerfile with Ubuntu 24.04, Node.js 20, and Claude Code"
```

---

### Task 3: Create `sandbox.sh`

**Files:**
- Create: `sandbox.sh` (repo root)

- [ ] **Step 1: Write `sandbox.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="claude-sandbox"

# Parse flags
REBUILD=false
for arg in "$@"; do
  case "$arg" in
    --rebuild) REBUILD=true ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# Determine the directory containing this script so we can find the Dockerfile
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build image if it doesn't exist or --rebuild was passed
if $REBUILD || [ -z "$(docker images -q "$IMAGE_NAME" 2>/dev/null)" ]; then
  echo "Building image '$IMAGE_NAME'..."
  docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x sandbox.sh
```

- [ ] **Step 3: Commit**

```bash
git add sandbox.sh
git commit -m "feat: add sandbox.sh sandbox launch script with --rebuild flag"
```

---

## Chunk 2: Verification

### Task 4: Verify sandbox isolation

These are manual verification steps to confirm the sandbox behaves correctly. Run them from the `sandbox/` directory.

- [ ] **Step 1: Launch the sandbox**

```bash
./sandbox.sh
```
Expected: bash shell prompt inside the container, working directory is `/workspace`.

- [ ] **Step 2: Verify `/workspace` is writable**

Inside the container:
```bash
touch /workspace/test-write.txt && echo "writable" || echo "not writable"
```
Expected: `writable`. Then clean up:
```bash
rm /workspace/test-write.txt
```

- [ ] **Step 3: Verify container root is read-only**

Inside the container:
```bash
touch /etc/test-write.txt 2>&1 || true
```
Expected: `touch: cannot touch '/etc/test-write.txt': Read-only file system`

- [ ] **Step 4: Verify `/tmp` is writable**

Inside the container:
```bash
touch /tmp/test && echo "writable" || echo "not writable"
```
Expected: `writable`

- [ ] **Step 5: Verify `/root` (tmpfs) is writable**

Inside the container:
```bash
touch /root/test-auth && echo "writable" || echo "not writable"
rm /root/test-auth
```
Expected: `writable` — confirms the tmpfs mount for Claude Code auth/config is functioning.

- [ ] **Step 6: Verify host filesystem is not accessible**

Inside the container:
```bash
ls /home 2>&1 || true
```
Expected: either empty output or a permissions error — the host's `/home` is not mounted.

- [ ] **Step 7: Verify `claude` binary is available**

Inside the container:
```bash
claude --version
```
Expected: prints the Claude Code version string.

- [ ] **Step 8: Exit the container**

```bash
exit
```
Expected: container exits and is removed (`--rm`). Verify on the host that no lingering container exists:
```bash
docker ps -a | grep claude-sandbox || echo "no container left"
```

- [ ] **Step 9: Verify `--rebuild` flag works**

```bash
./sandbox.sh --rebuild
```
Expected: image rebuild starts (you see `Building image 'claude-sandbox'...`), then drops into bash shell as normal. Exit with `exit`.

---

## Notes

- `--tmpfs /tmp:exec` — the `exec` flag is needed because some Node.js internals execute files from `/tmp`
- `/root` as tmpfs means Claude Code auth (`~/.claude`) is always ephemeral — users must authenticate each session
- The script uses `SCRIPT_DIR` to locate the `Dockerfile` regardless of where the user runs `sandbox.sh` from; `$PWD` (the current directory at invocation time) is always what gets mounted as `/workspace`
- If Claude Code authentication via browser is needed inside the container, the user may need to add `--network host` or expose a port — this is not included by default as it depends on auth method
