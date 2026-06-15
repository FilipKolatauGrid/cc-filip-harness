# Workflow: Bug Fix

Targeted fix cycle — reproduce, isolate, test-first fix, verify, review, close. No planning phase unless the fix requires architectural change.

This is a **routing-table reference doc**, not an auto-runner.

---

## Phase 0: Session Start

Check ACTIVE_TASK.md state before starting:
- Non-empty `## Requirement` from a different task → run `close` on prior task first.
- Partially populated `## Requirement` with type=bugfix → resume the existing bug fix.

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `task` | Entry point — type=bugfix; warns if ACTIVE_TASK already populated |

Set `type: bugfix` in ## Requirement. Include: reproduction steps, expected vs. actual behavior, affected version, stack layer ([FE]/[BE]).

**Gate:** ## Requirement populated with reproduction steps + stack layer.

---

## Phase 2: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 2 | `tdd` | Write failing test reproducing the bug FIRST (red-first, no impl yet) |
| 3 | `code` | Minimal fix — make the failing test pass |
| 4 | `refactor` *(optional)* | Only if fix introduces duplication or smell |

**TDD rule:** Failing test must reproduce the bug exactly before any fix code is written. No fix without a red test first. The TDD Observation block records runner output (red state) before code is written — this is the bug reproduction evidence.

**Architectural change?** If root cause requires design change → branch to `full-sdlc` from Phase 2 (Planning).

**Gate to Testing:** Failing test now green. Full suite passes. Observation block shows test-run-output evidence.

---

## Phase 3: Testing

| Step | Skill | Gate |
|------|-------|------|
| 5 | `verify` | Confirm bug criterion passes + no regression; requires test-run-output evidence |

No `tests` or `coverage` required unless coverage dropped below target (in which case: write missing tests before verify).

**Verify note:** For bug fixes, `verify` must confirm the bug reproduction test now passes AND no existing tests regressed. E2E test for the bug path is strongly recommended — bugs that resurface usually do so at integration points.

**Gate to Review:** ## Test Results PASS verdict with external-evidence Observation.

---

## Phase 4: Review

| Step | Skill | Gate |
|------|-------|------|
| 6 | `review` | ## Test Results PASS with external-evidence |
| 7 | `audit` | **Conditional** — required if fix touches auth, input handling, DB queries, file system, or external API calls |

`audit` is conditional — if triggered, audit Observation must show secops-scan signal before merge.

**Gate:** ## Review Findings populated. All CRITICAL resolved.

---

## Phase 5: Integration

| Step | Skill | Gate |
|------|-------|------|
| 8 | *(merge to branch)* | Review approved |
| 9 | `close` | Merged — archives [BUGFIX] task, updates context, resets ACTIVE_TASK.md |
| 10 | `ship` *(optional)* | If hotfix to prod |

**Task closed:** `task-log/YYYYMMDD-[BUGFIX]-slug.md` written. ACTIVE_TASK.md reset.

---

## Rollback Paths

| Situation | Action |
|-----------|--------|
| Fix introduces regression | Revert fix → re-analyze root cause → new failing test |
| Verification FAIL | Fix failing criterion → re-verify |
| Post-deploy regression | Execute rollback plan → root cause analysis before re-attempt |
| Observation block missing on verify | Re-run verify with actual test execution |

---

## Decision Points

- **Root cause requires design change:** stop → run `design` → full-sdlc Planning phase
- **Bug affects multiple layers (FE + BE):** run both context updates in `close`
- **Hotfix to prod:** run `deploy` before `close`
- **Coverage dropped below target:** run `tests` + `coverage` before `verify`
