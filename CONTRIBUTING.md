# Contributing to my-claude-knowledge-hub

Thank you for your interest in contributing! This guide covers the conventions and workflow for this repository.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/<your-user>/my-claude-knowledge-hub.git ~/.claude/`
3. Create a feature branch: `git checkout -b feat/your-feature`
4. Make your changes
5. Commit and push
6. Open a Pull Request

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Stable, production-ready configuration |
| `feat/*` | New skills, commands, agents, or hooks |
| `fix/*` | Bug fixes |
| `docs/*` | Documentation updates |

## Commit Conventions

Commit messages follow this format:

```
<type>: Short description (max 50 chars)

Optional longer description.

Co-Authored-By: Your Name <email>
```

**Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

**Examples:**
- `feat: Add vault-export command for Obsidian integration`
- `fix: Handle CRLF line endings in session-env-loader`
- `docs: Update README with new skill inventory`

## Adding a New Skill

1. Create directory: `skills/<skill-name>/`
2. Add `SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   description: "Clear, keyword-rich description of what the skill does and when to use it"
   ---
   ```
3. Keep `SKILL.md` under 500 lines; use supporting files for details
4. Test the skill in a Claude Code session before submitting

## Adding a New Command

1. Create `commands/<command-name>.md` with YAML frontmatter:
   ```yaml
   ---
   name: command-name
   description: "What the command does"
   ---
   ```
2. Commands are invoked via `/<command-name>` in Claude Code

## Adding a New Hook

1. Create `hooks/<hook-name>.sh`
2. Register the hook in `settings.json` under the appropriate event
3. Ensure the script is executable and handles both Windows (Git Bash) and macOS

## Code Style

- **Shell scripts:** Bash 4.0+, use `shellcheck` for linting
- **Line endings:** LF only (enforced via `.gitattributes`)
- **Indentation:** 2 spaces
- **No secrets** in code, configs, or commit history

## Pull Request Process

1. Ensure your branch is up to date with `main`
2. Describe what changed and why in the PR description
3. Link related issues if applicable
4. Wait for review before merging

## Reporting Issues

Use [GitHub Issues](https://github.com/jopre0502/my-claude-knowledge-hub/issues) with the provided templates for bug reports and feature requests.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please read it before participating.
