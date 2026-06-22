# Tech-Stack Agnostic Detection Layer + Adaptive Verification

**Date:** 2026-06-22
**Scope:** 2 new hooks, 1 skill update, 5 doc updates, 1 settings update, 1 gitignore update

---

## What Changed

### 1. `stack-detect.sh` — SessionStart Hook (B1–B5)

New hook: `.claude/hooks/stack-detect.sh`

Fires synchronously at every session start alongside `load-context.sh`. Inspects the repo root and writes `.claude/stack-profile.json` with detected tech stack. Injects a one-line stack summary into the context window via `additionalContext`.

**Detection coverage (B1–B5):**

| Section | What it detects | Indicators |
|---------|-----------------|-----------|
| B1 — Package manager | npm / yarn / pnpm / pip / poetry / cargo / go / maven / gradle / bundler | `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile` |
| B2 — Entry points + start command | `scripts.dev` or `scripts.start` in `package.json`; `main.py`, `app.py`, `manage.py`, `cmd/` | Files at repo root and `src/` |
| B3 — Test runner | jest / vitest / mocha / pytest / go-test / cargo-test / junit | Grep of `package.json` deps; `pytest.ini`, `conftest.py` |
| B4 — Lint / type-check / shellcheck | eslint, ruff, flake8, go vet, cargo clippy; tsc, mypy, pyright; shellcheck binary | `.eslintrc*`, `eslint.config.*`, `.ruff.toml`, `[tool.ruff]`, `.flake8`, `tsconfig.json`, `mypy.ini`, `[tool.mypy]`; `command -v shellcheck` |
| B5 — Verify chain | Ordered array: lint → typecheck → test → shellcheck | Built from above detections |

**Stack profile schema** (`.claude/stack-profile.json`):
```json
{
  "detected_at": "<ISO timestamp>",
  "package_manager": "npm|pip|cargo|go|...|unknown",
  "install_cmd": "npm install | pip install -r requirements.txt | ...",
  "start_cmd": "npm run dev | python main.py | ...",
  "test_runner": "jest|vitest|pytest|go-test|...",
  "test_cmd": "npm test | pytest | go test ./... | ...",
  "lint_cmd": "npm run lint | ruff check . | go vet ./... | ...",
  "typecheck_cmd": "npx tsc --noEmit | mypy . | ...",
  "shellcheck_available": true|false,
  "verify_chain": ["lint", "typecheck", "test", "shellcheck"],
  "entry_points": ["src/index.ts", "main.py"]
}
```

Non-blocking (exit 0 always). Re-runs and overwrites profile every session (stack can change). Profile excluded from git.

**Cross-platform:** POSIX bash + python3 stdlib (no pip installs). Windows requires WSL2 or Git Bash.

---

### 2. `adaptive-verify.sh` — PostToolUse Hook (B3+B4)

New hook: `.claude/hooks/adaptive-verify.sh`

Fires asynchronously after every Write or Edit tool call. Reads `.claude/stack-profile.json` and runs targeted checks based on the changed file's extension and path. Non-blocking — emits warnings only.

**Check logic:**

| File type | Check |
|-----------|-------|
| `*.sh` (any path) | Run `shellcheck -f gcc` if available; advisory to install if not |
| `*.sh` in `.claude/hooks/` | Same + always shows advisory if shellcheck absent |
| `*.ts`, `*.tsx`, `*.js`, `*.jsx` | Emit lint reminder (`lint_cmd`) + typecheck reminder (`typecheck_cmd`) |
| `*.spec.*`, `*.test.*` | Emit targeted test reminder (`test_cmd <file>`) |
| `*.py` | Emit lint reminder; typecheck reminder if configured |
| `test_*.py`, `*_test.py` | Emit targeted test reminder |
| `*.go` | `go vet ./... && go test ./...` reminder |
| `*.rs` | `cargo clippy && cargo test` reminder |
| `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml` | B1 install reminder (`install_cmd`) |

