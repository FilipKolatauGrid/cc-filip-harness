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

# 2. Copy .claude/ into your new project
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
# 1. Copy .claude/ skills and workflows into your project root
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

Commands: /task /init /design /grill /risk /code /tdd /refactor /tests /coverage /verify /review /audit /deploy /ship /close

State: ACTIVE_TASK.md (one section per phase, hard-gated)
Archive: task-log/YYYYMMDD-[TYPE]-slug.md after each /close
```

---

## Minimum File Set

The harness requires these files at your project root:

```
.claude/
  skills/         ← all 15 skill files
  workflows/      ← 4 workflow files
  context/        ← empty dir (populated by /close)
ACTIVE_TASK.md    ← empty schema (reset after each /close)
CLAUDE.md         ← session init instructions
task-log/         ← empty dir (populated by /close)
```

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
# .claude/skills/
# .claude/workflows/
```

---

## Updating the Harness

When the harness has new skills or fixes:

```bash
# Pull latest skill files
cd .claude-harness && git pull
cp -r .claude-harness/.claude/skills your-project/.claude/skills
cp -r .claude-harness/.claude/workflows your-project/.claude/workflows
```

Your `task-log/`, `.claude/context/`, and `ACTIVE_TASK.md` are project-local — they never get overwritten by harness updates.

---

## Troubleshooting

**"Hard block: ## Requirement is empty"**
→ Run `/task` first. Nothing can proceed without a structured requirement.

**"Hard block: ## Design is empty"**
→ Run `/design`. Skills gate on prior phase output.

**Skills not discovered by Claude Code**
→ Ensure `.claude/skills/` exists at your project root (not a subdirectory). Claude Code discovers skills relative to the working directory.

**ACTIVE_TASK.md grew too large**
→ Run `/close` to archive and reset. Each task should have its own cycle.

**Context snapshots stale**
→ Run `/close` after every merge. This keeps `FE_CONTEXT.md`/`BE_CONTEXT.md` current.
