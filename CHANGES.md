# Harness Transformation: Commands → Skills + AI-Native Principles

**Date:** 2026-06-15  
**Scope:** Full harness restructure — 16 skills migrated, 7 principles embedded, observability protocol added

---

## What Changed

### 1. Command Files → Skill Directories

**Before:** `.claude/commands/<name>.md` (16 flat markdown files)  
**After:** `.claude/skills/<name>/SKILL.md` (16 skill directories)

The old command files used a YAML frontmatter schema designed for slash-command routing:
```yaml
---
description: ...
phase: planning
reads: ["## Design"]
writes: ["## ADRs"]
hard_blocks:
  - condition: "## Design is empty"
    message: "..."
---
```

The new skill format uses the skill-creator standard — triggering is driven by the `description` field, which is now written to be "pushy" (includes when-to-use context, over-triggers rather than under-triggers):
```yaml
---
name: grill
description: Decision grill — stress-test every design decision... Use when starting the decision-making phase, when the user says "grill this", "let's decide"... Run before `risk` and before any implementation.
---
```

Skills are now first-class discoverable units — they appear in the skill registry the IDE loads, not just as file-path references in documentation.

**Files deleted:** All 16 files in `.claude/commands/`  
**Files created:** 16 directories in `.claude/skills/`, each containing `SKILL.md`

---

### 2. Observability Protocol (new in every skill)

**Problem before:** Every phase-completing skill wrote its section to ACTIVE_TASK.md, but downstream skills only checked whether the section was non-empty. An agent could self-declare "design complete" with no real content, and `grill` would proceed. "Agents declare victory too early" was a silent failure mode.

**Solution:** Every skill now appends an `### Observation` block after writing its section. Downstream skills read this block — not just the section content — before proceeding.

**Observation block format:**
```markdown
### Observation
- phase: <phase/skill>
- done-signal: <schema-populated | filesystem-written | test-run-output | coverage-report | diff-reviewed | secops-scan | smoke-tests-run>
- done-criteria: <what constitutes actual completion>
- verdict-source: <self-reported | external-evidence>
```

**Signal hierarchy (highest trust first):**  
`external-evidence` (test runner, coverage tool, secops agent) > `self-reported`

**Where each signal appears:**

| Signal | Produced by | Read by |
|--------|-------------|---------|
| `schema-populated` | task, design, risk, tests | grill (checks Design obs), risk (checks ADRs obs) |
| `filesystem-written` | init, code, close | — |
| `adrs-locked-sentinel-present` | grill | risk (hard-blocks if no locked sentinel) |
| `test-run-output` | tdd, refactor, verify | review (blocks on self-reported verify) |
| `coverage-report` | coverage | verify (hard-blocks if no coverage-report obs) |
| `diff-reviewed` | review | audit (blocks if review obs missing) |
| `secops-scan` | audit, deploy | deploy (audit obs), ship (deploy obs) |
| `smoke-tests-run` | ship | close (warns if ship obs missing) |

**Concrete behavior change example:**  
Before: `review` ran if `## Test Results` was non-empty.  
After: `review` reads the `verify` Observation block. If `verdict-source: self-reported`, it hard-blocks — "verify produced no test runner evidence, re-run verify with actual execution."

---

### 3. Seven AI-Native Principles Embedded

Each principle now has concrete harness mechanics, not just documentation:

#### Principle 1: Initialization Needs Its Own Phase
- `task` warns if ACTIVE_TASK.md `## Requirement` is already populated — prevents silent overwrite of in-progress work
- `init` checks for existing project files (`src/`, `package.json`, etc.) before scaffolding — warns instead of overwriting
- All 4 workflows now have a **Phase 0: Session Start** section with explicit state-check instructions

#### Principle 2: Agents Overreach and Under-Finish  
- `code`, `design`, `refactor` spawn `sdlc-investigator` before acting on existing projects — prevents designing/coding blind on an existing codebase
- `risk` hard-blocks if ADRs are not locked — risk on undecided design is undefined
- `grill` hard-blocks if Design Observation block is missing or shows no completion evidence

#### Principle 3: Feature Lists Are Harness Primitives
- `code` reads `acceptanceCriteria` from `## Requirement` directly before generating — verifies each AC maps to a component; warns on unmapped criteria
- `tdd` generates tests against AC from `## Requirement`, not inferred from design
- `verify` builds traceability matrix criterion-by-criterion from `## Requirement` — never reconstructs from implementation or design