Skips `.git/`, `node_modules/`, `__pycache__/`, `target/`, `.cache/`. Skips silently if `stack-profile.json` absent.

**Motivation:** Without this hook, a developer edits a `.sh` hook file and gets no feedback until manually running shellcheck. Editing TypeScript produced no inline lint signal. The hook closes the feedback loop at the file-save layer without adding a blocking step.

---

### 3. `init/SKILL.md` — B1–B5 Stack Detection Integration

Updated: `.claude/skills/init/SKILL.md`

After scaffold files are written, `init` now:
1. Runs `bash .claude/hooks/stack-detect.sh` (or reads existing profile from the SessionStart run)
2. Reads `.claude/stack-profile.json`
3. Appends a `### Stack Profile` subsection to `## Requirement` with B1–B5 findings

Output format appended to `## Requirement`:
```markdown
### Stack Profile
- B1 package-manager: <pm> — install: `<install_cmd>`
- B2 start: `<start_cmd>` — entry points: [<list>]
- B3 test-runner: <test_runner> — run: `<test_cmd>`
- B4 lint: `<lint_cmd>` | typecheck: `<typecheck_cmd>` | shellcheck: <true|false>
- B5 verify-chain: [<ordered chain>]
```

Observation block `done-criteria` updated to include `stack-profile.json written`.

---

### 4. `settings.local.json` — New Hooks Wired

Two new hook entries added:

**SessionStart** (alongside `load-context.sh`):
```json
{ "type": "command", "command": "...stack-detect.sh", "timeout": 10, "statusMessage": "Detecting tech stack..." }
```

**PostToolUse / Write|Edit** (alongside `secops-scan.sh` and `harness-change-detect.sh`):
```json
{ "type": "command", "command": "...adaptive-verify.sh", "timeout": 30, "async": true }
```

Hook count: 5 → 7 Claude Code hooks (8 total including `pre-commit.template`).

---

### 5. Documentation Updates

**`CLAUDE.md`** — Added explicit skills directory pointer near "How to Use":
> `Skills live in .claude/skills/ — one subdirectory per skill, each with a SKILL.md. Full index: docs/SKILL_REGISTRY.md.`
This fixes the F2 PARTIAL finding from `/validate-harness` (98% → would score 100% on re-run).

**`docs/SKILL_REGISTRY.md`** — New **Hooks** section with full table of all 8 hooks (event, blocking/async, purpose). `init` row updated to reflect B1–B5 `### Stack Profile` write. Stack profile note added.

**`docs/HARNESS_REFERENCE.md`** — File Map updated: `stack-detect.sh`, `adaptive-verify.sh` added to hooks section; `pre-commit.template` made explicit; `stack-profile.json` added as gitignored session artifact.

**`docs/INTEGRATION_GUIDE.md`** — Hooks count 5→7 throughout; hooks table updated with two new rows; Minimum File Set updated (6→8 hooks); Per-Stack Setup section now leads with automatic detection coverage table; `.gitignore` recommendations updated with `stack-profile.json`.

**`docs/ARCHITECTURE.md`** — Hooks component description updated (count + capabilities). New design decision: "Why tech-stack detection at the hook layer, not in skills?" (rationale: profile available before first skill invocation). Local development prerequisites updated: added Python 3 (for hook JSON parsing), shellcheck (optional), WSL2/Git Bash note for Windows.

**`.gitignore`** — Added `.claude/stack-profile.json` (session artifact, not committed).

---

## What Did NOT Change

- Phase order — all workflows unchanged
- ACTIVE_TASK.md schema — unchanged
- All other SKILL.md files — no logic changes
- Agent definitions — unchanged
- Observation block protocol — format unchanged
- Phase gate logic in `phase-gate.sh` — unchanged
- Harness validation score — 98% → no regression (F2 gap fixed by CLAUDE.md update)

---

## File Inventory

