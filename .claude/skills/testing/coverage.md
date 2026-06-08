# Coverage Analysis

Measure actual test coverage, identify gaps against the test plan and coverage target, and produce a prioritized list of missing tests.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Test Results`
Writes: appends gap analysis to `ACTIVE_TASK.md → ## Test Results`

**Hard block:** If `## Test Results` is empty:
> "Run `tests` first. Output required in ACTIVE_TASK.md → ## Test Results."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Test Results`: extract `plan`, `coverageTarget`, `executionOrder`.

**Analyze:**
- What is the current measured coverage per file/module?
- Which files are below the coverage target?
- Which acceptance criteria scenarios from the test plan have no corresponding test?
- Which edge cases from the test plan are untested?
- What are the highest-risk uncovered paths?

**Generate:**
1. **Coverage report** — per-file/module coverage percentages
2. **Gap list** — untested scenarios and edge cases from the plan, prioritized by risk
3. **Missing test specs** — concrete test descriptions to write for each gap
4. **Verdict** — meets target / below target + delta needed

## Pattern

```javascript
const testResults = readActiveTask("## Test Results");
if (!testResults) hardBlock("tests");

// Run coverage tool for the stack
const coverageData = await runCoverageTool(); // e.g. pytest --cov, jest --coverage

const analysis = await agent(enrichedMetaPrompt(coverageData, testResults), {
  schema: COVERAGE_ANALYSIS_SCHEMA
});
// Output: { perFile: [...], gaps: [...], missingTests: [...], verdict }

appendToActiveTask("## Test Results", { coverageAnalysis: analysis });
```

## Trigger Points

- After `tests` writes the test plan
- User says "check coverage", "what's not tested?", "coverage gaps"
- Before `verify`

## Output

Appends to `ACTIVE_TASK.md → ## Test Results`:
- Per-file coverage table
- Prioritized gap list with missing test specs
- Verdict vs. coverage target

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Test Results; hard block if empty
- [ ] Run coverage tool appropriate for the stack (pytest --cov, jest --coverage, go test -cover, etc.)
- [ ] Compare per-file coverage against target
- [ ] Map untested lines to acceptance criteria and edge cases from the test plan
- [ ] Prioritize gaps by risk (auth paths > happy paths > edge cases)
- [ ] Write concrete missing test specs for each gap
- [ ] State verdict: meets target or delta needed
- [ ] Append gap analysis to ACTIVE_TASK.md → ## Test Results
- [ ] Next: run `verify`

## Example

**Input (from ACTIVE_TASK.md → ## Test Results):**
```
Test Plan: 5 scenarios, 4 edge cases
Coverage Target: 85%
Execution Order: unit → integration → e2e
```

**Output (appended to ACTIVE_TASK.md → ## Test Results):**
```
### Coverage Analysis
| File | Coverage | Status |
|------|----------|--------|
| src/services/user.py | 91% | ✅ |
| src/services/auth.py | 78% | ❌ below target |
| src/repositories/user.py | 95% | ✅ |
| src/routers/users.py | 83% | ❌ below target |
| src/routers/auth.py | 70% | ❌ below target |
Overall: 83% — 2% below 85% target

### Gaps (prioritized by risk)
1. [HIGH] auth.py:verify_token — malformed token input path uncovered
   Missing test: test_malformed_token_returns_401
2. [HIGH] routers/auth.py — POST /auth/token with wrong password not tested
   Missing test: test_wrong_password_returns_401
3. [MEDIUM] routers/users.py — PUT /users/{id} with partial body not tested
   Missing test: test_partial_update_returns_200
4. [LOW] services/user.py — _validate_email with unicode chars
   Missing test: test_unicode_email_rejected

### Verdict
Below target: 83% actual vs. 85% target. Write 4 missing tests to close gap.
```

---

*Next: `verify` (Testing phase).*
