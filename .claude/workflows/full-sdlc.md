# Workflow: Full SDLC

Complete software development lifecycle — from requirement to deployed, archived, and context-cached.

This is a **routing-table reference doc**, not an auto-runner. Each phase lists skills to invoke manually in order. Follow the "Next:" prompt on each skill's output.

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `task` | Entry point — no prior gate |
| 2 | `init` | ## Requirement populated |

**Gate to Planning:** ## Requirement must be populated with type, goal, acceptanceCriteria, constraints.

---

## Phase 2: Planning

| Step | Skill | Gate |
|------|-------|------|
| 3 | `design` | ## Requirement populated |
| 4 | `grill` | ## Design populated |
| 5 | `risk` | ## Design + ## ADRs populated |

**Gate to Implementation:** ## Design, ## ADRs, ## Risks all populated.

---

## Phase 3: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 6 | `code` | ## Design populated |
| 7 | `tdd` | ## Implementation Log populated |
| 8 | `refactor` | ## Implementation Log populated + all TDD green |

**Gate to Testing:** ## Implementation Log populated, all TDD criteria green.

---

## Phase 4: Testing

| Step | Skill | Gate |
|------|-------|------|
| 9 | `tests` | ## Requirement + ## Implementation Log populated |
| 10 | `coverage` | ## Test Results (plan) populated |
| 11 | `verify` | ## Test Results + coverage gaps closed |

**Gate to Review:** ## Test Results populated with PASS verdict.

---

## Phase 5: Review

| Step | Skill | Gate |
|------|-------|------|
| 12 | `review` | ## Test Results PASS verdict |
| 13 | `audit` | ## Review Findings populated |

**Gate to Integration:** ## Review Findings populated. All CRITICAL + HIGH findings resolved.

---

## Phase 6: Integration

| Step | Skill | Gate |
|------|-------|------|
| 14 | `deploy` | ## Review Findings populated, no unresolved CRITICAL |
| 15 | *(merge to branch)* | Deploy checklist complete |
| 16 | `close` | Code merged — archives task, updates context, resets ACTIVE_TASK.md |
| 17 | `ship` *(optional)* | ## Deploy Checklist populated — run after prod deploy |

**Task closed:** `task-log/YYYYMMDD-[TYPE]-slug.md` written. `.claude/context/` updated. ACTIVE_TASK.md reset.

---

## Rollback Paths

| Situation | Action |
|-----------|--------|
| Review BLOCKED | Fix findings → re-run `review` |
| Verification FAIL | Fix blockers → re-run `verify` |
| Security CRITICAL_BLOCK | Fix vulns → re-run `audit` |
| Post-deploy smoke test fails | Execute rollback plan from ## Deploy Checklist → run `ship` again |
| Rolled back | Do NOT close-task — fix root cause, re-deploy, then close |

---

## Decision Points

- **risk-assessment flags HIGH risk:** pause — address mitigation before implementation
- **decision-grill produces conflicting ADRs:** re-run `design` with resolved constraints
- **coverage-analysis below target:** write missing tests before `verify`
- **refactor introduces regression:** re-run full test suite before proceeding to `tests`
