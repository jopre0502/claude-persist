# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-11

### Changed

- **Repository renamed** from `my-claude-knowledge-hub` to `claude-persist`
- **README rewritten** with Painpoint-First structure (Problem → Solution → What's Inside)
- **Tagline updated** to "Make Claude Code remember. Sessions that persist, tasks that finish, context that never dies."
- All internal URLs updated in CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md

### Added

- New skills: env-init, end-of-day, auto-task plugin
- GitHub Topics optimized for discoverability

## [1.0.0] - 2026-03-05

### Added

- **18 Skills** for session-continuous development (session-refresh, vault-manager, task-orchestrator, prompt-improver, project-init, skill-creator, and more)
- **2 Agents** (my-setup-guide, prompt-architect) for specialized autonomous tasks
- **6 Commands** (obsidian-sync, vault-export, run-next-tasks, sync-claude-persist, and more)
- **5 Hooks** (session-env-loader, notify, session-handoff-loader, tool-call-logger, startup)
- **1 Output Style** (Executive communication mode with German language preference)
- **10 Plugins** (code-review, commit-commands, hookify, pr-review-toolkit, feature-dev, frontend-design, plugin-dev, and more)
- Session-continuous workflow with automatic handoffs and token budget awareness
- Task orchestration with UUID-based tracking and dependency resolution
- Obsidian Vault integration (read, search, export) via CLI
- Secrets management via CLAUDE_ENV_FILE and env.d structure
- Community standard files: README, LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- GitHub Issue Templates (bug report, feature request)
- Secret scanning and push protection enabled

[1.1.0]: https://github.com/jopre0502/claude-persist/releases/tag/v1.1.0
[1.0.0]: https://github.com/jopre0502/claude-persist/releases/tag/v1.0.0
