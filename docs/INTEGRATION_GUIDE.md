# Integration Guide

How to add the SDLC harness to any project — greenfield or existing.

---

## Prerequisites

1. [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
2. [caveman](https://github.com/juliusbrussee/caveman) plugin (optional but recommended — cuts token usage ~75%)

---

## Option A: Greenfield Project

```bash
# 1. Clone the harness
git clone https://github.com/your-org/claude-code-harness .claude-harness

# 2. Copy .claude/ into your new project (includes skills/, agents/, workflows/, hooks/)
cp -r .claude-harness/.claude your-project/.claude
cp .claude-harness/CLAUDE.md your-project/CLAUDE.md
cp .claude-harness/ACTIVE_TASK.md your-project/ACTIVE_TASK.md

# 3. Create directories
mkdir -p your-project/task-log
mkdir -p your-project/docs

# 4. Start
cd your-project
/task
```

Then follow the `/init` scaffold output to create your project structure.

---

## Option B: Existing Project

```bash
# 1. Copy .claude/ agents and workflows into your project root
cp -r .claude-harness/.claude your-project/.claude

# 2. Merge or create CLAUDE.md
# If you already have CLAUDE.md: append the harness section (see below)
# If not: copy it directly
cp .claude-harness/CLAUDE.md your-project/CLAUDE.md

# 3. Copy ACTIVE_TASK.md schema
cp .claude-harness/ACTIVE_TASK.md your-project/ACTIVE_TASK.md

# 4. Create task-log directory
mkdir -p your-project/task-log
```

**Skip `/init` for existing projects.** Start with `/task` then jump straight to `/design`.

---

## Merging CLAUDE.md

If your project already has a `CLAUDE.md`, append this block:

```markdown
## SDLC Harness

Session init: read `docs/SKILL_REGISTRY.md`, then `ACTIVE_TASK.md`.
Load `.claude/context/BE_CONTEXT.md` and/or `FE_CONTEXT.md` if they exist.

Skills: /task /init /design /grill /risk /code /tdd /refactor /tests /coverage /verify /review /audit /deploy /ship /close
Meta: /validate-harness /local-env-requirements

State: ACTIVE_TASK.md (one section per phase, hard-gated)
Archive: task-log/YYYYMMDD-[TYPE]-slug.md after each /close
Reference: docs/HARNESS_REFERENCE.md (schema template + file map)
```

---

## Minimum File Set

The harness requires these files at your project root:

```
.claude/
  skills/         ← 18 skill dirs (each with SKILL.md)
                    SDLC: task/ init/ design/ grill/ risk/ code/ tdd/ refactor/
                          tests/ coverage/ verify/ review/ audit/ deploy/ ship/ close/
                    Meta: validate-harness/ local-env-requirements/
                    CLAUDE.md  ← skill authoring convention
  agents/         ← sdlc subagents (spawned by skills, not invoked directly)
  workflows/      ← 4 workflow files
  hooks/          ← 6 automation hooks (wired in settings.local.json)
  context/        ← empty dir (populated by /close)
reports/          ← empty dir (populated by /validate-harness)
ACTIVE_TASK.md    ← empty schema with <!-- Status: idle --> sentinel (reset after each /close)
CLAUDE.md         ← session init instructions
task-log/         ← empty dir (populated by /close)
```

---

## Hooks Setup

The harness ships with 5 hooks in `.claude/hooks/`. The Claude Code hooks (1–4) are pre-wired in `.claude/settings.local.json`. The git hook (5) requires a one-time manual install per clone.

### Claude Code hooks (auto-active after copy)

| Hook | Event | Effect |
|------|-------|--------|
| `load-context.sh` | `SessionStart` | Injects harness phase/verdict/next-skill into context window |
| `phase-gate.sh` | `PreToolUse(Bash)` | Blocks out-of-order skill invocations (exit 2) |
| `secops-scan.sh` | `PostToolUse(Write\|Edit)` | Async secret/vuln scan on source files during implementation |
| `verify-fail-capture.sh` | `UserPromptSubmit` | Injects prior `/verify` FAIL blockers on retry |
| `harness-change-detect.sh` | `PostToolUse(Write\|Edit)` | Fires when a harness file is edited; reminds session to run `/validate-harness` |

These fire automatically when Claude Code loads `.claude/settings.local.json` from the project root — no extra setup.

### Git pre-commit hook (manual install)

```bash
cp .claude/hooks/pre-commit.template .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Blocks `git commit` when ACTIVE_TASK.md is in an early phase with no test evidence. Override when needed: `git commit --no-verify`.

### Disabling hooks

To disable all Claude Code hooks temporarily:
```json
// .claude/settings.local.json
{ "disableAllHooks": true }
```

To disable a single hook, remove its entry from the `hooks` section in `.claude/settings.local.json`.

### CI/CD post-merge auto-close (reference pattern)

The harness is local-first, but teams can wire `/close` into CI. Example GitHub Actions pattern:

```yaml
# .github/workflows/harness-close.yml
on:
  pull_request:
    types: [closed]
    branches: [main]

jobs:
  close-task:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run harness close
        run: claude -p "/close" --output-format stream-json
        # Requires ANTHROPIC_API_KEY secret + claude CLI installed
```

This keeps `.claude/context/` snapshots current across the team without manual `/close` after every merge.

---

## Per-Stack Setup

### Python (FastAPI / Django / CLI)

No stack-specific config needed. When you run `/task`, specify:
```
techStack: Python 3.x, [framework], pytest, ruff
```
The skills will generate Python-appropriate output (pyproject.toml, pytest patterns, etc.)

### TypeScript / Node (NestJS / Express / Next.js)

Specify:
```
techStack: TypeScript, [framework], Jest, [orm]
```
Skills generate NestJS Guards/Interceptors, Jest test patterns, tsconfig references.

### Go

Specify:
```
techStack: Go 1.21, [gin/chi/stdlib], testing (stdlib), golangci-lint
```

### Monorepos

Run one ACTIVE_TASK.md per service/package. Store them as:
```
packages/api/ACTIVE_TASK.md
packages/web/ACTIVE_TASK.md
```
Update CLAUDE.md to reference the right one per session, or prefix commands:
```
/task  (with context: "working in packages/api")
```

---

## Multi-Developer Teams

Each developer works on their own branch with their own `ACTIVE_TASK.md`. Recommended:

1. Add `ACTIVE_TASK.md` to `.gitignore` (it's per-developer state)
2. Commit `task-log/` entries after `/close` — these are the shared record
3. Commit `.claude/context/` updates — these are the shared codebase snapshots

```gitignore
# .gitignore
ACTIVE_TASK.md
```

---

## CI/CD Integration

The harness is a developer tool, not a CI runner. But two outputs integrate with CI:

**Deploy Checklist (`/deploy`)** — paste the generated checklist into your PR description or a pre-deploy runbook.

**Task Log (`/close`)** — `task-log/` files are the audit trail. Commit them and your team has a chronological record of every completed task with outcomes, ADRs, and review findings.

---

## .gitignore Recommendations

```gitignore
# Keep ACTIVE_TASK per-developer (not shared state)
ACTIVE_TASK.md

# Commit these (shared team artifacts):
# task-log/
# .claude/context/
# .claude/agents/
# .claude/workflows/
```

---

## Updating the Harness

When the harness has new skills or fixes:

```bash
# Pull latest
cd .claude-harness && git pull
cp -r .claude-harness/.claude/skills    your-project/.claude/skills
cp -r .claude-harness/.claude/agents    your-project/.claude/agents
cp -r .claude-harness/.claude/workflows your-project/.claude/workflows
cp -r .claude-harness/.claude/hooks     your-project/.claude/hooks
# Re-install git hook after hooks update
cp your-project/.claude/hooks/pre-commit.template your-project/.git/hooks/pre-commit
```

Your `task-log/`, `.claude/context/`, and `ACTIVE_TASK.md` are project-local — they never get overwritten by harness updates.

---

## Troubleshooting

**"Hard block: ## Requirement is empty"**
→ Run `/task` first. Nothing can proceed without a structured requirement.

**"Hard block: ## Design is empty"**
→ Run `/design`. Skills gate on prior phase output.

**Skills not found (`/task`, `/design`, etc.)**
→ Ensure `.claude/skills/` exists at your project root with all 18 skill directories. Claude Code discovers skills from `.claude/skills/<name>/SKILL.md`. If missing, copy from the harness repo.

**Want to verify harness health after integration?**
→ Run `/validate-harness`. It scores the harness against 32 checks across 7 sections and writes a report to `reports/harness-validation-report.md`. Target: ≥ 85% (Solid band). The `harness-change-detect.sh` hook will remind you to re-run it whenever you modify harness files.

**ACTIVE_TASK.md grew too large**
→ Run `/close` to archive and reset. Each task should have its own cycle.

**Context snapshots stale**
→ Run `/close` after every merge. This keeps `FE_CONTEXT.md`/`BE_CONTEXT.md` current.