**Created (3 files):**
```
.claude/hooks/stack-detect.sh           SessionStart: B1–B5 detection, writes stack-profile.json
.claude/hooks/adaptive-verify.sh        PostToolUse: targeted lint/typecheck/shellcheck per file type
reports/harness-validation-report.md    /validate-harness output (98% Solid)
```

**Modified (7 files):**
```
.claude/skills/init/SKILL.md    B1–B5 stack detection section, checklist items, updated obs criteria
.claude/settings.local.json     stack-detect + adaptive-verify hooks wired (5→7 Claude Code hooks)
.gitignore                      .claude/stack-profile.json excluded
CLAUDE.md                       skills dir pointer added (F2 fix)
docs/SKILL_REGISTRY.md          new Hooks table, init row updated
docs/HARNESS_REFERENCE.md       file map updated (new hooks + stack-profile.json)
docs/INTEGRATION_GUIDE.md       hook count, table, per-stack detection table, gitignore rec
docs/ARCHITECTURE.md            hooks description, new design decision, local dev prereqs
```

---

# task: Human-in-the-Loop Requirements (Clarification Session)

**Date:** 2026-06-18
**Scope:** `.claude/skills/task/SKILL.md` — interactive DoR/DoD clarification built into requirements intake

---

## What Changed

### Interactive Clarification Session in `/task`

**Before:** `task` parsed user input into a structured schema and wrote one block to `## Requirement`. No interactive back-and-forth during intake. Ambiguities surfaced passively in a `questions` field — developer had to notice and act on them.

**After:** After writing the structured requirement, `task` identifies DoR/DoD gaps and asks them **one at a time** in grill-style format before finalising the requirement. Each question presents numbered options with pros/cons and a recommendation. Developer picks an option or gives a custom answer. Skill stops after each question and waits.

**Motivation:** Requirements built without human confirmation compound errors through all downstream phases. Getting the requirement right before design is cheaper than fixing it after code. The `task` skill is the highest-leverage point for human input.

### Three-Block Output (was one block)

`## Requirement` now contains three ordered sub-blocks:

1. `### Initial Request` — verbatim user input, unmodified. Never parsed or edited.
2. `### Structured Requirement` — parsed schema (type, goal, AC, scope, constraints, metrics).
3. `### Clarification Outcomes` — one entry per Q&A: question asked + developer's answer + impact on the requirement.

This makes the requirement section self-contained: anyone reading it can see the raw input, the parsed interpretation, and every clarification decision that shaped it.

### DoR/DoD Scope Table — Allowed vs Forbidden

The skill includes an explicit table separating what belongs in `task` clarification from what belongs in `design`/`grill`:

| Allowed (requirement-level) | Forbidden (belongs to design/grill) |
|---|---|
| Who is the end user? | Which database/store to use? |
| What does "done" look like? | Which library or framework? |
| Hard deadlines or SLAs? | Error handling strategy? |
| Which existing systems does this integrate with? | API design or schema shape? |
| Compliance or regulatory constraints? | Retry/fallback policies? |
| Acceptable failure behavior from user's perspective? | Deployment or infrastructure choices? |

Technical gaps are **skipped** — not asked. They surface naturally in `design`/`grill`.

### Observation Block Updated

```
### Observation
- phase: intake/task
- done-signal: schema-populated
- done-criteria: acceptanceCriteria non-empty, scope defined, successMetrics measurable, clarification-outcomes present (or 0 gaps found)
- clarifications-asked: N
- verdict-source: self-reported
```

`clarifications-asked: N` lets downstream skills and `close` know how many requirement decisions were validated by the developer.

---

## What Did NOT Change

- Section name (`## Requirement`) — unchanged; phase gates still work
- Downstream skill reads — all read `## Requirement`; sub-blocks are additive, not structural changes
- `grill` scope — still handles technical/implementation decisions. `task` clarification is requirement-level only
- Observation signal (`schema-populated`) — unchanged; `clarifications-asked` is a new field, not a new signal

---

## File Inventory

**Modified (1 file):**
```
.claude/skills/task/SKILL.md    three-block output, clarification session, DoR/DoD scope table, updated pattern + checklist + example
```

