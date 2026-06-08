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

## Meta-Prompt

Self-inject full `ACTIVE_TASK.md` content.

**Analyze:**
- What task type? (derive [FE] / [BE] / [FULLSTACK] / [INFRA] / [BUGFIX] / [REFACTOR] / [DOCS] from ## Requirement `type` + `techStack`)
- What files were created/modified? (from ## Implementation Log)
- Which codebase layers were touched? (FE = UI components/styles/routing; BE = services/APIs/DB/auth)
- What is the one-line outcome summary?

**Generate:**
1. **Task archive file** — full ACTIVE_TASK snapshot with type tag + outcome header
2. **FE_CONTEXT.md update** — if FE files touched: component tree, routing, key patterns, tech stack
3. **BE_CONTEXT.md update** — if BE files touched: services, endpoints, data models, auth, tech stack
4. **Reset ACTIVE_TASK.md** — empty fixed schema, ready for next task

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
const date = currentDate(); // YYYYMMDD

// Archive
writeFile(`task-log/${date}-${type}-${slug}.md`, archiveContent(activeTask));

// Regenerate context snapshots
if (touchesFE(activeTask)) {
  const feContext = await agent(feContextMetaPrompt, { schema: CONTEXT_SCHEMA });
  writeFile(".claude/context/FE_CONTEXT.md", feContext);
}
if (touchesBE(activeTask)) {
  const beContext = await agent(beContextMetaPrompt, { schema: CONTEXT_SCHEMA });
  writeFile(".claude/context/BE_CONTEXT.md", beContext);
}

// Reset
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
- [ ] Write task archive to task-log/YYYYMMDD-[TYPE]-slug.md
- [ ] If FE files touched: regenerate .claude/context/FE_CONTEXT.md
- [ ] If BE files touched: regenerate .claude/context/BE_CONTEXT.md
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
