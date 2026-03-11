# claude-persist

> **Make Claude Code remember.** Sessions that persist, tasks that finish, context that never dies.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## The Problem

Claude Code is powerful — but **stateless**. Every session starts from zero.

- Yesterday's progress? Gone. No memory of what was discussed, decided, or built.
- Task tracking across sessions? Manual copy-paste into prompts.
- Repetitive workflows? Type the same instructions every time.
- Token budget? Runs out silently. Context collapses without warning.

**Claude Code out of the box is a brilliant engineer with amnesia.**

## The Solution

**claude-persist** makes Claude Code sessions continuous. Install once, benefit in every project.

### Persistent Memory

Sessions write structured handoffs. The next session picks up exactly where you left off — decisions, progress, blockers, learnings. No re-explaining.

### Task Orchestration

UUID-based task tracking with dependency resolution, sub-agent delegation, and automatic checkpoint commits. A project manager that lives inside your terminal.

### 20+ Automation Skills

From project scaffolding to prompt optimization, from documentation restructuring to Obsidian vault integration. Each skill replaces 10-15 minutes of manual prompting.

### Token Budget Awareness

Proactive monitoring prevents context collapse. Automatic documentation refresh before you hit the limit.

---

## What's Inside

| Component | Count | Highlights |
|-----------|------:|------------|
| **Skills** | 20+ | session-refresh, task-orchestrator, vault-manager, prompt-improver, project-init |
| **Commands** | 6 | `/run-next-tasks`, `/obsidian-sync`, `/vault-export`, `/sync-claude-persist` |
| **Hooks** | 4 | Session handoff loader, notification system, tool-call logger |
| **Agents** | 1 | Setup guide agent for self-documentation |
| **Output Styles** | 1 | Executive communication mode (German/English) |
| **Plugins** | 14 | code-review, commit-commands, hookify, pr-review-toolkit, feature-dev |

---

## Key Workflows

### Session Start (2 minutes)

```text
1. Claude reads CLAUDE.md + PROJEKT.md (automatic)
2. /run-next-tasks → identifies ready tasks
3. Start working — full context from previous session loaded
```

### Session End (automatic)

```text
1. Final commit with descriptive message
2. Session handoff written (progress, blockers, recommendations)
3. Documentation refresh if token budget > 65%
```

### Task Lifecycle

```text
Create → Schedule → Execute (with sub-agents) → Checkpoint → Complete
         ↑                                                      |
         └──────────────────────────────────────────────────────┘
                         Dependencies resolve automatically
```

---

## Quick Start

```bash
# Clone into ~/.claude/
git clone https://github.com/jopre0502/claude-persist.git ~/.claude/

# That's it. Claude Code auto-discovers everything from ~/.claude/
```

> **Already have `~/.claude/`?** Back it up first — this repo replaces the entire directory.

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (latest)
- Bash >= 4.0 (macOS: `brew install bash`)
- Git >= 2.30
- Optional: [Obsidian](https://obsidian.md/) for vault integration
- Optional: [1Password CLI](https://developer.1password.com/docs/cli/) for secrets management

---

## Core Skills

| Skill | What it does |
|-------|-------------|
| `session-refresh` | Updates project docs, triggers restructuring, manages token budget |
| `task-orchestrator` | Executes tasks with sub-agent delegation and checkpoint commits |
| `task-scheduler` | Resolves dependencies, identifies which tasks are ready |
| `vault-manager` | Read-only Obsidian Vault access via `vault:` prefix notation |
| `project-init` | One-command project scaffolding with full session-continuous infrastructure |
| `prompt-improver` | Analyzes and improves prompts following Anthropic best practices |
| `skill-creator` | Guided skill creation with validation and best-practice enforcement |
| `prioritize-tasks` | Scores tasks by dependencies, effort, and blockers |

[View all skills and commands →](docs/COMPONENT-REFERENCE.md)

---

## How It Works

### Session-Continuous Architecture

```text
~/.claude/
├── CLAUDE.md              # Global instructions (loaded every session)
├── skills/                # 20+ automation skills
├── agents/                # Autonomous agents
├── commands/              # Slash commands (/run-next-tasks, etc.)
├── hooks/                 # Event-driven automation
├── output-styles/         # Communication modes
├── projects/              # Per-project memory (handoffs, decisions)
├── plugins/               # Installed plugins
└── settings.json          # Permissions and auto-approval rules
```

### Per-Project Infrastructure

Each project gets its own session-continuous setup via `/project-init`:

```text
your-project/
├── CLAUDE.md              # Project-specific instructions
├── PROJEKT.md             # Task tracking (7-column schema)
└── docs/
    ├── tasks/             # Individual task files with audit trail
    ├── handoffs/          # Session handoff history
    └── DECISION-LOG.md    # Architectural decisions
```

---

## Design Principles

1. **Persist over Reset** — Every session builds on the last
2. **Convention over Configuration** — Works out of the box, customizable when needed
3. **Automation over Repetition** — If you do it twice, make it a skill
4. **Transparency over Magic** — Every decision logged, every action traceable
5. **Cross-Platform** — Windows (Git Bash) and macOS, OS-detection built in

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch strategy, commit conventions, and how to add new skills, commands, or hooks.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting and security best practices.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <i>Built with Claude Code. Powered by persistence.</i>
</p>
