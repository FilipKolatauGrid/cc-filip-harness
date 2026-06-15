---
name: refactor
description: Structural cleanup — improve code structure, readability, and maintainability without changing external behavior. Tests must stay green throughout. Use when the user says "clean this up", "refactor", "simplify this code", or after `tdd` completes all acceptance criteria. Spawns `sdlc-investigator` to find cross-file duplication. Hard-blocks if implementation log is missing. Does NOT run if tests are not currently green — run tests first, fix failures, then refactor.
---

# Refactor

Improve code structure, readability, and maintainability without changing external behavior — tests must stay green throughout.

## Principles in Play

**Agents declare victory too early.** Refactor never self-certifies "tests still pass". It runs the actual test suite before and after each change, records the runner output, and hard-stops if any change turns the suite red.

**Agents overreach and under-finish.** Spawns `sdlc-investigator` to find cross-file duplication — duplication only visible across multiple files simultaneously. No investigator = no cross-file scope.

**Observability inside harness.** Observation block records actual test-suite runner output before and after refactor, proving behavior was preserved.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Implementation Log`
Writes: appends refactor summary to `ACTIVE_TASK.md → ## Implementation Log`

**Hard block:** If `## Implementation Log` is empty:
> "Run `code` first. Output required in ACTIVE_TASK.md → ## Implementation Log."

**Hard block:** Run test suite before starting. If any tests fail:
> "Tests are not green. Fix failing tests before refactoring. Refactoring on a red suite risks masking failures."

## Agent Delegation

Spawn `sdlc-investigator` before analyzing. Pass `"refactor"` (phase) and the `filesCreated` list from `## Implementation Log`.

Investigator returns current symbol map + cross-file patterns. Use to find:
- Duplication across files (invisible from single-file view)
- Overloaded or misnamed functions
- Dead code paths

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Implementation Log`: extract `filesCreated`, `status`, TDD coverage entries. Merge with investigator symbol map.

**Analyze:**
- What duplication exists across files?
- What functions are too long or carry multiple responsibilities?
- What naming is unclear or inconsistent?
- What abstractions are missing or over-engineered?
- Are there any dead code paths?

**Generate:**
1. **Refactor targets** — specific locations (file:function) with the smell and the fix
2. **Safe refactor sequence** — order changes so tests stay green at each step
3. **Post-refactor verification** — runner output confirming green after each change

## Pattern

```javascript
const implLog = readActiveTask("## Implementation Log");
if (!implLog) hardBlock("code");

// Baseline: must be green before touching anything
const baseline = await runTests();
if (baseline.status !== "PASS") hardBlock("Tests not green. Fix failures before refactoring.");

const symbolMap = await agent("refactor — map symbols in: " + implLog.filesCreated.join(", "), {
  agentType: "sdlc-investigator",
  label: "investigate:pre-refactor"
});

const targets = await agent(analysisMetaPrompt(implLog, symbolMap), { schema: REFACTOR_TARGETS_SCHEMA });

for (const target of targets) {
  await agent(refactorMetaPrompt(target), { schema: CODE_DELTA_SCHEMA });
  const result = await runTests();
  if (result.status !== "PASS") {
    hardStop(`Refactor of ${target.file}:${target.function} broke tests. Revert and fix before continuing.`);
  }
}

appendToActiveTask("## Implementation Log", {
  refactorsApplied: targets.map(t => ({ smell: t.smell, fix: t.fix, file: t.file })),
  baselineTestOutput: baseline.summary,
  postRefactorTestOutput: (await runTests()).summary,
  testStatus: "all-green"
});
appendObservation("refactor", { doneCriteria: "all refactor targets applied, tests green before and after" });
```

## Observation Block

Append after all refactors applied:

```
### Observation
- phase: implementation/refactor
- done-signal: test-run-output
- done-criteria: tests green before refactor, tests green after each change, no TODO introduced
- baseline-test-status: PASS
- post-refactor-test-status: PASS
- files-touched: [list]
- verdict-source: external-evidence (test runner)
```

## Trigger Points

- After `tdd` completes all acceptance criteria (green)
- User says "clean this up", "refactor", "simplify this code"
- Code review identifies structural issues before `review` phase

## Output

Appends refactor summary to `ACTIVE_TASK.md → ## Implementation Log`:
- Refactors applied (smell → fix, file:location)
- Baseline test status (before)
- Post-refactor test status (after)
- Files changed

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Implementation Log; hard block if empty
- [ ] Run test suite — hard block if not green (don't refactor a red suite)
- [ ] Spawn `sdlc-investigator` (pass: "refactor", filesCreated from ## Implementation Log)
- [ ] Use investigator PATTERNS output to identify cross-file duplication
- [ ] Use investigator SYMBOLS output to find overloaded / misnamed functions
- [ ] Identify refactor targets: duplication, long functions, unclear naming, dead code
- [ ] Order changes: safe sequence (tests green at each step)
- [ ] Apply each refactor; run tests after each change — hard-stop if any step turns red
- [ ] Confirm full suite green after all changes
- [ ] Append refactor summary + Observation block to ACTIVE_TASK.md → ## Implementation Log
- [ ] Next: run `tests`

---

*Next: `tests` (Testing phase).*
