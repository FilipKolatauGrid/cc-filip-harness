---
name: tdd
description: Test-driven development — write failing tests first per acceptance criterion, then make them pass. Use when the user says "write tests", "test this", "TDD this criterion", "test-drive the implementation", or after `code` creates the initial implementation. For bug fixes, write the failing test that reproduces the bug before running `code` to fix it (red-first is correct for bugs). Hard-blocks if implementation log is missing (except in bugfix mode).
---

# TDD

Drive implementation quality by writing failing tests first, then making them pass — one acceptance criterion at a time.

**Bug-fix mode:** If `## Requirement type = bugfix`, the Implementation Log gate is relaxed. Write the failing test reproducing the bug first, then run `code` to fix it. Red-first is correct for bugs.

## Principles in Play

**Feature lists are harness primitives.** Tests are written against acceptance criteria from `## Requirement` — not against the implementation in `## Implementation Log`. Each test must reference which AC it satisfies.

**Agents declare victory too early.** Green status must come from actually running the test suite — not from code that looks correct. Log entries must record test file path, test name, and pass/fail from the runner — not just "should be green".

**End-to-end testing changes results.** For each acceptance criterion, at minimum one test must exercise the criterion end-to-end (through the full component stack), not just in isolation. Unit tests alone are insufficient for AC coverage.

**Observability inside harness.** Each TDD log entry records the criterion, test name, file path, and actual runner output — so `verify` can check evidence, not just trust the log.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement` and `## Implementation Log`
Writes: appends test + implementation entries to `ACTIVE_TASK.md → ## Implementation Log`

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

**Hard block:** If `## Implementation Log` is empty AND task type is not `bugfix`:
> "Run `code` first. Output required in ACTIVE_TASK.md → ## Implementation Log."

## Meta-Prompt

Self-inject from `## Requirement` (acceptanceCriteria) and `## Implementation Log` (filesCreated).

**Analyze:**
- Which acceptance criteria lack test coverage?
- What is the simplest failing test for each criterion?
- What test doubles are needed?
- What edge cases does each criterion imply?
- Which criteria need an E2E test (full component stack) vs. unit only?

**Generate per criterion:**
1. **Failing test** — minimal test that expresses the criterion, runs red
2. **E2E test** — one test that exercises the criterion through all layers
3. **Implementation delta** — minimal code change to make tests pass
4. **Refactor pass** — clean up without changing behavior
5. **Runner output** — actual pass/fail from test runner (not assumed)

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
const implLog = readActiveTask("## Implementation Log");
if (!requirement) hardBlock("task");
if (!implLog && requirement.type !== "bugfix") hardBlock("code");

const criteria = extractAcceptanceCriteria(requirement);

for (const criterion of criteria) {
  // Red: write failing test (unit + at least one E2E)
  await agent(testMetaPrompt(criterion, implLog), { schema: TEST_SCHEMA });
  // Run: confirm test actually fails (red)
  const redResult = await runTests(criterion.testFile);
  assert(redResult.status === "FAIL", "Test must start red — fix test if it passes without code changes");
  
  // Green: minimal implementation change
  await agent(implMetaPrompt(criterion), { schema: IMPL_DELTA_SCHEMA });
  // Run: confirm test passes (green)
  const greenResult = await runTests(criterion.testFile);
  
  // Refactor: clean up, re-run
  await agent(refactorMetaPrompt(), { schema: REFACTOR_SCHEMA });
  const postRefactorResult = await runTests();

  appendToActiveTask("## Implementation Log", {
    criterion,
    testFile: criterion.testFile,
    testNames: [criterion.unitTest, criterion.e2eTest],
    redOutput: redResult.summary,
    greenOutput: greenResult.summary,
    postRefactorOutput: postRefactorResult.summary,
    status: "green"
  });
}
appendObservation("tdd", { doneCriteria: "all AC have green tests with runner evidence, E2E test per AC" });
```

## Observation Block

Append after all criteria are green:

```
### Observation
- phase: implementation/tdd
- done-signal: test-run-output
- done-criteria: all AC covered, each has unit + E2E test, runner output recorded, full suite green
- ac-covered: N/N
- e2e-tests-count: N/N
- test-runner-evidence: [test file paths]
- verdict-source: external-evidence (test runner)
```

## Trigger Points

- After `code` creates initial implementation
- User says "write tests", "TDD this", "test-drive the implementation"
- Any acceptance criterion lacks a corresponding test
- Bug fix: write failing reproduction test before `code`

## Output

Appends per-criterion log entries to `ACTIVE_TASK.md → ## Implementation Log`:
- Criterion tested
- Test file path + test names (unit + E2E)
- Actual runner output (red → green)
- Coverage delta

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## Implementation Log; hard block if empty (except bugfix)
- [ ] List acceptance criteria not yet covered by tests
- [ ] For each criterion: write failing test first — actually run it, confirm red
- [ ] Write at least one E2E test per criterion (full component stack)
- [ ] Make minimal implementation change to pass tests — run and confirm green
- [ ] Refactor without breaking tests — run and confirm still green
- [ ] Record actual runner output (not assumed) in implementation log entry
- [ ] Append per-criterion entries + Observation block to ACTIVE_TASK.md → ## Implementation Log
- [ ] Next: run `refactor` or `tests`

---

*Next: `refactor` or `tests` (Testing phase).*
