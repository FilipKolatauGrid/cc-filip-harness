# Claude Code SDLC Harness

End-to-end software development harness for Claude Code. Meta-prompted skills covering the full SDLC — stack-agnostic, state-driven, hard phase-gated.

## How It Works

1. User invokes skills manually in phase order
2. Each skill reads `ACTIVE_TASK.md`, hard-blocks if the prior phase section is missing, does its work, writes output to its own section, and tells you what to run next
3. State persists across sessions via `ACTIVE_TASK.md` at repo root

**Entry point:** always `/capture-requirements` → follow the "Next:" prompt at each step.

## Quick Start

```bash
# 1. Clone or init your project repo
# 2. Run capture-requirements to create ACTIVE_TASK.md and structured requirement
# 3. Follow the "Next:" prompt on each skill's output
```

## Structure

```
.claude/skills/
  intake/
    capture-requirements.md   # Entry point — writes ACTIVE_TASK.md → ## Requirement
    init-project.md           # Scaffold directories, config, CLAUDE.md from requirement
  planning/
    architecture-design.md    # Reads Requirement → writes ## Design
    decision-grill.md         # Reads Design → writes ## ADRs  (uses grill-me)
    risk-assessment.md        # Reads Design + ADRs → writes ## Risks
  implementation/
    code-gen.md               # Reads Design → writes filesystem + ## Implementation Log
    tdd.md                    # Reads Requirement + Impl Log → appends ## Implementation Log
    refactor.md               # Reads Impl Log → appends ## Implementation Log
  testing/
    test-design.md            # Reads Requirement + Impl Log → writes ## Test Results
    coverage-analysis.md      # Reads Test Results → appends gap analysis
    verification.md           # Reads Requirement + Test Results → appends verdict
  review/
    code-review.md            # Reads Test Results + git diff → writes ## Review Findings
    security-audit.md         # Reads Review Findings + git diff → appends ## Review Findings
  integration/
    deploy-checklist.md       # Reads Review Findings → writes ## Deploy Checklist
    post-deploy.md            # Reads Deploy Checklist → writes ## Post-Deploy

.claude/workflows/            # Routing-table reference docs (not auto-runners)
  full-sdlc.md
  bug-fix.md
  feature-build.md
  refactor.md

docs/
  SKILL_REGISTRY.md           # Single-page lookup: skill → phase, reads, writes
  HARNESS_DESIGN.md
  META_PROMPTING.md
  IMPLEMENTATION_PLAN.md

examples/
  python-cli-walkthrough.md
  typescript-api-walkthrough.md
```

## State: `ACTIVE_TASK.md`

Fixed schema — one section per phase, written in order:

```
## Requirement  ← capture-requirements / init-project
## Design       ← architecture-design
## ADRs         ← decision-grill
## Risks        ← risk-assessment
## Implementation Log  ← code-gen, tdd, refactor
## Test Results        ← test-design, coverage-analysis, verification
## Review Findings     ← code-review, security-audit
## Deploy Checklist    ← deploy-checklist
## Post-Deploy         ← post-deploy
```

## Meta / DX Tools

- [caveman](https://github.com/juliusbrussee/caveman) — install for token-efficient output (~75% reduction, full accuracy)
- [grill-me](https://github.com/mattpocock/skills) — invoked by `decision-grill` to stress-test ADRs

## Status

- [x] Intake: `capture-requirements`
- [x] Intake: `init-project`
- [ ] Planning: `architecture-design`
- [ ] Planning: `decision-grill`
- [ ] Planning: `risk-assessment`
- [ ] Implementation: `code-gen`, `tdd`, `refactor`
- [ ] Testing: `test-design`, `coverage-analysis`, `verification`
- [ ] Review: `code-review`, `security-audit`
- [ ] Integration: `deploy-checklist`, `post-deploy`
- [ ] Workflows (4)
- [ ] `SKILL_REGISTRY.md`
- [ ] Example walkthroughs (2)
- [ ] `CLAUDE.md`
