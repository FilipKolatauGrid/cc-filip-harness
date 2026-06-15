# Workflow: Full SDLC

Complete software development lifecycle — from requirement to deployed, archived, and context-cached.

This is a **routing-table reference doc**, not an auto-runner. Each phase lists skills to invoke manually in order. Follow the "Next:" prompt on each skill's output.

---

## Phase 0: Session Start

Before running any skill, check ACTIVE_TASK.md state:
- If `## Requirement` is populated but `## Design` is empty → previous task interrupted in intake phase. Resume with `design` or reset with `close` first.
- If any section is partially populated without an Observation block → task may have been abandoned mid-phase. Read the last populated section and resume from the next skill.
- If `ACTIVE_TASK.md` is empty → clean start, run `task`.

**Never start a new task into a non-empty ACTIVE_TASK.md without running `close` first.**

---

## Phase 1: Intake

| Step | Skill | Gate |
|------|-------|------|
| 1 | `task` | Entry point — no prior gate; warns if ACTIVE_TASK already populated |
| 2 | `init` | ## Requirement populated (greenfield only) |

**Gate to Planning:** ## Requirement must be populated with type, goal, acceptanceCriteria, constraints.

---

## Phase 2: Planning

| Step | Skill | Gate |
|------|-------|------|
| 3 | `design` | ## Requirement populated |
| 4 | `grill` | ## Design populated + Observation block present |
| 5 | `risk` | ## Design + ## ADRs populated, LOCKED sentinel present |

**Gate to Implementation:** ## Design, ## ADRs (locked), ## Risks all populated with Observation blocks.

---

## Phase 3: Implementation

| Step | Skill | Gate |
|------|-------|------|
| 6 | `code` | ## Design populated |
| 7 | `tdd` | ## Implementation Log populated; each AC gets unit + E2E test |
| 8 | `refactor` | ## Implementation Log populated + all TDD green + tests pass |

**Gate to Testing:** ## Implementation Log populated with Observation block showing test-run-output evidence.

---

## Phase 4: Testing

| Step | Skill | Gate |
|------|-------|------|
| 9 | `tests` | ## Requirement + ## Implementation Log; requires ≥1 E2E per AC |
| 10 | `coverage` | ## Test Results plan populated + Observation block; runs actual coverage tool |
| 11 | `verify` | Coverage Observation shows coverage-report evidence; runs full suite |

**Gate to Review:** ## Test Results populated with PASS verdict and Observation block showing `verdict-source: external-evidence`.

---

## Phase 5: Review

| Step | Skill | Gate |
|------|-------|------|
| 12 | `review` | ## Test Results PASS with external-evidence Observation |
| 13 | `audit` | ## Review Findings populated with review Observation |

**Gate to Integration:** ## Review Findings populated. All CRITICAL + HIGH findings resolved.

---

## Phase 6: Integration

| Step | Skill | Gate |
|------|-------|------|
| 14 | `deploy` | ## Review Findings + audit Observation (secops-scan); no unresolved CRITICAL |
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
| Observation block missing | Re-run the phase that should have produced it |
| Post-deploy smoke test fails | Execute rollback from ## Deploy Checklist → run `ship` again |
| Rolled back | Do NOT close-task — fix root cause, re-deploy, then close |

---

## Decision Points

- **risk-assessment flags HIGH risk:** pause — confirm mitigation before implementation
- **`grill` reveals unresolvable decisions:** re-run `design` with resolved constraints
- **coverage below target:** write missing tests before `verify`
- **refactor introduces regression:** re-run full test suite before proceeding to `tests`
- **verify Observation shows self-reported verdict:** re-run `verify` with actual test execution
- **Session start: ACTIVE_TASK has partial state:** check last Observation block → resume or reset
