---
description: Close task — archive to task-log, regenerate context files, reset ACTIVE_TASK.md
phase: integration
reads:
  - "ACTIVE_TASK.md (all sections)"
writes:
  - "task-log/YYYYMMDD-[TYPE]-slug.md"
  - ".claude/context/FE_CONTEXT.md"
  - ".claude/context/BE_CONTEXT.md"
  - "ACTIVE_TASK.md (reset to empty schema)"
hard_blocks:
  - condition: "## Requirement is empty"
    message: "Nothing to close. ACTIVE_TASK.md has no requirement. Run `task` to start a task."
  - condition: "## Review Findings is empty"
    message: "Task not reviewed. Run `review` before closing."
---

# Close Task

Archive completed task, regenerate codebase context snapshots, and reset ACTIVE_TASK.md — runs after merge regardless of deploy status.

## Prerequisites

Reads: `ACTIVE_TASK.md` (all sections)
Writes:
- `task-log/YYYYMMDD-[TYPE]-slug.md` — timestamped task archive
- `.claude/context/FE_CONTEXT.md` — frontend codebase snapshot (if FE touched)
- `.claude/context/BE_CONTEXT.md` — backend codebase snapshot (if BE touched)
- `ACTIVE_TASK.md` — reset to empty fixed schema

**Hard block:** If `## Requirement` is empty:
> "Nothing to close. ACTIVE_TASK.md has no requirement. Run `task` to start a task."

**Hard block:** If `## Review Findings` is empty:
> "Task not reviewed. Run `review` before closing."

## Agent Delegation

Context snapshot generation is offloaded to `sdlc-context-builder` agents. If both FE and BE were touched, spawn **two agents in parallel** — they write different files and have no shared state.

Do NOT generate context snapshots inline. The agent scans actual source files and does incremental merges against existing snapshots — accuracy requires reading files, not summarizing from memory.

**Inline (main thread):** task type derivation, slug generation, archive write, ACTIVE_TASK.md reset.
**Delegated:** FE_CONTEXT.md update, BE_CONTEXT.md update.

## Meta-Prompt

Self-inject full `ACTIVE_TASK.md` content.

