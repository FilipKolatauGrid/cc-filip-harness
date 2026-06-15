---
name: close
description: Close task — archive ACTIVE_TASK.md to task-log, regenerate codebase context snapshots (FE/BE), and reset ACTIVE_TASK.md to empty schema. Use after merge regardless of deploy status. Use when the user says "close task", "task done", "wrap up", "archive this", "done", or after `ship` or merge completes. MANDATORY after every merge — skipping this leaves stale state for the next task and breaks session initialization. Hard-blocks if requirement or review findings are missing.
---

# Close Task

Archive completed task, regenerate codebase context snapshots, and reset ACTIVE_TASK.md — runs after merge regardless of deploy status.

## Principles in Play

**Every session must leave clean state.** Close is the enforcement mechanism. After close: `ACTIVE_TASK.md` is reset, context snapshots are fresh, and the next session starts from clean. Skipping close means the next task inherits stale state — the single biggest source of context confusion.

**Observability inside harness.** Close reads every Observation block across all completed phases to verify the task actually progressed through the phases (not just that sections are non-empty). If key phase Observations are missing, close warns before archiving.

**Why every session must leave clean state.** The `task-log/` archive is the long-term record. Context snapshots are how future sessions avoid cold file scans. Both only exist if `close` runs. This skill is not optional.

## Prerequisites

Reads: `ACTIVE_TASK.md` (all sections)
Writes:
- `task-log/YYYYMMDD-[TYPE]-slug.md` — timestamped task archive
- `.claude/context/FE_CONTEXT.md` — updated if FE files touched
- `.claude/context/BE_CONTEXT.md` — updated if BE files touched
- `ACTIVE_TASK.md` — reset to empty fixed schema

**Hard block:** If `## Requirement` is empty:
> "Nothing to close. ACTIVE_TASK.md has no requirement. Run `task` to start a task."

**Hard block:** If `## Review Findings` is empty:
> "Task not reviewed. Run `review` before closing."

**Warning (not block):** If key phase Observation blocks are missing (e.g., verify, review):
> "Warning: Some phases lack Observation blocks — the task archive may be incomplete. Recommend re-running missing phases before closing. Proceed anyway? (y/n)"

## Agent Delegation

Context snapshot generation is offloaded to `sdlc-context-builder` agents. If both FE and BE were touched, spawn **two agents in parallel** — they write different files with no shared state.

Do NOT generate context snapshots inline. The agent scans actual source files and does incremental merges — accuracy requires reading files.

**Inline (main thread):** type tag derivation, slug generation, archive write, Observation scan, ACTIVE_TASK.md reset.
**Delegated:** FE_CONTEXT.md update, BE_CONTEXT.md update.

## Meta-Prompt

Self-inject full `ACTIVE_TASK.md` content.

**Analyze:**
- What task type? (derive [FE] / [BE] / [FULLSTACK] / [INFRA] / [BUGFIX] / [REFACTOR] / [DOCS])
- What files were created/modified? (from ## Implementation Log)
- Which layers touched?
- One-line outcome summary?
- Which phases have Observation blocks (evidence of completion)?

**Generate:**
1. **Observation scan** — which phases ran with evidence vs. which are empty or self-reported
2. **Task archive file** — full ACTIVE_TASK snapshot with type tag + outcome header
3. **Context snapshots** — spawn `sdlc-context-builder` per layer (parallel if FULLSTACK)
4. **Reset ACTIVE_TASK.md** — empty fixed schema, ready for next task

## Pattern

```javascript
const activeTask = readFullActiveTask();
if (!activeTask["## Requirement"]) hardBlock("task");
if (!activeTask["## Review Findings"]) hardBlock("review");

// Observation scan — warn on missing evidence
const observations = scanObservationBlocks(activeTask);
const missingObs = REQUIRED_PHASES.filter(p => !observations[p]);
if (missingObs.length > 0) {
  warn(`Missing Observation blocks for: ${missingObs.join(", ")}. Archive may be incomplete.`);
}

const type = deriveTypeTag(activeTask);
const slug = slugify(activeTask["## Requirement"].goal);
const date = getCurrentDate(); // YYYYMMDD

// Archive
writeFile(`task-log/${date}-${type}-${slug}.md`, archiveContent(activeTask, observations));

// Context snapshots (parallel when FULLSTACK)
const filesChanged = activeTask["## Implementation Log"].filesCreated;
const contextJobs = [];
if (touchesFE(activeTask)) {
  contextJobs.push(() => agent(`Build FE context snapshot`, { agentType: "sdlc-context-builder" }));
}
if (touchesBE(activeTask)) {
  contextJobs.push(() => agent(`Build BE context snapshot`, { agentType: "sdlc-context-builder" }));
}
await parallel(contextJobs);

// Reset
writeFile("ACTIVE_TASK.md", EMPTY_SCHEMA_TEMPLATE);
```

## Trigger Points

- After merge to main or develop branch (regardless of deploy status)
- User says "close task", "task done", "wrap up", "archive this"
- **Before starting a new task** — ACTIVE_TASK.md must be reset

## Output

- `task-log/YYYYMMDD-[TYPE]-slug.md` created with full task archive
- `.claude/context/FE_CONTEXT.md` updated (if FE touched)
- `.claude/context/BE_CONTEXT.md` updated (if BE touched)
- `ACTIVE_TASK.md` reset to empty fixed schema

## Checklist

- [ ] Read full ACTIVE_TASK.md; hard block if ## Requirement empty
- [ ] Hard block if ## Review Findings empty
- [ ] Scan Observation blocks across all phases — warn if key phases missing evidence
- [ ] Derive type tag from task type + tech stack
- [ ] Generate slug from goal (lowercase, hyphens)
- [ ] Write task archive to task-log/YYYYMMDD-[TYPE]-slug.md (main thread)
- [ ] Extract filesChanged from ## Implementation Log
- [ ] If FE files touched: spawn `sdlc-context-builder` (layer=FE)
- [ ] If BE files touched: spawn `sdlc-context-builder` (layer=BE)
- [ ] If FULLSTACK: spawn both in parallel (different output files, no conflict)
- [ ] Wait for context agents to complete before reset
- [ ] Reset ACTIVE_TASK.md to empty fixed schema
- [ ] Confirm reset: read back ACTIVE_TASK.md — verify all sections empty
- [ ] Commit: task-log/ + context updates + ACTIVE_TASK.md reset
- [ ] Next: `ship` (if still deploying) or `task` (next task)

## Type Tags

- `[FE]` — frontend only (React, Vue, CSS, routing)
- `[BE]` — backend only (API, services, DB, auth)
- `[FULLSTACK]` — both FE and BE touched
- `[BUGFIX]` — type=bugfix regardless of layer
- `[REFACTOR]` — type=refactor regardless of layer
- `[INFRA]` — CI/CD, Docker, k8s, config only
- `[DOCS]` — documentation only

---

*Next: `task` (start next task).*
