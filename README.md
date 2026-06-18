# Claude Code SDLC Harness

End-to-end software development harness for Claude Code. AI-native skills covering the full SDLC — stack-agnostic, state-driven, hard phase-gated, observability-first.

## TL;DR

```
/task       → capture requirements + acceptance criteria
/design     → system design from requirement
/grill      → stress-test decisions → ADRs
/risk       → risk register
/code       → generate implementation
/tdd        → test-drive acceptance criteria
/tests      → test plan
/coverage   → find gaps
/verify     → confirm all criteria pass (external evidence required)
/review     → code review anchored to acceptance criteria
/audit      → OWASP security audit
/deploy     → pre-deploy checklist + secops gate
/ship       → validate deployment
/close      → archive task, update context, reset

/validate-harness          → score harness health (32 checks, 7 sections)
/local-env-requirements    → produce containerized local dev spec (docs only)
```

## AI-Native Engineering Principles

Seven principles embedded as first-class constraints in every skill:

| # | Principle | Harness Mechanism |
|---|-----------|-------------------|
| 1 | **Initialization needs its own phase** | `task` warns on non-empty ACTIVE_TASK; `init` checks for existing files |
| 2 | **Agents overreach and under-finish** | All skills hard-block on missing prior phase; `code`/`design`/`refactor` spawn `sdlc-investigator` |
| 3 | **Feature lists are harness primitives** | `code`, `tdd`, `verify` read acceptanceCriteria from `## Requirement` — never from design or memory |
| 4 | **Agents declare victory too early** | `verify` requires test-runner evidence; `review` blocks on self-reported verdicts; Observation blocks gate downstream |
| 5 | **End-to-end testing changes results** | `tests` requires ≥1 E2E per AC; `tdd` writes E2E per criterion; `verify` checks E2E coverage separately |
| 6 | **Observability belongs inside the harness** | Every phase-closing skill appends Observation block with `done-signal` + `verdict-source` |
| 7 | **Every session must leave clean state** | `close` mandatory after merge; session-start check in all workflows |

## How It Works

1. Invoke skills in phase order — each skill reads `ACTIVE_TASK.md`, guards on prior phase, does its work, writes output + Observation block, tells you what to run next
2. State persists across sessions in `ACTIVE_TASK.md` at repo root
3. After merge: `/close` archives the task to `task-log/`, regenerates `.claude/context/` snapshots, resets `ACTIVE_TASK.md`

## Quick Start

```bash
/task
/design
/grill
/code
/tdd
/verify
/review
/audit
/close
```

## Typical Session

```
You: /task
→ "Add rate limiting to our NestJS API. 100 req/min per IP. 1 week."

Harness writes ### Initial Request (verbatim) + ### Structured Requirement (parsed schema)

Clarification 1/2: Who consumes the rate limit error response?
  1. End users (browser) — HTTP 429 with Retry-After header  ★ Recommended
  2. Internal API clients only — simpler JSON error body
→ You: 1

Clarification 2/2: Should rate limit state survive server restarts?
  1. No — in-memory, reset on restart (simpler)
  2. Yes — persisted in Redis (survives restart, horizontally scalable)  ★ Recommended
→ You: 2

Harness writes ### Clarification Outcomes → ACTIVE_TASK.md
Next: /design

You: /design
Harness reads ## Requirement, generates component map + API contracts
Next: /grill

You: /grill
Interactive: walks full design tree one decision at a time, presents numbered
options + recommendation, developer picks → ADR-001, ADR-002, ...
Next: /risk

... (follow the chain) ...

You: /close
Harness archives to task-log/20260615-[BE]-add-rate-limiting.md
Updates .claude/context/BE_CONTEXT.md
Resets ACTIVE_TASK.md
```

## Workflows

Jump to a workflow by task type — each is a routing-table doc in `.claude/workflows/`:

| Workflow | File | Use When |
|----------|------|----------|
| Full SDLC | `.claude/workflows/full-sdlc.md` | Complete lifecycle |
| Feature | `.claude/workflows/feature-build.md` | New feature, lighter planning |
| Bug fix | `.claude/workflows/bug-fix.md` | Fix a bug, TDD-first |
| Refactor | `.claude/workflows/refactor.md` | Structural cleanup, coverage-first |

All workflows include Phase 0: session-start ACTIVE_TASK.md state check.

## Structure

