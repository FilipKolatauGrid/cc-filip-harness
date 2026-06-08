# TDD

Drive implementation quality by writing failing tests first, then making them pass — one acceptance criterion at a time.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement` and `## Implementation Log`
Writes: appends test + implementation entries to `ACTIVE_TASK.md → ## Implementation Log`

**Hard block:** If `## Requirement` is empty:
> "Run `capture-requirements` first. Output required in ACTIVE_TASK.md → ## Requirement."

**Hard block:** If `## Implementation Log` is empty:
> "Run `code-gen` first. Output required in ACTIVE_TASK.md → ## Implementation Log."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Requirement` (acceptanceCriteria) and `## Implementation Log` (filesCreated, status).

**Analyze:**
- Which acceptance criteria lack test coverage?
- What is the simplest failing test for each criterion?
- What test doubles (mocks, stubs, fakes) are needed?
- What edge cases does each criterion imply?

**Generate per criterion:**
1. **Failing test** — minimal test that expresses the criterion, runs red
2. **Implementation delta** — minimal code change to make the test pass
3. **Refactor pass** — clean up without changing behavior
4. **Repeat** — next criterion

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
const implLog = readActiveTask("## Implementation Log");
if (!requirement) hardBlock("capture-requirements");
if (!implLog) hardBlock("code-gen");

const criteria = extractAcceptanceCriteria(requirement);

for (const criterion of criteria) {
  // Red: write failing test
  await agent(testMetaPrompt(criterion, implLog), { schema: TEST_SCHEMA });
  // Green: minimal implementation change
  await agent(implMetaPrompt(criterion), { schema: IMPL_DELTA_SCHEMA });
  // Refactor: clean up
  await agent(refactorMetaPrompt(), { schema: REFACTOR_SCHEMA });

  appendToActiveTask("## Implementation Log", {
    criterion, testFile, status: "green", coverage: "..."
  });
}
```

## Trigger Points

- After `code-gen` creates initial implementation
- User says "write tests", "test this", "TDD this criterion"
- Any acceptance criterion lacks a corresponding test

## Output

Appends per-criterion entries to `ACTIVE_TASK.md → ## Implementation Log`:
- Criterion tested
- Test file path
- Status (red → green)
- Coverage delta

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## Implementation Log; hard block if empty
- [ ] List acceptance criteria not yet covered by tests
- [ ] For each criterion: write failing test first (red)
- [ ] Make minimal implementation change to pass test (green)
- [ ] Refactor without breaking tests
- [ ] Run full test suite — confirm all pass
- [ ] Append per-criterion log entries to ACTIVE_TASK.md → ## Implementation Log
- [ ] Next: run `refactor` or `test-design`

## Example

**Input (from ACTIVE_TASK.md → ## Requirement + ## Implementation Log):**
```
acceptanceCriteria: ["Email uniqueness enforced", "Verification link expires after 24 hours"]
Implementation Log: files created [src/models/user.py, src/services/user.py, ...]
```

**Output (appended to ACTIVE_TASK.md → ## Implementation Log):**
```
### TDD — Criterion: Email uniqueness enforced
Test: tests/test_user_service.py::test_duplicate_email_raises_conflict
Red: AssertionError — no conflict raised
Delta: UserService.create_user checks existing email, raises 409
Green: ✅ test passes
Coverage: +3% (services/user.py: 78% → 81%)

### TDD — Criterion: Verification link expires after 24 hours
Test: tests/test_auth_service.py::test_expired_token_rejected
Red: AssertionError — expired token accepted
Delta: AuthService.verify_token checks exp claim against now()
Green: ✅ test passes
Coverage: +2% (services/auth.py: 71% → 73%)
```

---

*Next: `refactor` or `test-design` (Testing phase).*
