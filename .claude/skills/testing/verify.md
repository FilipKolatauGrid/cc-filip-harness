# Verification

Confirm implementation satisfies every acceptance criterion: build a traceability matrix, run the full suite, and produce a pass/fail verdict before review.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement` and `## Test Results`
Writes: appends traceability matrix + verdict to `ACTIVE_TASK.md → ## Test Results`

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

**Hard block:** If `## Test Results` is empty:
> "Run `tests` first. Output required in ACTIVE_TASK.md → ## Test Results."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Requirement` (acceptanceCriteria, successMetrics) and `## Test Results` (plan, coverageAnalysis).

**Analyze:**
- Is every acceptance criterion covered by at least one passing test?
- Do success metrics have measurable evidence (coverage %, latency, error rate)?
- Are there criteria with tests that are skipped, pending, or failing?
- Does coverage meet the stated target?

**Generate:**
1. **Traceability matrix** — each criterion → test(s) → status (pass/fail/missing)
2. **Success metric evidence** — each metric with measured value
3. **Verdict** — PASS (all criteria green, coverage met) or FAIL (list blockers)
4. **Blockers** — criteria not met, with recommended fix

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
const testResults = readActiveTask("## Test Results");
if (!requirement) hardBlock("task");
if (!testResults) hardBlock("tests");

const matrix = await agent(enrichedMetaPrompt, { schema: VERIFICATION_SCHEMA });
// Output: { matrix: [...], metrics: [...], verdict: "PASS"|"FAIL", blockers: [...] }

appendToActiveTask("## Test Results", { verification: matrix });
```

## Trigger Points

- After `coverage` closes all high-priority gaps
- User says "verify this", "does it meet requirements?", "acceptance check"
- Before `review` — verification must pass before review phase

## Output

Appends to `ACTIVE_TASK.md → ## Test Results`:
- Traceability matrix (criterion → test → status)
- Success metric evidence
- PASS / FAIL verdict
- Blockers if FAIL

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## Test Results; hard block if empty
- [ ] Build traceability matrix: every criterion → test(s) → pass/fail/missing
- [ ] Measure each success metric (run suite, check coverage report, latency if applicable)
- [ ] Flag any skipped or pending tests as unverified
- [ ] State verdict: PASS only if all criteria green and coverage target met
- [ ] List blockers with recommended fix for any FAIL
- [ ] Append matrix + verdict to ACTIVE_TASK.md → ## Test Results
- [ ] Next: run `review` (if PASS) or fix blockers and re-verify (if FAIL)

## Example

**Input (from ACTIVE_TASK.md → ## Requirement + ## Test Results):**
```
acceptanceCriteria: ["Email uniqueness enforced", "JWT expires in 15min", "CRUD for users"]
successMetrics: ["Coverage >= 85%", "Search < 500ms"]
Coverage Analysis: 87% overall, all gaps closed
```

**Output (appended to ACTIVE_TASK.md → ## Test Results):**
```
### Verification — Traceability Matrix
| Criterion | Test(s) | Status |
|-----------|---------|--------|
| Email uniqueness enforced | test_duplicate_email_raises_conflict, test_duplicate_email_db_constraint | ✅ PASS |
| JWT expires in 15min | test_expired_token_rejected, test_wrong_password_returns_401 | ✅ PASS |
| CRUD for users | test_create_user, test_get_user, test_update_user, test_delete_user | ✅ PASS |

### Success Metric Evidence
| Metric | Target | Measured | Status |
|--------|--------|----------|--------|
| Coverage | ≥ 85% | 87% | ✅ |
| All tests pass | 0 failures | 0 failures (18/18) | ✅ |

### Verdict: ✅ PASS
All acceptance criteria satisfied. Coverage target met. Ready for code-review.
```

---

*Next: `review` (Review phase).*
