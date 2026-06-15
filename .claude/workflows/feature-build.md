# Workflow: Feature Build

Streamlined feature cycle — planning through merge with optional risk assessment for small features. Same gates as full-sdlc but lighter planning.

This is a **routing-table reference doc**, not an auto-runner.

---

## Phase 0: Session Start

Check ACTIVE_TASK.md state before starting:
- Non-empty `## Requirement` → run `close` on prior task, or resume if it's the same feature.
- Partial state with Observation blocks present → identify last completed phase, resume from next skill.

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `task` | Entry point — type=feature; warns if ACTIVE_TASK already populated |
| 2 | `init` *(if greenfield)* | Only for new projects |

**Gate:** ## Requirement populated with acceptanceCriteria, techStack, constraints.

---

## Phase 2: Planning

| Step | Skill | Gate | Required? |
|------|-------|------|-----------|
| 3 | `design` | ## Requirement populated | Always |
| 4 | `grill` | ## Design populated + Observation block | Always |
| 5 | `risk` | ## Design + ## ADRs locked | **Optional** — skip for small/low-risk features |

**Small feature rule:** Skip `risk` if: single layer (FE-only or BE-only), no new external dependencies, no schema changes, timeline < 3 days.

**Victory-too-early guard:** If skipping `risk`, explicitly acknowledge the risks are known-low — do not skip because they seem annoying. If any grill decision produced a HIGH consequence ADR, do not skip.

**Gate to Implementation:** ## Design + ## ADRs (locked) populated. ## Risks optional but conditional.

---

## Phase 3: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 6 | `code` | ## Design populated |
| 7 | `tdd` | ## Implementation Log; each AC must get unit + E2E test |
| 8 | `refactor` *(optional)* | TDD green, structural cleanup needed |

**Gate:** ## Implementation Log populated with test-run-output Observation.

---

## Phase 4: Testing

| Step | Skill | Gate |
|------|-------|------|
| 9 | `tests` | ## Requirement + ## Implementation Log; ≥1 E2E per AC required |
| 10 | `coverage` | ## Test Results plan + Observation; runs actual coverage tool |
| 11 | `verify` | Coverage-report Observation present; runs full suite |

**Gate:** ## Test Results PASS with external-evidence Observation.

---

## Phase 5: Review

| Step | Skill | Gate |
|------|-------|------|
| 12 | `review` | ## Test Results PASS with external-evidence |
| 13 | `audit` | ## Review Findings + review Observation |

**Gate:** ## Review Findings populated. All CRITICAL + HIGH resolved.

---

## Phase 6: Integration

| Step | Skill | Gate |
|------|-------|------|
| 14 | `deploy` *(if deploying this cycle)* | All findings resolved |
| 15 | *(merge to branch)* | Review approved |
| 16 | `close` | Merged — archives task, updates context, resets ACTIVE_TASK.md |
| 17 | `ship` *(optional)* | If feature goes to prod this cycle |

**Task closed:** `task-log/YYYYMMDD-[TYPE]-slug.md` written. `.claude/context/` updated. ACTIVE_TASK.md reset.

---

## Rollback Paths

| Situation | Action |
|-----------|--------|
| `grill` reveals fatal design flaw | Re-run `design` with resolved constraints |
| Verification FAIL | Fix blockers → re-run `verify` |
| Review BLOCKED | Fix findings → re-run `review` |
| Observation block missing | Re-run the phase that should have produced it |
| Post-deploy regression | Execute rollback from ## Deploy Checklist |

---

## Decision Points

- **Feature grows during implementation:** re-run `task` to update scope → re-run `design`
- **risk skipped, but HIGH consequence ADR found:** promote to full-sdlc — do not skip remaining steps
- **Multiple features in flight:** each gets its own ACTIVE_TASK.md cycle — do not mix tasks
- **verify Observation shows self-reported:** re-run verify with actual test execution
