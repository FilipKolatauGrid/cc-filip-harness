# Workflow: Feature Build

Streamlined feature cycle — planning through merge with optional risk-assessment for small features. Same gates as full-sdlc but lighter planning.

This is a **routing-table reference doc**, not an auto-runner.

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `task` | Entry point — type=feature |
| 2 | `init` *(if greenfield)* | Only for new projects |

**Gate:** ## Requirement populated with acceptanceCriteria, techStack, constraints.

---

## Phase 2: Planning

| Step | Skill | Gate | Required? |
|------|-------|------|-----------|
| 3 | `design` | ## Requirement populated | Always |
| 4 | `grill` | ## Design populated | Always |
| 5 | `risk` | ## Design + ## ADRs | **Optional** — skip for small/low-risk features |

**Small feature rule:** Skip `risk` if: single layer (FE-only or BE-only), no new external dependencies, no schema changes, timeline < 3 days.

**Gate to Implementation:** ## Design + ## ADRs populated. ## Risks optional.

---

## Phase 3: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 6 | `code` | ## Design populated |
| 7 | `tdd` | ## Implementation Log populated |
| 8 | `refactor` *(optional)* | TDD green, structural cleanup needed |

**Gate:** ## Implementation Log populated. All TDD criteria green.

---

## Phase 4: Testing

| Step | Skill | Gate |
|------|-------|------|
| 9 | `tests` | ## Requirement + ## Implementation Log |
| 10 | `coverage` | ## Test Results (plan) populated |
| 11 | `verify` | Gaps closed, coverage target met |

**Gate:** ## Test Results PASS verdict.

---

## Phase 5: Review

| Step | Skill | Gate |
|------|-------|------|
| 12 | `review` | ## Test Results PASS |
| 13 | `audit` | ## Review Findings populated |

**Gate:** ## Review Findings populated. All CRITICAL + HIGH resolved.

---

## Phase 6: Integration

| Step | Skill | Gate |
|------|-------|------|
| 14 | `deploy` *(if deploying)* | All findings resolved |
| 15 | *(merge to branch)* | Review approved |
| 16 | `close` | Merged — archives [FE]/[BE]/[FULLSTACK] task, updates context, resets ACTIVE_TASK.md |
| 17 | `ship` *(optional)* | If feature goes to prod this cycle |

**Task closed:** `task-log/YYYYMMDD-[TYPE]-slug.md` written. `.claude/context/` updated. ACTIVE_TASK.md reset.

---

## Rollback Paths

| Situation | Action |
|-----------|--------|
| decision-grill reveals fatal flaw in design | Re-run `design` with resolved constraints |
| Verification FAIL | Fix blockers → re-run `verify` |
| Review BLOCKED | Fix findings → re-run `review` |
| Post-deploy regression | Execute rollback from ## Deploy Checklist |

---

## Decision Points

- **Feature grows during implementation:** stop → re-run `task` to update scope → re-run `design`
- **risk-assessment flags HIGH risk on a "small" feature:** promote to full-sdlc (do not skip remaining steps)
- **Multiple features in flight:** each gets its own ACTIVE_TASK.md cycle — do not mix tasks in one file