```
.claude/
  skills/       task/ init/ design/ grill/ risk/ code/ tdd/ refactor/
                tests/ coverage/ verify/ review/ audit/ deploy/ ship/ close/
                validate-harness/           ← harness health check (meta skill)
                local-env-requirements/     ← containerized local dev spec (design phase)
                CLAUDE.md                   ← skill authoring convention
                (each skill dir has SKILL.md — canonical spec + full skill logic)
  agents/       sdlc-investigator, sdlc-reviewer, sdlc-secops, sdlc-context-builder
  workflows/    full-sdlc, bug-fix, feature-build, refactor
  hooks/        load-context.sh, phase-gate.sh, secops-scan.sh,
                verify-fail-capture.sh, harness-change-detect.sh, pre-commit.template
  context/      FE_CONTEXT.md, BE_CONTEXT.md  ← auto-generated by /close (empty until first run)

reports/        harness-validation-report.md  ← output of /validate-harness
task-log/       YYYYMMDD-[TYPE]-slug.md per completed task  ← auto-populated by /close
docs/           SKILL_REGISTRY.md, INTEGRATION_GUIDE.md, META_PROMPTING.md,
                ARCHITECTURE.md, HARNESS_REFERENCE.md
examples/       python-cli-walkthrough.md, typescript-api-walkthrough.md
ACTIVE_TASK.md  current task state (one section per phase, reset by /close)
CLAUDE.md       session init instructions + phase gating rules
```

## State: `ACTIVE_TASK.md`

```
## Requirement        ← /task
## Design             ← /design
## ADRs               ← /grill
## Risks              ← /risk
## Implementation Log ← /code /tdd /refactor
## Test Results       ← /tests /coverage /verify
## Review Findings    ← /review /audit
## Deploy Checklist   ← /deploy
## Post-Deploy        ← /ship
```

Each section may contain one or more `### Observation` blocks written by the skill that populated it. Downstream skills gate on these — not just section content.

## Agents

Spawned by skills automatically — not invoked directly.

| Agent | Spawned By | Purpose |
|-------|-----------|---------|
| `sdlc-investigator` | `design`, `code`, `refactor` | Read-only file/symbol locator — never suggests fixes |
| `sdlc-reviewer` | `review` | Diff review anchored to acceptance criteria + design contracts |
| `sdlc-secops` | `review`, `audit`, `deploy` | Fast secrets/vuln/compliance pattern scan |
| `sdlc-context-builder` | `close` | Generates/updates `.claude/context/` snapshots |

## Meta / DX

- [caveman](https://github.com/juliusbrussee/caveman) — token-efficient output (~75% reduction). Install once: `/plugin install caveman`
- [grill-me](https://github.com/mattpocock/skills) — inspired `/grill`'s interrogation pattern (full design tree, one decision at a time, codebase-first resolution)

## Hooks

Six automation hooks enforce discipline at the shell level — no skill changes required.

| Hook | Event | What It Does |
|------|-------|-------------|
| `load-context.sh` | `SessionStart` | Injects current phase/verdict/next-skill into context window — no cold file read |
| `phase-gate.sh` | `PreToolUse(Bash)` | Blocks skill invocations if required prior Observation is missing — exit 2 |
| `secops-scan.sh` | `PostToolUse(Write\|Edit)` | Async regex scan for secrets/vulns on source files during implementation |
| `verify-fail-capture.sh` | `UserPromptSubmit` | Injects prior FAIL blockers when `/verify` re-submitted |
| `harness-change-detect.sh` | `PostToolUse(Write\|Edit)` | Detects edits to harness files; reminds session to run `/validate-harness` |
| `pre-commit.template` | `git commit` | Blocks commits when task is in early phase with no test evidence |

Install git hook (one-time per project clone):
```bash
cp .claude/hooks/pre-commit.template .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Status

- [x] Intake: `/task`, `/init`
- [x] Planning: `/design`, `/grill`, `/risk`, `/local-env-requirements`
- [x] Implementation: `/code`, `/tdd`, `/refactor`
- [x] Testing: `/tests`, `/coverage`, `/verify`
- [x] Review: `/review`, `/audit`
- [x] Integration: `/deploy`, `/ship`, `/close`
- [x] Meta/Utility: `/validate-harness`
- [x] Workflows: `full-sdlc`, `bug-fix`, `feature-build`, `refactor`
- [x] AI-native principles (7) embedded across all skills
- [x] Observation block protocol — every phase-closing skill
- [x] Hooks (6) — session context, phase gate, secops scan, verify-fail capture, harness-change-detect, git interlock
- [x] `SKILL_REGISTRY.md`, `ARCHITECTURE.md`, `HARNESS_REFERENCE.md`
- [x] `.claude/skills/CLAUDE.md` — skill authoring convention
- [x] `.editorconfig` — editor consistency
- [x] Example walkthroughs (Python CLI, TypeScript API)
- [x] `CLAUDE.md` (134 lines — under 150-line guideline)
- [x] `INTEGRATION_GUIDE.md`

## Integrating Into Your Project

See [`docs/INTEGRATION_GUIDE.md`](docs/INTEGRATION_GUIDE.md).