---

# Harness Cycle 3: Refactor + Skill Expansion + Observability Hook

**Date:** 2026-06-17
**Scope:** 2 new skills, 5 new files, 7 file edits — CLAUDE.md trim, documentation layer, harness self-measurement

---

## What Changed

### 1. Two New Skills Added

#### `validate-harness` (Meta/Utility)

A standalone, read-only diagnostic skill that scores the harness against a 32-check, 7-section foundational checklist and writes a structured report to `reports/harness-validation-report.md`.

Key design decisions vs. the source specification:
- Auto-detects `HARNESS_TYPE = prompt-harness` (SKILL.md files present, no source files at root) → marks B1–B5 as `N/A` instead of FAIL. The original spec evaluated language-agnostic harnesses the same as application repos, producing misleading scores.
- Observation block written inside the report file, not ACTIVE_TASK.md — this skill has no SDLC phase context.
- Not phase-gated (no ACTIVE_TASK.md hard-blocks) — runs against any harness state, idle or active.

Trigger: `/validate-harness` (explicit user invocation only).

#### `local-env-requirements` (Planning Phase)

Produces a requirements specification for a containerized local development environment. Documents **what** the environment must provide — not **how** to implement it. No Dockerfiles, no docker-compose.yml generated.

Fits in the planning phase (after `/task`, alongside or before `/design`). Reads existing project docs (CLAUDE.md, docs/techstack.md, docs/dependencies.md, docs/architecture.md) to derive what must be containerized vs. left on the host. Writes:
- `docs/local-environment.md` — full requirements spec
- `CLAUDE.md` — short Getting Started pointer (preserves existing content)
- `docs/architecture.md` — local dev section (creates file if missing)
- `ACTIVE_TASK.md → ## Design` — deliverable summary + Observation block

Both skills registered in `docs/SKILL_REGISTRY.md` and `CLAUDE.md` File Map.

---

### 2. CLAUDE.md Trimmed to 134 Lines (was 193)

**Before:** 193 lines. ACTIVE_TASK.md schema template (~30 lines) and File Map (~25 lines) inlined.

**After:** 134 lines. Both extracted to `docs/HARNESS_REFERENCE.md`. Replaced with single-line links.

Agent instruction files should stay under 150 lines — every line loaded every session.

---

### 3. E3 Single-Task Constraint Made Explicit

`## Forbidden` entry updated from:
> "Starting a new task without resetting ACTIVE_TASK.md"

To:
> "Starting a new task without resetting ACTIVE_TASK.md (one active task per session; `task` warns on non-empty state)"

The constraint was implied but not explicit. Phase-gate.sh already enforces it at the tool layer; CLAUDE.md now states it as a named rule.

---

### 4. Documentation Layer Added

Three new files:

**`docs/HARNESS_REFERENCE.md`** — extracted schema template + full annotated file map (includes new hooks, reports/ dir, .claude/skills/CLAUDE.md). The `<!-- Status: idle -->` sentinel is part of the canonical template.

**`docs/ARCHITECTURE.md`** — component model (ASCII diagram), full SDLC data flow diagram, and design rationale for four key decisions:
- Why Markdown prompts over code
- Why flat ACTIVE_TASK.md over a database
- Why Observation blocks
- Why agent delegation over inline skill logic

**`.claude/skills/CLAUDE.md`** — skill authoring convention for agents navigating the skills directory. Contains the 8-step pattern, Observation block field reference, phase gate contract table, and instructions for adding a new skill. Addresses validator finding F3 (no hierarchical instruction files).

---

### 5. `ACTIVE_TASK.md` Idle Sentinel

Added `<!-- Status: idle -->` to the canonical ACTIVE_TASK.md schema template and to the live file. Allows tooling (and skills) to distinguish "initialized schema, no active task" from "uninitialized file". Canonical template in `docs/HARNESS_REFERENCE.md` includes the sentinel.

---

### 6. `close/SKILL.md` — Doc Update Checklist Step

