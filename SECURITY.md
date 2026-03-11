# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| latest  | :white_check_mark: |

This project follows a rolling release model. Only the latest version on the
`main` branch is actively maintained and receives security updates.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please use one of these methods:

1. **GitHub Security Advisories** (preferred):
   [Report a vulnerability](https://github.com/jopre0502/claude-persist/security/advisories/new)

2. **Email**: Open a [private security advisory](https://github.com/jopre0502/claude-persist/security/advisories/new)
   on GitHub if email is not available.

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### What to Expect

- **Acknowledgment** within 48 hours
- **Assessment** within 7 days
- **Fix or mitigation** depending on severity:
  - Critical: as soon as possible
  - High: within 14 days
  - Medium/Low: next scheduled release

### Scope

This security policy covers:

- Shell scripts (skills, hooks, commands) that execute on user machines
- Configuration files that may reference sensitive paths or credentials
- Any code that processes user input or interacts with external services

### Out of Scope

- Vulnerabilities in Claude Code CLI itself (report to [Anthropic](https://github.com/anthropics/claude-code/security))
- Vulnerabilities in third-party dependencies not maintained by this project
- Issues that require physical access to the user's machine

## Security Best Practices for Contributors

- Never commit secrets, API keys, or credentials
- Use environment variables for sensitive configuration
- Validate and sanitize all external input in shell scripts
- Follow the principle of least privilege for file permissions
- Review `.gitignore` to ensure sensitive files are excluded
