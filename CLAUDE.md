# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This is a sandbox setup project. The goal is to create a Docker-based environment where Claude Code runs in isolation, with only a single bind-mounted project directory (`/workspace`) visible and writable.

## Project Structure

- `prompts/setup.md` — Requirements spec describing the Docker sandbox setup
- `.claude/settings.local.json` — Claude permissions config (currently restricts to `Bash(ls:*)` only)

## Sandbox Requirements (from prompts/setup.md)

- A bash script that starts Docker with only the current directory bind-mounted as `/workspace` (via `-v "$PWD":/workspace`)
- Base image: Ubuntu Server LTS
- Container must include dependencies needed to run Claude Code inside it
- Claude runs inside the container where the only writable tree is `/workspace`

## Permissions

The `.claude/settings.local.json` restricts Claude's permissions intentionally — only `Bash(ls:*)` is allowed. This is by design for sandboxing purposes.