Added to the close checklist:
> "If shipped feature changes user-facing behavior: update README.md and relevant docs/ files before regenerating context"

Previously this expectation existed only implicitly (close regenerates context). Now explicit in the checklist.

---

### 7. `harness-change-detect.sh` Hook + Settings Wiring

New hook: `.claude/hooks/harness-change-detect.sh`

Fires async on every Write/Edit tool call. Checks if the written file is a harness file:
- `CLAUDE.md`
- `.claude/skills/*/SKILL.md`, `.claude/skills/CLAUDE.md`
- `.claude/agents/*.md`
- `.claude/workflows/*.md`
- `.claude/hooks/*.sh`
- `docs/SKILL_REGISTRY.md`, `docs/HARNESS_REFERENCE.md`, `docs/ARCHITECTURE.md`, `docs/META_PROMPTING.md`

If yes, emits:
```
HARNESS CHANGE DETECTED: <filename> modified.
Run /validate-harness to measure the impact of this change on harness score.
```

This closes the feedback loop: every harness modification prompts measurement. The validator is no longer a one-time diagnostic — it's a CI-equivalent check triggered by the hook.

Wired in `.claude/settings.local.json` as a second async PostToolUse hook alongside `secops-scan.sh`.

---

### 8. `.editorconfig` Added

Minimal editor config: UTF-8, LF line endings, 2-space indent for `.md`/`.json`, 4-space for `.sh`. Includes `# Shell scripts: validate with shellcheck` convention note.

---

## What Did NOT Change

- Phase order — all workflows unchanged
- ACTIVE_TASK.md schema — same 9 sections (idle sentinel is a comment, not a section)
- All 16 SDLC SKILL.md files — no logic changes
- Agent definitions — sdlc-investigator, sdlc-reviewer, sdlc-secops, sdlc-context-builder unchanged
- Observation block protocol — format unchanged
- Phase gate logic in phase-gate.sh — unchanged

---

## File Inventory

**Created (7 files):**
```
.claude/skills/validate-harness/SKILL.md
.claude/skills/local-env-requirements/SKILL.md
.claude/skills/CLAUDE.md
.claude/hooks/harness-change-detect.sh
docs/HARNESS_REFERENCE.md
docs/ARCHITECTURE.md
.editorconfig
```

**Modified (9 files):**
```
CLAUDE.md                         trimmed 193→134 lines; E3 explicit; template+filemap extracted
ACTIVE_TASK.md                    <!-- Status: idle --> sentinel added
.claude/skills/close/SKILL.md     doc-update checklist step added
.claude/settings.local.json       harness-change-detect hook wired (6th hook)
docs/SKILL_REGISTRY.md            two new skills in table; Reference Documents section added
docs/INTEGRATION_GUIDE.md         18 skills, 6 hooks, /validate-harness troubleshooting note
docs/META_PROMPTING.md            Skill Structure Template updated (commands→skills path, current format)
README.md                         new skills, hooks, structure, status
CHANGES.md                        this entry
```

---

# Harness Cycle 2: Token Reduction + HITL Gates + Deferred Findings

**Date:** 2026-06-16
**Scope:** 6 SKILL.md files + SKILL_REGISTRY.md + CLAUDE.md — planning gate, grill batch-resolve, section-scoped reads, pseudocode compression, reviewer context extraction, close warnings, deferred findings chain

---

## What Changed

### 1. Planning Gate (AC-1)

**Before:** `risk` output a risk register and said "Next: run `code`." No dev confirmation required. Wrong design compounded silently through 8+ phases.

**After:** `risk` ends with a `## Planning Complete` section: 3-bullet summary (design + key ADRs + top risk) and explicit "Confirm to proceed?" prompt. On "proceed", updates `planning-gate: confirmed` in the Risks Observation block.

`code` now hard-blocks if `## Risks` Observation does not contain `planning-gate: confirmed`:
> "Planning gate not confirmed. Run `risk` and confirm the planning summary before proceeding to `code`."

