# Workflow: Bug Fix

Targeted fix cycle — reproduce, isolate, test-first fix, verify, review, close. No planning phase unless the fix requires architectural change.

This is a **routing-table reference doc**, not an auto-runner.

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `capture-requirements` | Entry point — type=bugfix |

Set `type: bugfix` in ## Requirement. Include: reproduction steps, expected vs. actual behavior, affected version, stack layer ([FE]/[BE]).

**Gate:** ## Requirement populated with reproduction steps + stack layer.

---

## Phase 2: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 2 | `tdd` | Write failing test that reproduces the bug first |
| 3 | `code-gen` | Fix — minimal change to make failing test pass |
| 4 | `refactor` *(optional)* | Only if fix introduces duplication or smell |

**TDD rule:** The failing test must reproduce the bug exactly before any fix code is written. No fix without a red test first.

**Architectural change?** If root cause requires design change → branch to `full-sdlc` from Phase 2 (Planning).

**Gate to Testing:** Failing test now green. No regression in existing suite.

---

## Phase 3: Testing

| Step | Skill | Gate |
|------|-------|------|
| 5 | `verification` | Confirm bug criterion passes + no regression |

No `test-design` or `coverage-analysis` required unless coverage dropped below target.

**Gate to Review:** ## Test Results PASS verdict. Bug criterion green.

---

## Phase 4: Review

| Step | Skill | Gate |
|------|-------|------|
| 6 | `code-review` | ## Test Results PASS |
| 7 | `security-audit` | If fix touches auth, input handling, or data access |

`security-audit` is **conditional** — required if fix touches: auth flows, input validation, DB queries, file system access, external API calls.

**Gate:** ## Review Findings populated. All CRITICAL resolved.

---

## Phase 5: Integration

| Step | Skill | Gate |
|------|-------|------|
| 8 | *(merge to branch)* | Review approved |
| 9 | `close-task` | Merged — archives [BUGFIX] task, updates context, resets ACTIVE_TASK.md |
| 10 | `post-deploy` *(optional)* | If hotfix to prod |

**Task closed:** `task-log/YYYYMMDD-[BUGFIX]-slug.md` written. ACTIVE_TASK.md reset.

---

## Rollback Paths

| Situation | Action |
|-----------|--------|
| Fix introduces regression | Revert fix → re-analyze root cause → new failing test |
| Verification FAIL | Fix failing criterion → re-verify |
| Post-deploy regression | Execute rollback plan → root cause analysis before re-attempt |

---

## Decision Points

- **Root cause requires design change:** stop → run `architecture-design` → full-sdlc Planning phase
- **Bug affects multiple layers (FE + BE):** run both `FE_CONTEXT.md` and `BE_CONTEXT.md` updates in `close-task`
- **Hotfix to prod:** run `deploy-checklist` before `close-task`
