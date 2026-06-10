---
description: Refactor — structural cleanup without behavior change
phase: implementation
reads:
  - "## Implementation Log"
writes:
  - "## Implementation Log (append)"
hard_blocks:
  - condition: "## Implementation Log is empty"
    message: "Run `code` first. Output required in ACTIVE_TASK.md → ## Implementation Log."
---

# Refactor

Improve code structure, readability, and maintainability without changing external behavior — tests must stay green throughout.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Implementation Log`
Writes: appends refactor summary to `ACTIVE_TASK.md → ## Implementation Log`

**Hard block:** If `## Implementation Log` is empty:
> "Run `code` first. Output required in ACTIVE_TASK.md → ## Implementation Log."

## Agent Delegation

Spawn `sdlc-investigator` before analyzing for smells. The investigator scans the files from `## Implementation Log` and returns current symbol map + cross-file patterns. Use this to find duplication across files — duplication only visible by scanning multiple files simultaneously.

Pass as input: `"refactor"` (phase) and the `filesCreated` list from `## Implementation Log`.

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Implementation Log`: extract `filesCreated`, `status`, coverage entries. Merge with investigator symbol map.

**Analyze:**
- What duplication exists across files? (cross-file pattern from investigator)
- What functions are too long or carry multiple responsibilities?
- What naming is unclear or inconsistent?
- What abstractions are missing or over-engineered?
- Are there any dead code paths?

**Generate:**
1. **Refactor targets** — specific locations (file:function) with the smell and the fix
2. **Safe refactor sequence** — order changes so tests stay green at each step
3. **Post-refactor verification** — confirm test suite still passes after each change

## Pattern

```javascript
const implLog = readActiveTask("## Implementation Log");
if (!implLog) hardBlock("code");

// Pre-step: scan created files for symbols and cross-file patterns
const symbolMap = await agent("refactor — map symbols in: " + implLog.filesCreated.join(", "), {
  agentType: "sdlc-investigator",
  label: "investigate:pre-refactor"
});
// symbolMap: { files, symbols, patterns (duplication), gaps }

const targets = await agent(analysisMetaPrompt(implLog, symbolMap), { schema: REFACTOR_TARGETS_SCHEMA });
// Output: [{ file, function, smell, fix, risk }]

for (const target of targets) {
  await agent(refactorMetaPrompt(target), { schema: CODE_DELTA_SCHEMA });
  // Apply change, run tests, confirm green
}

appendToActiveTask("## Implementation Log", {
  refactorsApplied: targets.map(t => t.smell),
  testStatus: "all-green",
  nextStep: "tests"
});
```

## Trigger Points

- After `tdd` completes all acceptance criteria (green)
- User says "clean this up", "refactor", "simplify this code"
- Code review identifies structural issues before `review` phase
- Any time tests are green and structure needs improvement

## Output

Appends refactor summary to `ACTIVE_TASK.md → ## Implementation Log`:
- Refactors applied (smell → fix, file:line)
- Test status post-refactor
- Files changed

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Implementation Log; hard block if empty
- [ ] Run test suite first — confirm baseline green before touching anything
- [ ] Spawn `sdlc-investigator` (pass: "refactor", filesCreated from ## Implementation Log)
- [ ] Use investigator PATTERNS output to identify cross-file duplication
- [ ] Use investigator SYMBOLS output to find overloaded / misnamed functions
- [ ] Identify refactor targets: duplication, long functions, unclear naming, dead code
- [ ] Order changes: safe sequence (tests green at each step)
- [ ] Apply each refactor; run tests after each change
- [ ] Confirm full suite still green after all changes
- [ ] Append refactor summary to ACTIVE_TASK.md → ## Implementation Log
- [ ] Next: run `tests`

## Example

**Input (from ACTIVE_TASK.md → ## Implementation Log):**
```
filesCreated: [src/services/user.py, src/services/auth.py, ...]
TDD status: all criteria green
Coverage: 81%
```

**Output (appended to ACTIVE_TASK.md → ## Implementation Log):**
```
### Refactor — 2024-01-15
Targets:
- src/services/user.py:create_user — extracted email validation to _validate_email() (long function smell)
- src/repositories/user.py — removed duplicate get_by_id calls (DRY violation)
- src/routers/users.py — renamed `usr` → `user` in handler args (clarity)
Dead code removed: src/services/user.py:_legacy_hash (unreachable)
Test status: ✅ all 14 tests green post-refactor
Files changed: services/user.py, repositories/user.py, routers/users.py
```

---

*Next: `tests` (Testing phase).*