CLAUDE.md Phase Gating table updated. CLAUDE.md Forbidden list updated.

---

### 2. Grill Phase 0 Batch-Resolve (AC-2)

**Before:** Every decision — including ones answerable from codebase — required individual HITL turns. Cycle 1: 11 turns for 8 codebase-resolvable + 3 human decisions.

**After:** Grill now runs a Phase 0 before any questions:
1. Classifies all decisions as `codebase-resolvable` or `human-required`
2. Shows all codebase-resolvable decisions as a numbered list with proposed answers: "N decisions resolved from codebase — confirm all or override any:"
3. Only human-required decisions get individual HITL turns (Phase 1+)

Classification rule is explicit and binary: `codebase-resolvable = answer derivable solely from existing file content, zero product or UX judgment required.`

"One question per message" rule preserved — applies to Phase 1 only.

---

### 3. Section-Scoped ACTIVE_TASK Reads (AC-3)

**Before:** All skills read full ACTIVE_TASK.md (~12K tokens by audit phase). Every skill paid for sections it didn't need.

**After:** Each SKILL.md Prerequisites section now specifies exact sections to read with "stop at next `##`" boundary. Per-skill, not a shared pattern (consistent with existing convention).

| Skill | Reads |
|-------|-------|
| `grill` | `## Design` + `## Requirement` (scoped) |
| `risk` | `## Design` + `## ADRs` (scoped) |
| `code` | `## Design` + `## Requirement` (scoped) |
| `review` | `## Test Results` + `## Requirement` (scoped) + `## Design.apiContracts` only |
| `close` | Full ACTIVE_TASK.md (only legitimate exception) |

CLAUDE.md Forbidden: "Reading full ACTIVE_TASK.md in any skill that defines section-scoped read boundaries."

---

### 4. Pseudocode Compression (AC-4)

**Before:** Each SKILL.md `## Pattern` section contained 8–31 lines of JavaScript pseudocode. Conceptual only — no runtime value. ~75 lines total across 6 skills.

**After:** Each `## Pattern` compressed to a 5-line comment block covering the 5 invariant steps:
```
// 1. Hard-block guard
// 2. Self-inject from required sections
// 3. Generate output
// 4. Write to ACTIVE_TASK.md section
// 5. Append Observation block
```

Skills compressed: `risk`, `grill` (Session Flow restructured), `code`, `review`, `close`, `task`.

---

### 5. Review Subagent Context Extraction (AC-5)

**Before:** `sdlc-reviewer` received full ACTIVE_TASK.md + full diff. Reviewer read `## Risks`, `## ADRs`, and full TDD log — none of which it needs.

**After:** Before spawning `sdlc-reviewer`, `review` extracts a scoped context object:
```
reviewerContext = {
  diff: git diff main...HEAD,
  acceptanceCriteria: readSection("## Requirement").acceptanceCriteria,
  apiContracts: readSection("## Design").apiContracts
}
```

`sdlc-secops` unchanged — still receives full diff (needs it for pattern scan).

CLAUDE.md Forbidden: "Passing full ACTIVE_TASK.md to `sdlc-reviewer`."

---

### 6. Close Deploy/Ship Warnings (AC-6)

**Before:** `close` warned only on missing Observation blocks. Skipped deploy/ship was silently archived.

**After:** Two new non-blocking warnings before archive:
- `## Deploy Checklist` empty → "deploy phase was never run — archiving without deploy artifact"
- `## Post-Deploy` empty → "ship phase was never run — no smoke-test evidence in archive"

Non-blocking by design — hotfix and docs tasks legitimately skip deploy/ship.

---

### 7. Deferred MEDIUM Findings Chain (AC-7)

**Before:** MEDIUM findings deferred in `review` disappeared into the archive. Next task had no awareness of them.

**After:** Two-part chain:

**`review`:** MEDIUM findings not fixed inline are tagged `[deferred]` in the findings list.

