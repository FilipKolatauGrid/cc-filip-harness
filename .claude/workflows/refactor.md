# Workflow: Refactor

Structural improvement cycle — coverage-first, risk-assessed, test-gated. Tests must pass before refactoring begins and after it ends.

This is a **routing-table reference doc**, not an auto-runner.

---

## Phase 0: Session Start

Check ACTIVE_TASK.md state before starting:
- Non-empty `## Requirement` from different task → run `close` first.
- Partial refactor state → find last Observation block, resume from next skill.

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `task` | Entry point — type=refactor; warns if ACTIVE_TASK already populated |

Set `type: refactor` in ## Requirement. Include: target files/modules, smell or reason, coverage baseline, what must NOT change (external API contracts, behavior).

**Gate:** ## Requirement populated with refactor scope + behavior constraints.

---

## Phase 2: Pre-Refactor Testing

Run coverage BEFORE touching any code. Cannot refactor safely without a green baseline.

| Step | Skill | Gate |
|------|-------|------|
| 2 | `tests` | ## Requirement populated; must include existing test coverage baseline |
| 3 | `coverage` | ## Test Results plan populated; runs actual coverage tool |

**Hard rule:** Coverage below target → write missing tests first. Do not refactor until baseline is green and coverage meets target. The coverage Observation block must show `done-signal: coverage-report` before proceeding.

**Clean state rule:** Full test suite must be green before any refactor change. The `refactor` skill enforces this — it hard-stops if baseline is red.

**Gate to Risk Assessment:** ## Test Results populated with coverage-report Observation. All tests green. Coverage at or above target.

---

## Phase 3: Planning

| Step | Skill | Gate |
|------|-------|------|
| 4 | `risk` | Context files (BE/FE_CONTEXT.md) or ## Design + ## Test Results |

For refactors, `risk` reads from `.claude/context/BE_CONTEXT.md` or `FE_CONTEXT.md` as the design input — no `design` needed unless structure changes dramatically.

Key risks: behavior regression, performance change, API contract breakage, downstream consumer impact.

**Gate to Implementation:** ## Risks populated. Mitigation plan for HIGH risks confirmed.

---

## Phase 4: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 5 | `refactor` | Tests green (verified by baseline run), ## Risks populated |

**Rules:**
- Run full test suite after every individual change — `refactor` skill enforces this with hard-stop on red
- External API contracts must not change (gate from ## Requirement)
- If change requires API contract update → stop → re-scope as feature-build

**Gate:** All tests still green post-refactor. Refactor Observation shows test-run-output evidence before and after.

---

## Phase 5: Verification

| Step | Skill | Gate |
|------|-------|------|
| 6 | `verify` | ## Requirement + ## Test Results + coverage-report Observation |

Verify: same acceptance criteria pass. Coverage maintained or improved. E2E tests unchanged.

**Gate:** ## Test Results PASS verdict. Coverage delta ≥ 0.

---

## Phase 6: Review

| Step | Skill | Gate |
|------|-------|------|
| 7 | `review` | ## Test Results PASS with external-evidence |
| 8 | `audit` | Only if refactor touches auth, input handling, or crypto |

**Gate:** ## Review Findings populated. All CRITICAL resolved.

---

## Phase 7: Integration

| Step | Skill | Gate |
|------|-------|------|
| 9 | *(merge to branch)* | Review approved |
| 10 | `close` | Merged — archives [REFACTOR] task, updates context snapshots, resets ACTIVE_TASK.md |

No `deploy` or `ship` unless refactor touches DB schema or config. ACTIVE_TASK.md must be reset — do not start next task into a stale refactor state.

**Task closed:** `task-log/YYYYMMDD-[REFACTOR]-slug.md` written. `.claude/context/` updated. ACTIVE_TASK.md reset.

---

## Rollback Paths

| Situation | Action |
|-----------|--------|
| Refactor breaks test | Revert change → re-analyze → smaller atomic step |
| Coverage drops below target | Write missing tests before continuing |
| API contract change discovered | Stop → re-scope as feature-build |
| Verification FAIL | Revert to pre-refactor state → fix root cause |
| Observation block missing on refactor | Re-run refactor to get test evidence |

---

## Decision Points

- **Coverage below target before start:** write tests first — no exceptions
- **Refactor scope grows:** re-run `task` to update scope, re-run `risk`
- **No deployment needed:** skip `deploy` + `ship` — go straight to `close` after merge
- **BE and FE both touched:** update both context snapshots in `close`
- **Baseline tests red:** fix before any refactor — `refactor` skill hard-stops on red baseline
