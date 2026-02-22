# Session Refresh - Reference Documentation

Human-facing documentation for the session-refresh skill.
For execution logic, see SKILL.md.

---

## What This Skill Does

Claude automatically performs a complete session refresh:
1. **Reads state** - CLAUDE.md + PROJEKT.md
2. **Runs Health-Check** - Token-efficient script validates task table consistency, dependencies, file existence
3. **Updates CLAUDE.md** - Claude analyzes session learnings and adds decisions, architecture updates, insights
4. **Updates PROJEKT.md** - Claude updates task status, phase progress, Definition of Done based on session work
5. **Restructures documentation** - Triggers `/project-doc-restructure` (conditional, only if needed)
6. **Token-Optimierung** - User reduziert danach Token-Budget manuell (CLI Built-in)
7. **GitHub-Push anbieten** - Falls `.claude/github.json` existiert
8. **Session-Handoff anbieten** - Narratives Handoff-Dokument fuer naechste Session
9. **Reports summary** - Compact summary of changes

## When to Use

**Perfect timing:**
- Token budget at 65-70%
- Before ending a session
- Phase transition (consolidate learnings)
- Major tasks completed

**Don't need session-refresh if:**
- Token budget still <50%
- Session just started (previous session already refreshed)
- Small incremental work

**Important:** Run at END of session, not at START.

## Common Questions

**Q: Does Claude make all the changes automatically?**
A: Yes. Claude analyzes your session, identifies learnings, and makes targeted updates. You review and confirm before restructure runs.

**Q: What if I want to make my own edits?**
A: Request "manual mode" and Claude will show you the checklist while you make edits yourself.

**Q: What if Claude missed something?**
A: After Claude shows the summary, you can request adjustments before proceeding.

**Q: Can I run this mid-session?**
A: Yes! Run it anytime your token budget hits 60%+.

**Q: Warum muss ich das Token-Budget manuell reduzieren?**
A: Der CLI Built-in Befehl zur Kontextreduktion kann nicht programmatisch von Skills aufgerufen werden.

**Q: How long does this take?**
A: ~5-8 minutes total (Claude analyzes: 2-3 min, User review: 1-2 min, Restructure: 2-3 min).