**`close`:** Collects all `[deferred]` items from `## Review Findings`. Writes them to task-log as a `## Deferred` section. Archive output format updated.

**`task`:** At start of every invocation, checks latest task-log for `## Deferred`. If non-empty:
> "Previous task deferred N issues — inherit as AC candidates? (y/n)"
Lists items. On yes: prepends as candidate ACs. On no/no task-log: proceeds silently.

---

### 8. SKILL_REGISTRY.md Updated (AC-8)

Skills table `Reads` and `Key Observation Signal` columns updated for: `task`, `grill`, `risk`, `code`, `review`, `close`.

---

## What Did NOT Change

- Phase order — all workflows unchanged
- ACTIVE_TASK.md schema — same 9 sections
- Agent definitions — sdlc-investigator, sdlc-reviewer, sdlc-secops, sdlc-context-builder unchanged
- Hard-block gates — all prior gates preserved; new gates added on top
- Observation block protocol — format unchanged; `planning-gate` field added to risk Observation only
- Task archival format — same slug/date/type pattern; `## Deferred` section added to archive

---

## File Inventory

**Modified (8 files):**
```
.claude/skills/risk/SKILL.md    planning gate + section-scoped reads + pattern compression
.claude/skills/grill/SKILL.md   Phase 0 batch-resolve + section-scoped reads
.claude/skills/code/SKILL.md    planning-gate hard-block + section-scoped reads + pattern compression
.claude/skills/review/SKILL.md  reviewer context extraction + MEDIUM deferred tagging + section-scoped reads + pattern compression
.claude/skills/close/SKILL.md   deploy/ship warnings + deferred collection + pattern compression
.claude/skills/task/SKILL.md    deferred findings check + pattern compression
docs/SKILL_REGISTRY.md          updated reads + signals for 6 skills
CLAUDE.md                       phase gating table + 3 new Forbidden entries
```

---

---

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

---

# Hooks Integration

**Date:** 2026-06-15
**Scope:** 5 Claude Code hooks added — deterministic phase gating, session context injection, inline secops scanning, verify-fail capture, git pre-commit interlock

---

## What Changed

### New: `.claude/hooks/` directory (5 files)

All hooks are shell scripts, executable, wired into `.claude/settings.local.json`.

#### `load-context.sh` — SessionStart context injection

Fires on every session start (new + resume). Parses ACTIVE_TASK.md, finds last Observation block, injects a one-line harness state summary into the context window via `additionalContext`:

```
HARNESS STATE: phase=testing/verify | done-signal=test-run-output | next=/review | verdict=PASS (external-evidence)
```

Prevents cold re-read of full ACTIVE_TASK.md each session. Clean state emits `"no active task. Run /task to start."` instead.

#### `phase-gate.sh` — PreToolUse Bash gate

Fires before every Bash tool call. Detects skill invocations (`/code`, `/verify`, `/review`, `/audit`, `/deploy`, `/ship`, `/close`) and checks ACTIVE_TASK.md Observation blocks against required prior-phase gates. Blocks with exit 2 if gate not satisfied — error message fed back to Claude:

```
PHASE GATE BLOCKED: /review requires verify PASS verdict (external-evidence).
Current state: ## Test Results has no PASS Observation. Run /verify first.
```

Gate table:

| Skill | Required prior evidence |
|-------|------------------------|
| `/code` | `## Design` Observation present |
| `/verify` | `## Test Results` Observation with `done-signal: coverage-report` |
| `/review` | verify Observation with `verdict: PASS` + `verdict-source: external-evidence` |
| `/audit` | `## Review Findings` Observation present |
| `/deploy` | No unresolved CRITICAL in `## Review Findings` |
| `/ship` | `## Deploy Checklist` Observation present |
| `/close` | `## Requirement` + `## Review Findings` both populated |

This is the hook-layer enforcement of the same gates already embedded in each SKILL.md — double fence.

#### `secops-scan.sh` — PostToolUse Write/Edit scanner

