---
name: task
description: Capture requirements — parse a task description, bug report, or feature request into a structured definition with acceptance criteria, scope, constraints, and success metrics. Use this skill whenever starting any new work, at the beginning of every session with a task in mind, or when a user provides a task description, issue, or request that needs structuring. Always run this before design, code, or any other phase skill. If the user says "I want to build X", "there's a bug with Y", "we need to add Z", or pastes an issue — trigger this skill immediately.
---

# Capture Requirements

Parse user intent into a structured task definition with acceptance criteria, scope, and success metrics.

## Principles in Play

**Initialization needs its own phase.** This skill is the mandatory entry point — no design, code, or test skill may run without a populated `## Requirement`. Enforces clean-state start: if `ACTIVE_TASK.md` already has a populated `## Requirement`, warn the user to run `close` on the previous task before starting a new one.

**Feature lists are harness primitives.** Acceptance criteria written here are the source of truth for every downstream skill. `code`, `tdd`, and `verify` read AC directly from this section — they never infer from design or memory.

## Prerequisites

Reads: nothing (entry point)
Writes: `ACTIVE_TASK.md` → `## Requirement`

**Guard:** If `## Requirement` is already populated in `ACTIVE_TASK.md`:
> "ACTIVE_TASK.md already has an active requirement. Run `close` to archive the current task before starting a new one, or continue the current task by reading the existing requirement."

**Create** `ACTIVE_TASK.md` at project root if it doesn't exist. Use the fixed schema from `CLAUDE.md`.

## Meta-Prompt

Given user text describing a task (feature request, bug report, refactor request):

**Analyze:**
- Is this a new feature, bug fix, refactor, or improvement?
- What is the primary goal?
- Who is the user (engineer, product manager, end-user)?
- What constraints exist (timeline, compatibility, tech stack)?

**Generate:**
1. **Task Type** — feature|bugfix|refactor|improvement|maintenance
2. **Goal Statement** — 1-2 sentences, clear and measurable
3. **Acceptance Criteria** — bulleted list of "must-have" requirements, each testable and independently verifiable
4. **Scope** — what's in scope, what's explicitly out
5. **Constraints** — tech stack, compatibility, timeline, team size
6. **Success Metrics** — how to verify task is done (measurable values, not vague statements)
7. **Questions** — clarifications needed before planning

## Pattern

```
// 1. Check latest task-log for ## Deferred; if non-empty prompt "Inherit N deferred issues as AC candidates? (y/n)"
// 2. Guard: warn if ## Requirement already populated (don't silently overwrite)
// 3. Self-inject user input; generate requirement schema (type, goal, AC, scope, constraints, metrics, questions)
// 4. Write to ACTIVE_TASK.md → ## Requirement
// 5. Append Observation block
```

## Observation Block

Append after writing `## Requirement`:

```
### Observation
- phase: intake/task
- done-signal: schema-populated
- done-criteria: acceptanceCriteria non-empty, scope defined, successMetrics measurable
- verdict-source: self-reported
```

## Trigger Points

- User starts new session with a task description
- User says "new task", "/task", "I want to build X", "there's a bug with Y"
- Team member files an issue that needs structuring
- Entry point — always first

## Output

Writes structured task definition to `ACTIVE_TASK.md → ## Requirement`:
- Task type, goal, acceptance criteria, scope, constraints, success metrics, questions

## Deferred Findings Check

At start of every invocation, check the most recent file in `task-log/` for a `## Deferred` section.

- If `## Deferred` is non-empty: surface prompt before writing requirement:
  > "Previous task deferred N issues — inherit as AC candidates? (y/n)"
  > [list deferred items]
  - If yes: prepend as candidate ACs in the new requirement (developer can edit/drop any)
  - If no: proceed without them
- If `## Deferred` is empty or no task-log exists: skip silently.

## Checklist

- [ ] Check latest task-log for ## Deferred; surface y/n prompt if non-empty
- [ ] Check ACTIVE_TASK.md → ## Requirement — warn if already populated (don't silently overwrite)
- [ ] Extract task type (feature/bugfix/refactor/other)
- [ ] Identify goal vs. implementation details
- [ ] List acceptance criteria (testable, measurable, independently verifiable)
- [ ] Define scope boundaries (in/out)
- [ ] Surface constraints (timeline, team, tech)
- [ ] Propose success metrics (numbers, not adjectives)
- [ ] Identify ambiguities → surface as questions
- [ ] Write structured output to ACTIVE_TASK.md → ## Requirement
- [ ] Append Observation block
- [ ] Next: run `init` (new project) or `design` (existing project)

## Example

**Input:**
```
Users report that the search endpoint times out on large datasets.
It was fine last week. We added a new feature that does bulk upserts.
Probably that broke something?
```

**Output (written to ACTIVE_TASK.md → ## Requirement):**
```json
{
  "type": "bugfix",
  "goal": "Restore search endpoint performance after bulk upsert feature introduction",
  "acceptanceCriteria": [
    "Search completes in < 500ms on dataset with 1M records",
    "No degradation from baseline (prior week performance)",
    "Bulk upsert feature still works correctly"
  ],
  "scope": {
    "inScope": ["search endpoint", "database queries", "indexing"],
    "outOfScope": ["search UI", "other endpoints"]
  },
  "constraints": { "timeline": "ASAP (prod impact)", "risk": "HIGH" },
  "successMetrics": [
    "Load test: 1M records searched in < 500ms",
    "No regression in bulk upsert tests"
  ],
  "questions": [
    "When did performance degrade? (exact timestamp?)",
    "Which bulk upsert query pattern is slowest?"
  ]
}
```

---

*Next: `init` (new project) or `design` (existing project).*
