---
name: review
description: Code review — review diff against task acceptance criteria, design contracts, and test results. Use when the user says "review this", "code review", "/code-review", "check the diff", or after `verify` returns a PASS verdict. Spawns `sdlc-reviewer` + `sdlc-secops` in parallel. Hard-blocks if verification has not passed — verification MUST produce a PASS verdict before any code review begins. The reviewer is an external agent, not the implementor — this is intentional.
---

# Code Review

Review the implementation diff for correctness, design alignment, test quality, and maintainability — one finding per line, severity-tagged.

## Principles in Play

**Agents declare victory too early.** Review hard-blocks on missing verify verdict. A PASS from `verify` is required — not just a populated `## Test Results` section. Evidence must exist before review gates can open.

**Observability inside harness.** Review reads the verify Observation block to confirm evidence is present (test-run-output, external-evidence) before spawning reviewers. If `verify` Observation shows `verdict-source: self-reported`, review blocks.

**Why end-to-end testing changes results.** Review checks: did `verify` confirm E2E coverage? A review approved on unit-only coverage has a known gap — surface it explicitly.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Test Results` (stop at next `##`) and `## Requirement` (stop at next `##`). Do NOT read full ACTIVE_TASK.md.
Also reads: `## Design` → `apiContracts` field only (for reviewer context extraction).
Also reads: current git diff.
Writes: `ACTIVE_TASK.md` → `## Review Findings`

**Hard block:** If `## Test Results` is empty:
> "Run `tests` first. Output required in ACTIVE_TASK.md → ## Test Results."

**Hard block:** If `## Test Results` does not contain a PASS verdict from `verify`:
> "Verification must pass before code review. Fix blockers in ## Test Results first."

**Hard block:** If verify Observation block `verdict-source` is `self-reported` (not `external-evidence`):
> "Verify produced a self-reported verdict — no test runner evidence. Re-run `verify` with actual test suite execution."

## Agent Delegation

Spawn `sdlc-reviewer` AND `sdlc-secops` in **parallel** — both read the same diff independently.

- `sdlc-reviewer` → correctness, design alignment, test quality, AC check
- `sdlc-secops` → secrets, dangerous patterns, compliance drift

Merge both outputs. Take worst verdict.

## Pattern

```
// 1. Hard-block: Test Results empty, no PASS verdict, verify verdict-source self-reported
// 2. Extract reviewer context: { diff, AC from ##Requirement, apiContracts from ##Design only }
// 3. Parallel spawn: sdlc-reviewer(reviewerContext) + sdlc-secops(full diff)
// 4. Merge findings; take worst verdict; flag MEDIUM items as deferred candidates
// 5. Write ## Review Findings + Observation block
```

## Reviewer Context Extraction

Before spawning `sdlc-reviewer`, extract only what it needs — do NOT pass full ACTIVE_TASK.md:

```
reviewerContext = {
  diff: git diff main...HEAD,
  acceptanceCriteria: readSection("## Requirement").acceptanceCriteria,
  apiContracts: readSection("## Design").apiContracts
}
```

`sdlc-secops` receives the full diff only (no ACTIVE_TASK sections needed for pattern scan).

**MEDIUM findings:** In the findings list, tag any MEDIUM item not fixed inline as `[deferred]`. `close` will collect these for the task-log `## Deferred` section.

## Observation Block

Append after writing `## Review Findings`:

```
### Observation
- phase: review/review
- done-signal: diff-reviewed
- done-criteria: sdlc-reviewer + sdlc-secops both ran, findings merged, verdict set
- verify-evidence-confirmed: true
- e2e-coverage-confirmed: true|false
- verdict: APPROVED|APPROVED_WITH_CHANGES|BLOCKED
- verdict-source: external-evidence (reviewer + secops agents)
```

## Severity Mapping

- `🔴 CRITICAL` / SECRET → must resolve before merge
- `🟠 HIGH` → must resolve before merge
- `🟡 MEDIUM` / COMPLIANCE → should resolve, not a blocker
- `🔵 LOW` → optional
- `🟣 SCOPE` → flag only

**Verdict (worst-of):**
- Either agent returns BLOCKED / CRITICAL_BLOCK → BLOCKED
- Both return PASS_WITH_NOTES / FINDINGS_REQUIRE_FIX → APPROVED_WITH_CHANGES
- Both return PASS / CLEAR → APPROVED

## Trigger Points

- After `verify` returns PASS verdict
- User says "review this", "code review"
- Before `audit` and `deploy`

## Output

Writes to `ACTIVE_TASK.md → ## Review Findings`:
- Findings list (path:line, severity, problem, fix)
- Overall verdict (APPROVED / APPROVED_WITH_CHANGES / BLOCKED)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Test Results; hard block if empty or no PASS verdict
- [ ] Check verify Observation block: `verdict-source` must be `external-evidence` — hard block if self-reported
- [ ] Confirm E2E coverage was checked in verify — note in findings if gaps exist
- [ ] Spawn `sdlc-reviewer` + `sdlc-secops` in parallel (same diff, independent agents)
- [ ] Wait for both agents to complete
- [ ] Merge findings: reviewer findings first, secops findings second
- [ ] Take worst verdict (BLOCKED beats everything)
- [ ] Map merged verdict to APPROVED / APPROVED_WITH_CHANGES / BLOCKED
- [ ] Write merged findings + verdict + Observation block to ACTIVE_TASK.md → ## Review Findings
- [ ] If BLOCKED: surface all CRITICAL + SECRET blockers before proceeding
- [ ] Next: run `audit`

---

*Next: `audit` (Review phase).*