#### Principle 4: Agents Declare Victory Too Early
- `verify` requires actual test runner output — not code inspection or assumed pass
- `review` hard-blocks if verify Observation shows `verdict-source: self-reported`
- `grill` only appends the `<!-- ADRs LOCKED -->` sentinel after developer explicitly confirms each decision — no auto-decision
- `risk` hard-blocks if the ADRs locked sentinel is absent (grill never finished)

#### Principle 5: End-to-End Testing Changes Results
- `tests` requires at least one E2E scenario per acceptance criterion — warns if any AC lacks E2E coverage
- `tdd` writes both a unit test and an E2E test per criterion during implementation
- `verify` checks E2E test status separately from unit status in the traceability matrix — an AC with only unit tests passing is flagged "partial coverage", not PASS
- `coverage` checks E2E coverage separately from line coverage

#### Principle 6: Observability Belongs Inside the Harness
- The Observation protocol above is the full implementation of this principle
- `close` now scans all Observation blocks across phases before archiving — warns if key phases have no evidence
- `docs/SKILL_REGISTRY.md` includes an Observation Block Protocol section and a signal column per skill

#### Principle 7: Every Session Must Leave a Clean State
- All 4 workflows have Phase 0 session-start state check
- `close` verifies the reset by reading ACTIVE_TASK.md back after writing
- `task` warns before overwriting an existing requirement — directs to `close` first
- CLAUDE.md session init now includes explicit health check logic (5 state cases documented)

---

### 4. Phase-by-Phase Changes

#### Intake Phase (`task`, `init`)

| Change | Before | After |
|--------|--------|-------|
| Active task guard | No check | Warns if `## Requirement` already populated |
| Existing project detection | `init` — warning present | Same warning, explicit fallback to `design` |
| Observation block | None | Appended after section write |

#### Planning Phase (`design`, `grill`, `risk`)

| Change | Before | After |
|--------|--------|-------|
| `grill` gate | Design non-empty | Design non-empty + Observation block present |
| `risk` gate | Design + ADRs non-empty | Design + ADRs + **ADRs locked sentinel present** |
| AC verification in design | Not done | `design` explicitly maps each AC to a component |
| `grill` completion proof | ADRs section written | `<!-- ADRs LOCKED -->` sentinel + Observation |

#### Implementation Phase (`code`, `tdd`, `refactor`)

| Change | Before | After |
|--------|--------|-------|
| AC coverage check before coding | None | `code` checks each AC maps to a design component |
| E2E test requirement | Not specified | `tdd` writes unit + E2E test per criterion |
| TDD evidence | Log entry (self-reported) | Runner output recorded (red → green) |
| Refactor baseline | "Run tests first" (advisory) | Hard-stop if baseline red; runner output before+after recorded |
| Observation blocks | None | All three skills append test-run-output Observations |

#### Testing Phase (`tests`, `coverage`, `verify`)

| Change | Before | After |
|--------|--------|-------|
| E2E per AC | Not enforced | `tests` warns if any AC lacks E2E scenario |
| Coverage measurement | "Run coverage tool" (instruction) | Must produce runner output; hard-stop if tool returns nothing |
| E2E coverage tracking | Not tracked | `coverage` checks E2E scenarios separately |
| `verify` gate | Test Results non-empty | Test Results + coverage-report Observation required |
| `verify` PASS definition | All AC green + coverage met | All AC green + **E2E green** + coverage met |
| `verify` evidence | Traceability matrix (stated) | Traceability matrix + fresh runner output + Observation |

#### Review Phase (`review`, `audit`)

| Change | Before | After |
|--------|--------|-------|
| `review` gate | Test Results PASS | Test Results PASS + verify Observation `external-evidence` |
| Self-reported verify block | Not checked | Hard-blocks — "re-run verify with actual test execution" |
| E2E coverage gap | Not surfaced | Review notes if verify showed E2E gaps |
| `audit` gate | Review Findings non-empty | Review Findings + review Observation `diff-reviewed` |
| Observation blocks | None | Both skills append Observations |

#### Integration Phase (`deploy`, `ship`, `close`)

