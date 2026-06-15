---
name: verify
description: Verify — confirm all acceptance criteria are met with external evidence before code review. Use when the user says "verify this", "does it meet requirements?", "acceptance check", "are we done?", or after `coverage` closes all high-priority gaps. MANDATORY before `review` — verification must pass before any code review begins. Requires actual test run output and coverage numbers as evidence — self-reported "it should pass" is not sufficient.
---

# Verification

Confirm implementation satisfies every acceptance criterion: build a traceability matrix against actual test run evidence, run the full suite, and produce a pass/fail verdict before review.

## Principles in Play

**Agents declare victory too early.** Verify exists specifically to catch premature victory. It requires:
- Actual test runner output (not assumed or extrapolated)
- Actual coverage numbers from the coverage tool
- Each AC must map to a passing test with evidence — not just a test that exists

**End-to-end testing changes results.** Verify checks E2E test status separately. An AC with only unit tests passing is flagged as "partial coverage" — not PASS. PASS requires at least one E2E test green per AC.

**Feature lists are harness primitives.** Traceability matrix is built criterion-by-criterion from `## Requirement` acceptanceCriteria. Nothing is verified from design or assumed from implementation log — only from test evidence.

**Observability inside harness.** Observation block records the runner output hash and coverage number so `review` can verify the evidence is fresh and complete.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement` and `## Test Results`
Writes: appends traceability matrix + verdict to `ACTIVE_TASK.md → ## Test Results`

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

**Hard block:** If `## Test Results` is empty:
> "Run `tests` first. Output required in ACTIVE_TASK.md → ## Test Results."

**Hard block:** If `## Test Results` Observation block is missing or `done-signal` is not `coverage-report`:
> "Coverage analysis not completed with tool evidence. Run `coverage` to produce a verified coverage report before verifying."

## Meta-Prompt

Self-inject from `## Requirement` (acceptanceCriteria, successMetrics) and `## Test Results` (plan, coverageAnalysis, runnerOutput, e2eCoverage).

**Analyze:**
- Is every AC covered by at least one passing unit test?
- Is every AC covered by at least one passing E2E test?
- Do success metrics have measurable evidence (coverage %, latency, error rate)?
- Are there criteria with skipped, pending, or failing tests?
- Does coverage meet the stated target?

**Generate:**
1. **Traceability matrix** — each AC → test(s) → unit status → E2E status → verdict
2. **Success metric evidence** — each metric with measured value from runner/tool
3. **Verdict** — PASS (all AC green including E2E, coverage met) or FAIL (list blockers)
4. **Blockers** — criteria not met, with required fix

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
const testResults = readActiveTask("## Test Results");
if (!requirement) hardBlock("task");
if (!testResults) hardBlock("tests");
if (!testResults.observations?.some(o => o.doneSig === "coverage-report")) {
  hardBlock("Coverage tool evidence missing. Run `coverage` first.");
}

// Run full test suite one more time — get fresh runner output
const fullSuiteRun = await runTests({ full: true });
const matrix = buildTraceabilityMatrix(requirement.acceptanceCriteria, testResults, fullSuiteRun);

// E2E check: each AC must have at least one E2E test passing
const e2eGaps = matrix.filter(row => row.e2eStatus !== "PASS");
if (e2eGaps.length > 0) {
  warn(`E2E coverage missing for: ${e2eGaps.map(r => r.criterion).join(", ")}. Required for PASS verdict.`);
}

const verdict = (matrix.every(r => r.verdict === "PASS") && testResults.coverage >= testResults.target && e2eGaps.length === 0)
  ? "PASS" : "FAIL";

appendToActiveTask("## Test Results", {
  traceabilityMatrix: matrix,
  fullSuiteRunOutput: fullSuiteRun.summary,
  coverageMeasured: testResults.coverage,
  e2eGaps,
  verdict
});
appendObservation("verify", {
  doneCriteria: "all AC in matrix, E2E status checked, runner output recorded, coverage verified",
  verdict
});
```

## Observation Block

Append after verification:

```
### Observation
- phase: testing/verify
- done-signal: test-run-output
- done-criteria: full suite ran, all AC in traceability matrix, E2E status per AC, coverage measured
- full-suite-run: PASS|FAIL
- coverage-measured: N%
- coverage-target: N%
- e2e-gaps: N (must be 0 for PASS)
- verdict: PASS|FAIL
- verdict-source: external-evidence (test runner + coverage tool)
```

## Trigger Points

- After `coverage` closes all high-priority gaps
- User says "verify this", "does it meet requirements?", "acceptance check"
- **Mandatory before `review`** — no code review without a PASS verdict here

## Output

Appends to `ACTIVE_TASK.md → ## Test Results`:
- Traceability matrix (criterion → unit test → E2E test → pass/fail)
- Success metric evidence with measured values
- PASS / FAIL verdict
- Blockers if FAIL

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## Test Results; hard block if empty
- [ ] Verify coverage Observation block present with `done-signal: coverage-report` — hard block if missing
- [ ] Run full test suite — capture actual runner output
- [ ] Build traceability matrix: every AC → test(s) → unit status → E2E status
- [ ] Verify each AC has at least one passing E2E test — flag gaps
- [ ] Measure each success metric (coverage %, latency if applicable)
- [ ] Flag any skipped or pending tests as unverified
- [ ] State verdict: PASS only if all AC green (including E2E) and coverage target met
- [ ] List blockers with recommended fix for any FAIL
- [ ] Append matrix + verdict + Observation block to ACTIVE_TASK.md → ## Test Results
- [ ] Next: run `review` (if PASS) or fix blockers and re-verify (if FAIL)

## Example

**Output (appended to ACTIVE_TASK.md → ## Test Results):**
```
### Verification — Traceability Matrix
| Criterion | Unit Test(s) | E2E Test | Unit | E2E | Verdict |
|-----------|-------------|----------|------|-----|---------|
| Email uniqueness | test_duplicate_email_raises_conflict | test_e2e_duplicate_email_409 | ✅ | ✅ | PASS |
| JWT expires 15min | test_expired_token_rejected | test_e2e_expired_token_401 | ✅ | ✅ | PASS |
| CRUD for users | test_create/read/update/delete | test_e2e_crud_cycle | ✅ | ✅ | PASS |

### Success Metric Evidence
| Metric | Target | Measured | Source | Status |
|--------|--------|----------|--------|--------|
| Coverage | ≥ 85% | 87% | pytest-cov run | ✅ |
| All tests pass | 0 failures | 0/18 fail | pytest run | ✅ |

### Verdict: ✅ PASS
All AC satisfied. E2E coverage complete. Coverage target met. Ready for code-review.
```

---

*Next: `review` (Review phase).*
