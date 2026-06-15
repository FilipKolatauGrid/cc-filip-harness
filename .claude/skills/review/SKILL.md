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

Reads: `ACTIVE_TASK.md` → `## Test Results` and current git diff
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

```javascript
const testResults = readActiveTask("## Test Results");
if (!testResults) hardBlock("tests");
if (!verificationPassed(testResults)) hardBlock("verify — PASS required");

// Check evidence source
const verifyObs = getObservation(testResults, "verify");
if (!verifyObs || verifyObs.verdictSource !== "external-evidence") {
  hardBlock("Verify observation missing or self-reported. Re-run verify with actual test execution.");
}

// Parallel: code review + secrets/compliance scan
const [reviewOutput, secopsOutput] = await parallel([
  () => agent("review — correctness, design alignment, test quality, AC coverage", {
    agentType: "sdlc-reviewer",
    label: "review:diff"
  }),
  () => agent("review — secrets, vuln patterns, compliance drift", {
    agentType: "sdlc-secops",
    label: "secops:review"
  })
]);

const merged = mergeFindings(reviewOutput, secopsOutput);
const verdict = worstVerdict(reviewOutput.verdict, secopsOutput.verdict);

writeActiveTask("## Review Findings", { ...merged, verdict });
appendObservation("review", { doneCriteria: "both agents ran, findings merged, verdict determined" });
```

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