Fires asynchronously after every Write or Edit tool call on source files. Skips `.claude/`, `task-log/`, `docs/`, `examples/`, and all `*.md`/`*.json`/`*.yaml` files. Runs three regex passes:

- **Secrets:** `(api_key|secret|password|token|private_key)\s*[=:]\s*["'][^"']{8,}`
- **Dangerous patterns:** `eval(|subprocess shell=True|dangerouslySetInnerHTML|innerHTML =|yaml.load(|pickle.loads(`
- **PII in logs:** `console.log/print/logger.* email|password|ssn|token`

Non-blocking — emits warning output only. Hard gate remains `sdlc-secops` during `/review`. This hook gives early feedback during implementation before review phase.

#### `verify-fail-capture.sh` — UserPromptSubmit verify-fail injector

Fires on every prompt submission. When prompt matches `/verify` and ACTIVE_TASK.md already has a `verdict: FAIL` Observation in `## Test Results`, injects prior failure blockers into context window before Claude responds:

```
PREVIOUS /verify RESULT: FAIL
Blockers from last run:
  - AC#2: E2E test missing for email uniqueness
  - Coverage: 72% (target 85%)
Fix blockers before re-running /verify. Common fixes: run /tdd for missing E2E tests, run /refactor if coverage is below target.
```

No-op when last verify passed or no prior verify run exists.

#### `pre-commit.template` — Git pre-commit hook template

Not a Claude Code hook — standard git hook. Copy to `.git/hooks/pre-commit` + `chmod +x` to install. Blocks `git commit` when ACTIVE_TASK.md is in an early phase with no test evidence:

- No active task → allow
- Phase `intake/task`, `planning/*`, `implementation/code` (no tests) → **block**
- Phase `implementation/tdd` or `testing/*` (tests exist, verify not run) → warn, allow
- Phase `testing/verify` with `verdict: FAIL` → **block**
- Phase `testing/verify` with `verdict: PASS` or later → allow
- No Observation blocks → warn, allow (legacy state)

Override: `git commit --no-verify` (intentional escape hatch, visible in message).

---

### Modified: `.claude/settings.local.json`

Added `hooks` section wiring all 4 Claude Code hooks:

```json
"hooks": {
  "SessionStart":    [{ "hooks": [{ "type": "command", "command": "...load-context.sh",        "timeout": 10, "statusMessage": "Loading harness state..." }] }],
  "PreToolUse":      [{ "matcher": "Bash",       "hooks": [{ "type": "command", "command": "...phase-gate.sh",          "timeout": 10 }] }],
  "PostToolUse":     [{ "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "...secops-scan.sh",         "timeout": 15, "async": true }] }],
  "UserPromptSubmit":[{ "hooks": [{ "type": "command", "command": "...verify-fail-capture.sh", "timeout": 10 }] }]
}
```

---

## What Was Skipped and Why

| Idea | Decision | Reason |
|------|----------|--------|
| MCP Data-Fetch (Jira/Linear on /task) | Skipped | Requires external MCP server per-project; harness is tool-agnostic |
| Headless auto-refactor loop on verify fail | Skipped | Auto-revert without human confirmation violates clean-state principle; verify-fail hook surfaces failures instead |
| CI post-merge auto-close | Skipped | CI environment is project-specific; document as reference pattern in INTEGRATION_GUIDE.md |

---

## What Did NOT Change

- All 16 SKILL.md files — hooks add a second enforcement layer, not a replacement
- ACTIVE_TASK.md schema — unchanged
- Phase order — unchanged
- Agent definitions — unchanged
- Observation block protocol — hooks read these but do not write them

---

## File Inventory

**Created (5 files):**
```
.claude/hooks/load-context.sh
.claude/hooks/phase-gate.sh
.claude/hooks/secops-scan.sh
.claude/hooks/verify-fail-capture.sh
.claude/hooks/pre-commit.template
```

**Modified (1 file):**
```
.claude/settings.local.json    added hooks section (SessionStart, PreToolUse, PostToolUse, UserPromptSubmit)
```

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
