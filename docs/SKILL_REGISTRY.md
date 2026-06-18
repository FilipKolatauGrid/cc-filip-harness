# Skill Registry

Single-page lookup: what skill handles what, in what order, reading and writing which ACTIVE_TASK.md sections.

**Canonical spec:** `.claude/skills/<name>/SKILL.md` — each file is the full, authoritative definition.

---

## AI-Native Engineering Principles (embedded in all skills)

Every skill in this harness enforces one or more of these principles:

| Principle | Primary Enforcement |
|-----------|-------------------|
| **Initialization needs its own phase** | `task` warns on non-empty ACTIVE_TASK; `init` detects existing project files; all workflows have Phase 0 session-start check |
| **Agents overreach and under-finish** | All skills hard-block on missing prior sections; `code`/`design`/`refactor` spawn `sdlc-investigator` before acting |
| **Feature lists are harness primitives** | `code`, `tdd`, `verify` read acceptanceCriteria from `## Requirement` directly — never from design or memory |
| **Agents declare victory too early** | `verify` requires test-run-output evidence; `review` blocks on self-reported verify; Observation blocks gate downstream skills |
| **End-to-end testing changes results** | `tests` requires ≥1 E2E per AC; `tdd` writes E2E test per criterion; `verify` checks E2E status separately |
| **Observability inside harness** | Every phase-closing skill appends Observation block with done-signal + verdict-source; downstream skills read these |
| **Every session must leave clean state** | `close` is mandatory after merge; Phase 0 in all workflows; `task` warns if ACTIVE_TASK non-empty |

---

## Observation Block Protocol

Every skill that writes to ACTIVE_TASK.md appends an Observation block:

```markdown
### Observation
- phase: <phase/skill>
- done-signal: <schema-populated | filesystem-written | test-run-output | coverage-report | diff-reviewed | secops-scan | smoke-tests-run>
- done-criteria: <what constitutes actual completion>
- verdict-source: <self-reported | external-evidence>
```

Downstream skills that gate on a prior phase read the Observation block — not just the section content.

**Signals hierarchy (highest trust first):** `external-evidence` > `self-reported`

---

## Skills

| Skill | Phase | File | Trigger | Reads | Writes | Key Observation Signal |
|-------|-------|------|---------|-------|--------|----------------------|
| `task` | Intake | `.claude/skills/task/SKILL.md` | Start any task | latest task-log `## Deferred` (if exists) | `## Requirement` (3 sub-blocks: Initial Request → Structured Requirement → Clarification Outcomes) | schema-populated + clarifications-asked:N |
| `init` | Intake | `.claude/skills/init/SKILL.md` | Greenfield scaffold | `## Requirement` | `## Requirement` (scaffold) | filesystem-written |
| `design` | Planning | `.claude/skills/design/SKILL.md` | Design system | `## Requirement` | `## Design` | schema-populated |
| `grill` | Planning | `.claude/skills/grill/SKILL.md` | Stress-test decisions | `## Design` (scoped) | `## ADRs` | adrs-locked-sentinel-present |
| `risk` | Planning | `.claude/skills/risk/SKILL.md` | Identify risks | `## Design` + `## ADRs` (scoped, locked) | `## Risks` + planning-gate | schema-populated + planning-gate:confirmed |
| `code` | Implementation | `.claude/skills/code/SKILL.md` | Generate code | `## Design` + `## Requirement` (scoped) | filesystem + `## Implementation Log` | filesystem-written |
| `tdd` | Implementation | `.claude/skills/tdd/SKILL.md` | Test-drive criteria | `## Requirement` + `## Implementation Log` | `## Implementation Log` (append) | test-run-output |
| `refactor` | Implementation | `.claude/skills/refactor/SKILL.md` | Structural cleanup | `## Implementation Log` | `## Implementation Log` (append) | test-run-output |
| `tests` | Testing | `.claude/skills/tests/SKILL.md` | Plan test scenarios | `## Requirement` + `## Implementation Log` | `## Test Results` | schema-populated |
| `coverage` | Testing | `.claude/skills/coverage/SKILL.md` | Find coverage gaps | `## Test Results` | `## Test Results` (append) | coverage-report |
| `verify` | Testing | `.claude/skills/verify/SKILL.md` | Confirm all criteria | `## Requirement` + `## Test Results` | `## Test Results` (append) | test-run-output |
| `review` | Review | `.claude/skills/review/SKILL.md` | Review diff | `## Test Results` (scoped) + extracted AC + apiContracts + git diff | `## Review Findings` (with `[deferred]` MEDIUM tags) | diff-reviewed |
| `audit` | Review | `.claude/skills/audit/SKILL.md` | OWASP audit | `## Review Findings` + git diff | `## Review Findings` (append) | secops-scan |
| `deploy` | Integration | `.claude/skills/deploy/SKILL.md` | Pre-deploy gate | `## Review Findings` | `## Deploy Checklist` | secops-scan |
| `ship` | Integration | `.claude/skills/ship/SKILL.md` | Validate deploy | `## Deploy Checklist` | `## Post-Deploy` | smoke-tests-run |
| `close` | Integration | `.claude/skills/close/SKILL.md` | After merge | Full `ACTIVE_TASK.md` | `task-log/` (with `## Deferred`) + `.claude/context/` + reset | filesystem-written |
| `local-env-requirements` | Planning | `.claude/skills/local-env-requirements/SKILL.md` | Containerized local dev spec | project docs + `## Requirement` (soft) | `docs/local-environment.md` + `CLAUDE.md` + `docs/architecture.md` + `## Design` | spec-written |
| `validate-harness` | Meta/Utility | `.claude/skills/validate-harness/SKILL.md` | `/validate-harness` (user-invocable) | repo files (read-only) | `reports/harness-validation-report.md` | report-written (in report file) |

