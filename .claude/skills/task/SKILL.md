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
Writes: `ACTIVE_TASK.md` → `## Requirement` (three sub-blocks in order):

1. `### Initial Request` — verbatim user input, unmodified
2. `### Structured Requirement` — parsed schema (type, goal, AC, scope, constraints, metrics)
3. `### Clarification Outcomes` — decisions from the grill Q&A session (appended after session completes)

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
7. **Clarification Gaps** — requirement-level ambiguities that block DoR/DoD completeness (NOT technical or implementation choices — those go to design/grill)

## Clarification Session (Grill-Style)

After writing the initial structured requirement, identify any DoR/DoD gaps and ask them **one at a time** using this format — never batch:

```
**Clarification [N/total]: [Gap Title]**

[1-2 sentences — why this matters for requirement completeness]

Options:
  1. [Option] — [one-line description]
     Pros: [key strengths]
     Cons: [key weaknesses]

  2. [Option] — [one-line description]
     Pros: [key strengths]
     Cons: [key weaknesses]

★ Recommendation: Option [N] — [reason]

Reply with the option number, or describe a custom answer.
```

**STOP after each question. Wait for the developer's answer before proceeding.**
After each answer: acknowledge in one line, move to next immediately.
After all gaps resolved: append `### Clarification Outcomes` block to `## Requirement`, then append Observation block.

### DoR/DoD Scope — Allowed vs Forbidden

| Allowed (requirement-level)                                     | Forbidden (belongs to design/grill)   |
| --------------------------------------------------------------- | ------------------------------------- |
| Who is the end user / consumer of this feature?                 | Which database/store to use?          |
| What does "done" look like? How verified?                       | Which library or framework?           |
| Are there any hard deadlines or SLAs?                           | Error handling strategy?              |
| Which existing systems does this integrate with?                | API design or schema shape?           |
| Are there compliance or regulatory constraints?                 | Retry/fallback policies?              |
| What's the acceptable failure behavior from user's perspective? | Deployment or infrastructure choices? |

If a gap is technical/implementation, **skip it** — do not ask. It will be handled by design/grill.

## Pattern

```
// 1. Check latest task-log for ## Deferred; if non-empty prompt "Inherit N deferred issues as AC candidates? (y/n)"
// 2. Guard: warn if ## Requirement already populated (don't silently overwrite)
// 3. Write ### Initial Request block → verbatim user input, unmodified
// 4. Parse input; generate structured schema (type, goal, AC, scope, constraints, metrics)
// 5. Write ### Structured Requirement block → parsed schema
// 6. Identify DoR/DoD gaps (requirement-level only — NOT technical choices)
// 7. If gaps exist: ask one at a time in grill format; STOP after each; wait for answer
// 8. After all answers: write ### Clarification Outcomes block → each Q&A decision recorded
// 9. Append Observation block
```

## Observation Block

Append after all three sub-blocks are written:

```
### Observation
- phase: intake/task
- done-signal: schema-populated
- done-criteria: acceptanceCriteria non-empty, scope defined, successMetrics measurable, clarification-outcomes present (or 0 gaps found)
- clarifications-asked: N
- verdict-source: self-reported
```

## Trigger Points

- User starts new session with a task description
- User says "new task", "/task", "I want to build X", "there's a bug with Y"
- Team member files an issue that needs structuring
- Entry point — always first

## Output

Writes three sub-blocks to `ACTIVE_TASK.md → ## Requirement`:

- `### Initial Request` — verbatim user input (unchanged, no parsing)
- `### Structured Requirement` — parsed schema: type, goal, AC, scope, constraints, success metrics
- `### Clarification Outcomes` — one entry per Q&A decision: question asked + developer's answer + impact on requirement

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
- [ ] Write `### Initial Request` block — verbatim user input, no edits
- [ ] Parse input: extract task type, goal, AC, scope, constraints, success metrics
- [ ] Write `### Structured Requirement` block — parsed schema
- [ ] Identify DoR/DoD gaps (requirement-level only — skip anything technical/ADR)
- [ ] For each gap: ask one at a time in grill format; STOP; wait for answer; acknowledge; next
- [ ] Write `### Clarification Outcomes` block — each decision: question + answer + requirement impact
- [ ] Append Observation block (clarifications-asked: N)
- [ ] Next: run `init` (new project) or `design` (existing project)

## Example

**Input:**

```
Users report that the search endpoint times out on large datasets.
It was fine last week. We added a new feature that does bulk upserts.
Probably that broke something?
```

**Output (written to ACTIVE_TASK.md → ## Requirement):**

### Initial Request

```
Users report that the search endpoint times out on large datasets.
It was fine last week. We added a new feature that does bulk upserts.
Probably that broke something?
```

### Structured Requirement

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
  ]
}
```

### Clarification Outcomes

```
1. Q: Is this customer-facing (SLA breach) or internal tooling?
   A: Customer-facing — SLA is 500ms P99
   Impact: Added P99 threshold to AC; timeline set to ASAP

2. Q: Should bulk upsert be preserved as-is or is rollback acceptable if it's the root cause?
   A: Preserve bulk upsert — fix the search side
   Impact: Scope locked to search/indexing; bulk upsert explicitly out of scope for changes
```

---

_Next: `init` (new project) or `design` (existing project)._