**Analyze (main thread only):**
- What task type? (derive [FE] / [BE] / [FULLSTACK] / [INFRA] / [BUGFIX] / [REFACTOR] / [DOCS] from ## Requirement `type` + `techStack`)
- What files were created/modified? (from ## Implementation Log)
- Which layers touched? (FE = components/styles/routing; BE = services/APIs/DB/auth)
- One-line outcome summary?

**Generate:**
1. **Task archive file** — full ACTIVE_TASK snapshot with type tag + outcome header
2. **Context snapshots** — spawn `sdlc-context-builder` per layer (parallel if FULLSTACK)
3. **Reset ACTIVE_TASK.md** — empty fixed schema, ready for next task

## Type Tags

Derive from ## Requirement `type` and `techStack`:
- `[FE]` — frontend only (React, Vue, CSS, routing)
- `[BE]` — backend only (API, services, DB, auth)
- `[FULLSTACK]` — both FE and BE touched
- `[BUGFIX]` — type=bugfix regardless of layer
- `[REFACTOR]` — type=refactor regardless of layer
- `[INFRA]` — CI/CD, Docker, k8s, config only
- `[DOCS]` — documentation only

## Pattern

```javascript
const activeTask = readFullActiveTask();
if (!activeTask["## Requirement"]) hardBlock("task");
if (!activeTask["## Review Findings"]) hardBlock("review");

const type = deriveTypeTag(activeTask);
const slug = slugify(activeTask["## Requirement"].goal);
const date = args.date; // passed in — YYYYMMDD

// 1. Archive (main thread — fast, no file scanning needed)
writeFile(`task-log/${date}-${type}-${slug}.md`, archiveContent(activeTask));

// 2. Regenerate context snapshots (delegated, parallel when FULLSTACK)
const filesChanged = activeTask["## Implementation Log"].filesCreated;
const contextJobs = [];

if (touchesFE(activeTask)) {
  contextJobs.push(() => agent(
    `Build FE context snapshot for files: ${filesChanged.filter(isFE).join(", ")}`,
    { agentType: "sdlc-context-builder", label: "context:FE",
      // agent reads existing FE_CONTEXT.md and filesChanged internally
    }
  ));
}
if (touchesBE(activeTask)) {
  contextJobs.push(() => agent(
    `Build BE context snapshot for files: ${filesChanged.filter(isBE).join(", ")}`,
    { agentType: "sdlc-context-builder", label: "context:BE" }
  ));
}

// Parallel when both layers touched — each writes a different file, no conflict
await parallel(contextJobs);

// 3. Reset (main thread — after context agents complete)
writeFile("ACTIVE_TASK.md", EMPTY_SCHEMA_TEMPLATE);
```

## Context Snapshot Format

`.claude/context/FE_CONTEXT.md` and `BE_CONTEXT.md` follow this structure:

```markdown
# [FE|BE] Context Snapshot
Generated: YYYYMMDD — updated each task close.

## Tech Stack
[framework, language, key libraries]

## Key Files
[file: purpose — one line each]

## Patterns
[naming conventions, folder structure, key abstractions]

## Data Models / API Contracts
[entities, endpoints — brief]

## Known Constraints
[performance limits, compatibility requirements, tech debt notes]
```

## Trigger Points

- After merge to main or develop branch (regardless of deploy status)
- User says "close task", "task done", "wrap up", "archive this"
- Before starting a new task (ACTIVE_TASK.md must be reset)

## Output

- `task-log/YYYYMMDD-[TYPE]-slug.md` created
- `.claude/context/FE_CONTEXT.md` updated (if FE touched)
- `.claude/context/BE_CONTEXT.md` updated (if BE touched)
- `ACTIVE_TASK.md` reset to empty fixed schema

## Checklist

- [ ] Read full ACTIVE_TASK.md; hard block if ## Requirement empty
- [ ] Hard block if ## Review Findings empty
- [ ] Derive type tag from task type + tech stack
- [ ] Generate slug from goal (lowercase, hyphens)
- [ ] Write task archive to task-log/YYYYMMDD-[TYPE]-slug.md (main thread)
- [ ] Extract filesChanged from ## Implementation Log
- [ ] If FE files touched: spawn `sdlc-context-builder` (layer=FE, filesChanged, date)
- [ ] If BE files touched: spawn `sdlc-context-builder` (layer=BE, filesChanged, date)
- [ ] If FULLSTACK: spawn both in parallel — different output files, no conflict
- [ ] Wait for context agent(s) to complete before reset
- [ ] Reset ACTIVE_TASK.md to empty fixed schema
- [ ] Commit: task-log/ + context updates + ACTIVE_TASK.md reset
- [ ] Next: `ship` (if deploying) or `task` (next task)

## Example

**Input (from ACTIVE_TASK.md → full content):**
```
## Requirement: type=feature, goal="Add JWT auth to FastAPI", techStack=Python/FastAPI
## Implementation Log: files=[src/services/auth.py, src/routers/auth.py]
## Review Findings: APPROVED_WITH_CHANGES (all resolved)
```

**Output:**
```
task-log/20240115-[BE]-add-jwt-auth-to-fastapi.md  ← created
.claude/context/BE_CONTEXT.md                       ← updated
ACTIVE_TASK.md                                      ← reset to empty schema
```

`BE_CONTEXT.md` after update:
```markdown
# BE Context Snapshot
Generated: 20240115

## Tech Stack
Python 3.11, FastAPI, SQLAlchemy, argon2id, stateless JWT (python-jose)

## Key Files
src/services/auth.py   — JWT issue/verify, password hashing
src/services/user.py   — user CRUD, email validation
src/repositories/user.py — DB queries (SQLAlchemy)
src/routers/auth.py    — POST /auth/token endpoint
src/routers/users.py   — user CRUD endpoints
src/main.py            — FastAPI app, router wiring

## Patterns
Repository pattern: routers → services → repositories (no cross-layer skips)
All endpoints return Pydantic response models (no ORM objects in responses)

## API Contracts
POST /auth/token  { email, password } → { access_token, token_type } | 401
POST /users       { email, password } → { id, email } | 409
GET  /users/{id}  → { id, email, created_at } | 404

## Known Constraints
JWT TTL=15min, non-revocable (stateless decision — ADR-002)
argon2id work factor tuned for staging; verify on prod hardware
```

---

*Next: `ship` (if deploying now) or `task` (next task).*
