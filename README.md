# my-claude-knowledge-hub

> Claude Code configuration hub: Skills, Agents, Commands, Hooks and Output Styles for session-continuous AI-assisted development.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## What is this?

A curated collection of **Claude Code** extensions that turn the CLI into a full session-continuous development environment. Everything lives in `~/.claude/` and is version-controlled here.

### At a glance

| Component | Count | Examples |
|-----------|-------|----------|
| **Skills** | 20 | session-refresh, vault-manager, task-orchestrator, prompt-improver |
| **Agents** | 1 | my-setup-guide |
| **Commands** | 6 | obsidian-sync, vault-export, run-next-tasks |
| **Hooks** | 4 | notify, session-handoff-loader |
| **Output Styles** | 1 | Executive communication mode |
| **Plugins** | 14 | code-review, commit-commands, hookify, pr-review-toolkit |

---

## Features

- **Session-Continuous Workflow** — Automatic handoffs, token budget awareness, and documentation refresh between sessions
- **Task Orchestration** — UUID-based task tracking with dependency resolution, sub-agent delegation, and checkpoint commits
- **Vault Integration** — Bidirectional Obsidian Vault access (read, search, export) via CLI
- **Prompt Engineering** — Prompt analysis and improvement following Anthropic best practices
- **Project Initialization** — One-command project scaffolding with CLAUDE.md, PROJEKT.md, and task infrastructure
- **Multi-Platform** — Windows (Git Bash) and macOS compatible with OS-detection patterns

---

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (latest version)
- Bash >= 4.0 (macOS: `brew install bash`)
- Git >= 2.30
- Optional: [Obsidian](https://obsidian.md/) (for vault-manager and vault-export)
- Optional: [1Password CLI](https://developer.1password.com/docs/cli/) (for SSH key management)

---

## Installation

```bash
# Clone into ~/.claude/
git clone https://github.com/jopre0502/my-claude-knowledge-hub.git ~/.claude/

# Claude Code automatically discovers skills, commands, agents, and hooks
# from ~/.claude/ — no additional configuration needed.
```

> **Note:** If you already have a `~/.claude/` directory, back it up first. This repo replaces the entire directory.

---

## Directory Structure

```text
~/.claude/
├── CLAUDE.md              # Global instructions for Claude Code
├── skills/                # 18 skills (session-refresh, task-orchestrator, ...)
│   └── <skill-name>/
│       └── SKILL.md       # Skill definition + supporting files
├── agents/                # 2 autonomous agents
│   └── <agent-name>.md
├── commands/              # 6 slash commands
│   └── <command-name>.md
├── hooks/                 # 5 event-driven hooks
│   └── <hook-name>.sh
├── output-styles/         # 1 output style (executive)
│   └── executive.md
├── projects/              # Per-project memory and configuration
├── plugins/               # 10 installed plugins (managed by Claude Code)
└── settings.json          # Permissions and auto-approval rules
```

---

## Key Skills

| Skill | Description |
|-------|-------------|
| `session-refresh` | Updates CLAUDE.md + PROJEKT.md, triggers restructuring when needed |
| `task-orchestrator` | Orchestrates task execution with sub-agent delegation and checkpoints |
| `task-scheduler` | Resolves task dependencies, identifies ready tasks |
| `vault-manager` | Read-only Obsidian Vault access via `vault:` prefix notation |
| `project-init` | Scaffolds session-continuous project infrastructure |
| `prompt-improver` | Analyzes and improves prompts for Claude 4.x models |
| `skill-creator` | Guided skill creation with validation |
| `prioritize-tasks` | Scores and ranks tasks by dependencies, effort, and blockers |

---

## Key Commands

| Command | Description |
|---------|-------------|
| `/run-next-tasks` | Identify and start ready tasks from PROJEKT.md |
| `/obsidian-sync` | Push Obsidian Vault to GitHub |
| `/knowledge-hub-sync` | Commit and push this repo to GitHub |
| `/vault-export` | Export content to Obsidian Vault with templates |
| `/vault-work` | Load, edit, and save Vault documents |
| `/refresh-reference` | Generate system inventory from live `~/.claude/` |

---

## Configuration

Claude Code uses `~/.claude/settings.json` for permissions and auto-approval rules. Key settings:

- **Allow rules** — Pre-approved tool patterns (e.g., read-only file access)
- **Deny rules** — Blocked operations (e.g., `TaskCreate`, `TodoWrite`)
- **Model selection** — Default model for sessions

Refer to `CLAUDE.md` for global instructions that Claude Code follows in every session.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Branch strategy and commit conventions
- How to add new skills, commands, or hooks
- Pull request process

---

## Security

See [SECURITY.md](SECURITY.md) for:

- Supported versions
- How to report vulnerabilities
- Security considerations for secrets handling

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
