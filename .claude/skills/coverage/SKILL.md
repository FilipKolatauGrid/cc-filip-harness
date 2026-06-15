---
name: coverage
description: Coverage analysis — measure actual test coverage, find gaps against the test plan and target, and produce prioritized missing test specs. Use when the user says "check coverage", "what's not tested?", "coverage gaps", "are we hitting the target?", or after `tests` writes the test plan. Runs the actual coverage tool — does not estimate. Hard-blocks if test results section is missing.
---

# Coverage Analysis

Measure actual test coverage, identify gaps against the test plan and coverage target, and produce a prioritized list of missing tests.

## Principles in Play

**End-to-end testing changes results.** Coverage analysis must check E2E coverage separately from unit/integration coverage. A line covered by a unit test but not by any E2E test is a partial coverage — surface it.

**Agents declare victory too early.** Coverage is measured by running the actual coverage tool — not estimated from code reading or assumed from TDD log entries. No runner output = no coverage verdict.

**Observability inside harness.** Coverage Observation block records the actual tool invocation output and the resulting numbers, so `verify` can cross-check rather than trust a self-reported number.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Test Results`
Writes: appends gap analysis to `ACTIVE_TASK.md → ## Test Results`

**Hard block:** If `## Test Results` is empty:
> "Run `tests` first. Output required in ACTIVE_TASK.md → ## Test Results."

**Hard block:** If `## Test Results` Observation block shows `done-signal: agent-declared` without schema-populated:
> "Test plan shows no completion evidence. Re-run `tests` before analyzing coverage."

## Meta-Prompt

Self-inject from `## Test Results`: extract `plan`, `coverageTarget`, `e2eScenarios`, `executionOrder`.

**Analyze:**
- What is the current measured coverage per file/module (from runner)?
- Which files are below the coverage target?
- Which AC scenarios from the test plan have no corresponding test?
- Which E2E scenarios from the test plan are untested?
- What are the highest-risk uncovered paths?

**Generate:**
1. **Coverage report** — per-file percentages from actual runner output
2. **E2E coverage check** — which AC have E2E tests, which don't
3. **Gap list** — untested scenarios and edge cases, prioritized by risk
4. **Missing test specs** — concrete test descriptions for each gap
5. **Verdict** — meets target / below target + delta needed

## Pattern

```javascript
const testResults = readActiveTask("## Test Results");
if (!testResults) hardBlock("tests");

// Run actual coverage tool
const coverageData = await runCoverageTool(); // pytest --cov, jest --coverage, go test -cover
if (!coverageData.rawOutput) hardStop("Coverage tool returned no output. Check test runner configuration.");

// Check E2E coverage separately
const e2eCoverage = checkE2EScenarios(testResults.plan.e2eScenarios);
const analysis = await agent(enrichedMetaPrompt(coverageData, testResults), { schema: COVERAGE_ANALYSIS_SCHEMA });

appendToActiveTask("## Test Results", {
  coverageAnalysis: analysis,
  runnerOutput: coverageData.rawOutput,
  e2eCoverage: e2eCoverage
});
appendObservation("coverage", {
  doneCriteria: "coverage tool ran, per-file report present, E2E gaps identified, verdict vs target stated"
});
```

## Observation Block

Append after writing coverage analysis:

```
### Observation
- phase: testing/coverage
- done-signal: coverage-report
- done-criteria: runner output captured, per-file %, E2E coverage checked, verdict vs target
- overall-coverage: N%
- coverage-target: N%
- target-met: true|false
- e2e-scenarios-covered: N/N
- verdict-source: external-evidence (coverage tool)
```

## Trigger Points

- After `tests` writes the test plan
- User says "check coverage", "what's not tested?", "coverage gaps"
- Before `verify`

## Output

Appends to `ACTIVE_TASK.md → ## Test Results`:
- Per-file coverage table (from runner)
- E2E coverage check
- Prioritized gap list with missing test specs
- Verdict vs. coverage target

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Test Results; hard block if empty or missing Observation
- [ ] Run coverage tool for the stack (pytest --cov, jest --coverage, go test -cover, etc.)
- [ ] Capture raw runner output — no output = hard stop
- [ ] Compare per-file coverage against target
- [ ] Check E2E coverage: which AC have E2E tests passing
- [ ] Map untested lines to AC and edge cases from the test plan
- [ ] Prioritize gaps by risk (auth paths > business logic > edge cases)
- [ ] Write concrete missing test specs for each gap
- [ ] State verdict: meets target or delta needed
- [ ] Append coverage analysis + runner output + Observation block to ACTIVE_TASK.md → ## Test Results
- [ ] Next: run `verify`

---

*Next: `verify` (Testing phase).*