---

## Workflows

| Workflow | File | Use When | Skippable Steps |
|----------|------|----------|-----------------|
| `full-sdlc` | `.claude/workflows/full-sdlc.md` | New feature, complete lifecycle | None |
| `bug-fix` | `.claude/workflows/bug-fix.md` | Fixing a bug, targeted change | `audit` (if no auth/input touch), `deploy` (if not hotfix) |
| `feature-build` | `.claude/workflows/feature-build.md` | Feature with lighter planning | `risk` (small/low-risk, no HIGH-consequence ADR) |
| `refactor` | `.claude/workflows/refactor.md` | Structural improvement, no behavior change | `deploy`, `ship` (unless DB/config touched) |

All workflows include Phase 0: session-start ACTIVE_TASK.md state check.

---

## Agents

Spawned by skills — not invoked directly.

| Agent | Spawned By | Model | Purpose |
|-------|-----------|-------|---------|
| `sdlc-investigator` | `design`, `code`, `refactor` | haiku | Read-only file/symbol locator — returns FILES + SYMBOLS table, never suggests fixes |
| `sdlc-reviewer` | `review` | sonnet | Diff review anchored to acceptance criteria + design contracts — severity-tagged findings |
| `sdlc-secops` | `review`, `audit`, `deploy` | haiku | Fast secrets/vuln/compliance pattern scan — CLEAR / FINDINGS_REQUIRE_FIX / CRITICAL_BLOCK |
| `sdlc-context-builder` | `close` | sonnet | Generates/updates `.claude/context/FE_CONTEXT.md` and `BE_CONTEXT.md` from changed files |

---

## ACTIVE_TASK.md Section Order

Skills write sections in this order. Each skill hard-blocks if its required prior section is missing.

```
## Requirement        ← task, init
## Design             ← design
## ADRs               ← grill (locked sentinel required for downstream)
## Risks              ← risk
## Implementation Log ← code, tdd, refactor
## Test Results       ← tests, coverage, verify
## Review Findings    ← review, audit
## Deploy Checklist   ← deploy
## Post-Deploy        ← ship
```

`close` reads all sections + all Observation blocks, then resets ACTIVE_TASK.md to empty schema.

---

## Meta / DX

| Tool | Type | Install | When to Use |
|------|------|---------|-------------|
| [caveman](https://github.com/juliusbrussee/caveman) | Plugin | `/plugin install caveman` | All sessions — reduces output tokens ~75% |
| [grill-me](https://github.com/mattpocock/skills) | Skill | auto-loaded | Inspired `/grill` — same interrogation pattern. `/grill` implements it directly. |

---

## Context Files

Generated by `close`, loaded at session start.

| File | Updated When | Contains |
|------|-------------|---------|
| `.claude/context/FE_CONTEXT.md` | After any task touching FE files | Component tree, routing, patterns, tech stack |
| `.claude/context/BE_CONTEXT.md` | After any task touching BE files | Services, endpoints, data models, auth, tech stack |

---

## Quick Lookup: "What skill handles X?"

| Question | Skill |
|----------|-------|
| I have a task description, where do I start? | `task` |
| I need to scaffold a new project | `init` |
| I need a system design | `design` |
| I need to resolve all design decisions interactively | `grill` |
| I need to know what could go wrong | `risk` |
| I need to write the code | `code` |
| I need to write tests for a criterion | `tdd` |
| I need to clean up the code | `refactor` |
| I need a test plan | `tests` |
| I need to know what's not tested | `coverage` |
| I need to confirm requirements are met | `verify` |
| I need a code review | `review` |
| I need a security review | `audit` |
| I'm ready to deploy | `deploy` |
| I just deployed | `ship` |
| Task is done / merged | `close` |
| I need a containerized local dev environment spec | `local-env-requirements` |
| I want to score harness health / check harness changes | `validate-harness` |
| Something seems wrong with a phase result | Check that phase's Observation block |

---

## Reference Documents

| Document | Purpose |
|----------|---------|
| `docs/SKILL_REGISTRY.md` | This file — skill index, Observation protocol, quick lookup |
| `docs/ARCHITECTURE.md` | Component model, data flow, design rationale |
| `docs/HARNESS_REFERENCE.md` | ACTIVE_TASK.md schema template + full file map |
| `docs/META_PROMPTING.md` | Meta-prompting patterns and skill authoring guide |
| `docs/INTEGRATION_GUIDE.md` | How to integrate the harness into any project |
| `.claude/skills/CLAUDE.md` | Skill authoring convention (for agents in the skills dir) |
| `reports/harness-validation-report.md` | Latest output of `/validate-harness` |