| Change | Before | After |
|--------|--------|-------|
| `deploy` gate | Review Findings + audit present | + audit Observation `secops-scan` required |
| Final secops scan | Runs before checklist | Same, but result recorded in Observation |
| `ship` gate | Deploy Checklist non-empty | + deploy Observation `secops-scan` required |
| `close` Observation scan | Not done | Scans all phase Observations, warns on missing evidence |
| `close` reset verification | Not verified | Reads back ACTIVE_TASK.md to confirm reset |

---

### 5. Documentation Changes

**`CLAUDE.md`**
- Added "AI-Native Engineering Principles" table (7 principles → harness mechanism)
- Session init section now has 5-state health check (empty, partial intake, partial mid-task, missing obs, stale)
- "Resuming mid-task" now says: find last **Observation block** (not last populated section)
- "Skill Pattern" updated from 6 steps to 8 steps (adds Observation block write + evidence requirement)
- File Map updated: `.claude/commands/` removed, `.claude/skills/` expanded with all 16 skill names
- "Forbidden" list expanded: self-reported verdicts where external-evidence required; declaring phase complete without Observation block

**`docs/SKILL_REGISTRY.md`**
- Added "AI-Native Engineering Principles" table at top
- Added "Observation Block Protocol" section with signal definitions
- Skills table: File column updated to `.claude/skills/<name>/SKILL.md`; new "Key Observation Signal" column
- "Quick Lookup" table: added row for "something seems wrong with a phase result"

**Workflows (all 4)**
- Added Phase 0: Session Start to every workflow
- Gate descriptions now reference Observation blocks, not just section presence
- Rollback Paths tables: added "Observation block missing → re-run phase" row in all workflows
- `feature-build.md`: "victory-too-early guard" note on risk-skipping decision
- `refactor.md`: hard rule that baseline must be green before any refactor (enforced by skill, not just advisory)
- `bug-fix.md`: explicit note that TDD Observation records red-state runner output as bug reproduction evidence

---

## What Did NOT Change

- Phase order — all workflows follow the same sequence
- ACTIVE_TASK.md schema — same 9 sections, same fixed structure
- Agent definitions — `.claude/agents/` unchanged (sdlc-investigator, sdlc-reviewer, sdlc-secops, sdlc-context-builder)
- Phase logic — all meta-prompts, checklists, and examples preserved from original commands
- Hard-blocks — original gates preserved; new gates added on top
- Task archival format — `task-log/YYYYMMDD-[TYPE]-slug.md` unchanged
- Context snapshot format — FE_CONTEXT.md / BE_CONTEXT.md schema unchanged

---

## File Inventory

**Deleted (16 files):**
```
.claude/commands/audit.md
.claude/commands/close.md
.claude/commands/code.md
.claude/commands/coverage.md
.claude/commands/deploy.md
.claude/commands/design.md
.claude/commands/grill.md
.claude/commands/init.md
.claude/commands/refactor.md
.claude/commands/review.md
.claude/commands/risk.md
.claude/commands/ship.md
.claude/commands/task.md
.claude/commands/tdd.md
.claude/commands/tests.md
.claude/commands/verify.md
```

**Created (16 files):**
```
.claude/skills/audit/SKILL.md
.claude/skills/close/SKILL.md
.claude/skills/code/SKILL.md
.claude/skills/coverage/SKILL.md
.claude/skills/deploy/SKILL.md
.claude/skills/design/SKILL.md
.claude/skills/grill/SKILL.md
.claude/skills/init/SKILL.md
.claude/skills/refactor/SKILL.md
.claude/skills/review/SKILL.md
.claude/skills/risk/SKILL.md
.claude/skills/ship/SKILL.md
.claude/skills/task/SKILL.md
.claude/skills/tdd/SKILL.md
.claude/skills/tests/SKILL.md
.claude/skills/verify/SKILL.md
```

**Modified (6 files):**
```
CLAUDE.md                          session health check, principles table, skill pattern, file map
docs/SKILL_REGISTRY.md             principles table, observation protocol, updated paths + signal column
.claude/workflows/full-sdlc.md     Phase 0, observation-gated gates, observation rollback path
.claude/workflows/bug-fix.md       Phase 0, TDD red-state evidence note, observation gates
.claude/workflows/feature-build.md Phase 0, victory-too-early guard, observation gates
.claude/workflows/refactor.md      Phase 0, baseline-green enforcement, observation gates
```
