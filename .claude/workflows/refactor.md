# Workflow: Refactor

Structural improvement cycle — coverage-first, risk-assessed, test-gated. Tests must pass before refactoring begins and after it ends.

This is a **routing-table reference doc**, not an auto-runner.

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `task` | Entry point — type=refactor |

Set `type: refactor` in ## Requirement. Include: target files/modules, smell or reason, coverage baseline, what must NOT change (external API contracts, behavior).

**Gate:** ## Requirement populated with refactor scope + behavior constraints.

---

## Phase 2: Pre-Refactor Testing

Run coverage analysis BEFORE touching any code. You cannot refactor safely without a green baseline.

| Step | Skill | Gate |
|------|-------|------|
| 2 | `tests` | ## Requirement populated |
| 3 | `coverage` | ## Test Results (plan) populated |

**Hard rule:** If coverage is below target → write missing tests first. Do not refactor until baseline is green and coverage meets target.

**Gate to Risk Assessment:** ## Test Results populated. Coverage at or above target. All tests green.

---

## Phase 3: Planning

| Step | Skill | Gate |
|------|-------|------|
| 4 | `risk` | ## Design (existing — read from codebase or context) + ## Test Results |

For refactors, `risk` reads from `.claude/context/BE_CONTEXT.md` or `FE_CONTEXT.md` as the design input (no `design` needed unless structure changes dramatically).

Key risks to assess: behavior regression, performance change, API contract breakage, downstream consumer impact.

**Gate to Implementation:** ## Risks populated. Mitigation plan for HIGH risks confirmed.

---

## Phase 4: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 5 | `refactor` | Tests green, ## Risks populated |

**Rules:**
- Run full test suite after every individual change — never batch changes without testing
- External API contracts must not change (gate from ## Requirement)
- If a change requires API contract update → stop → re-scope as feature-build

**Gate:** All tests still green post-refactor. No behavior change observable.

---

## Phase 5: Verification

| Step | Skill | Gate |
|------|-------|------|
| 6 | `verify` | ## Requirement + ## Test Results |

Verify: same acceptance criteria pass as before refactor. Coverage maintained or improved.

**Gate:** ## Test Results PASS verdict. Coverage delta ≥ 0.

---

## Phase 6: Review

| Step | Skill | Gate |
|------|-------|------|
| 7 | `review` | ## Test Results PASS |
| 8 | `audit` | Only if refactor touches auth, input handling, or crypto |

**Gate:** ## Review Findings populated. All CRITICAL resolved.

---

## Phase 7: Integration

| Step | Skill | Gate |
|------|-------|------|
| 9 | *(merge to branch)* | Review approved |
| 10 | `close` | Merged — archives [REFACTOR] task, updates context snapshots, resets ACTIVE_TASK.md |

No `deploy` or `ship` unless refactor touches DB schema or config.

**Task closed:** `task-log/YYYYMMDD-[REFACTOR]-slug.md` written. `.claude/context/` updated. ACTIVE_TASK.md reset.

---

## Rollback Paths

| Situation | Action |
|-----------|--------|
| Refactor breaks test | Revert change → re-analyze → smaller atomic step |
| Coverage drops below target | Write missing tests before continuing |
| API contract change discovered | Stop → re-scope as feature-build |
| Verification FAIL | Revert to pre-refactor state → fix root cause |

---

## Decision Points

- **Coverage below target before start:** write tests first — no exceptions
- **Refactor scope grows:** re-run `task` to update scope, re-run `risk`
- **No deployment needed:** skip `deploy` + `ship` entirely — go straight to `close` after merge
- **BE and FE both touched:** update both context snapshots in `close`
