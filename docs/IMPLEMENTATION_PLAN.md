# Claude Code SDLC Harness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, meta-prompted SDLC harness in `/Users/fkolatau/Documents/claude-code-harness/` — manual invocation, state via `ACTIVE_TASK.md`, hard phase gating, stack-agnostic, all files plain Markdown.

**Architecture:** User manually invokes skills in phase order. Each skill (1) reads `ACTIVE_TASK.md`, (2) hard-blocks if prior phase section is missing, (3) self-injects context, (4) does its work, (5) writes output to its own named section, (6) tells user what to run next. No auto-orchestration. Workflows are routing-table reference docs, not runners. State persists across sessions via `ACTIVE_TASK.md`.

**Tech Stack:** Markdown only. No frontmatter. Pattern: descriptive guidance (match `capture-requirements.md`).

---

## Key Design Decisions (post grill-me)

| Decision | Choice |
|---|---|
| Use pattern | Manual — each skill suggests next |
| State | `ACTIVE_TASK.md`, fixed schema, one section per phase |
| Phase gating | Hard block if prior section missing |
| Meta-prompter | Each skill self-injects — no separate agent file |
| Agents | Collapsed into workflow files — no `agents/` directory |
| Skill style | Descriptive guidance, concrete example I/O |
| File format | Plain Markdown, no YAML frontmatter |
| Discovery | Separate `SKILL_REGISTRY.md` |
| grill-me integration | Reference-only in `decision-grill.md` (ADR stress-test phase) |
| caveman integration | Reference-only: one line in `CLAUDE.md` + one row in `SKILL_REGISTRY.md` Meta/DX section |

---

## `ACTIVE_TASK.md` Fixed Schema

Every harness project uses this file at repo root. Skills read upstream sections and write to their own:

```markdown
# Active Task

## Requirement
<!-- capture-requirements writes here -->

## Design
<!-- architecture-design writes here -->

## ADRs
<!-- decision-grill writes here -->

## Risks
<!-- risk-assessment writes here -->

## Implementation Log
<!-- tdd writes one entry per criterion here -->

## Test Results
<!-- test-design, coverage-analysis, verification write here -->

## Review Findings
<!-- code-review + security-audit write here -->

## Deploy Checklist
<!-- deploy-checklist writes here -->

## Post-Deploy
<!-- post-deploy writes here -->
```

---

## File Map

### Skills (14 files — 1 exists, 13 to create)

```
.claude/skills/
  intake/
    capture-requirements.md    ← EXISTS (update: add ACTIVE_TASK read/write steps)
    init-project.md            ← Task 1
  planning/
    architecture-design.md     ← Task 2
    decision-grill.md          ← Task 3
    risk-assessment.md         ← Task 4
  implementation/
    code-gen.md                ← Task 5
    tdd.md                     ← Task 6
    refactor.md                ← Task 7
  testing/
    test-design.md             ← Task 8
    coverage-analysis.md       ← Task 9
    verification.md            ← Task 10
  review/
    code-review.md             ← Task 11
    security-audit.md          ← Task 12
  integration/
    deploy-checklist.md        ← Task 13
    post-deploy.md             ← Task 14
```

### Workflows (4 files — embed routing + phase sequence)

```
.claude/workflows/
  full-sdlc.md                 ← Task 15
  bug-fix.md                   ← Task 15
  feature-build.md             ← Task 15
  refactor.md                  ← Task 15
```

### Docs + Config (4 files)

```
docs/
  SKILL_REGISTRY.md            ← Task 16
examples/
  python-cli-walkthrough.md    ← Task 17
  typescript-api-walkthrough.md ← Task 17
CLAUDE.md                      ← Task 18
```

**No `agents/` directory.** Agent logic embedded in workflow files.

---

## Canonical Skill Structure

Every skill (except `capture-requirements.md`) follows this exact pattern:

```markdown
# [Skill Name]

[One-line description]

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## [Prior Section]`
Writes: `ACTIVE_TASK.md` → `## [This Section]`

**Hard block:** If `## [Prior Section]` is empty → stop and tell user:
> "Run [prior-skill] first. Output required in ACTIVE_TASK.md → ## [Prior Section]."

## Meta-Prompt

Given [prior section content from ACTIVE_TASK.md]:

**Analyze:**
- [What to analyze]

**Generate:**
1. [Output 1]
2. [Output 2]

## Pattern

[Pseudocode showing self-injection from ACTIVE_TASK.md + agent call + output shape]

## Trigger Points

- [When to invoke this skill]

## Output

Write to `ACTIVE_TASK.md → ## [This Section]`:
- [What gets written]

## Checklist

- [ ] Read ACTIVE_TASK.md, confirm prior section populated
- [ ] [Task-specific item 1]
- [ ] [Task-specific item 2]
- [ ] Write output to ACTIVE_TASK.md → ## [This Section]
- [ ] Next: run [next-skill]

## Example

**Input (from ACTIVE_TASK.md → ## [Prior Section]):**
[concrete example]

**Output (written to ACTIVE_TASK.md → ## [This Section]):**
[concrete example]
```

---

## Task 0: Update `capture-requirements.md`

**File:** Modify `.claude/skills/intake/capture-requirements.md`

Add the Prerequisites block and ACTIVE_TASK write step — it's the first skill so no hard block, but it must write to `## Requirement`.

- [x] **Step 1: Add Prerequisites block after the H1 description**

```markdown
## Prerequisites

Reads: nothing (entry point)
Writes: `ACTIVE_TASK.md` → `## Requirement`

**Note:** Create `ACTIVE_TASK.md` at project root if it doesn't exist. Use the fixed schema from the harness `CLAUDE.md`.
```

- [x] **Step 2: Add write step to Checklist**

Append to existing checklist:
```markdown
- [ ] Write structured output to ACTIVE_TASK.md → ## Requirement
- [ ] Next: run `init-project` (new project) or `architecture-design` (existing project)
```

- [x] **Step 3: Commit**

```bash
cd /Users/fkolatau/Documents/claude-code-harness
git add .claude/skills/intake/capture-requirements.md
git commit -m "feat(skills): add ACTIVE_TASK write step to capture-requirements"
```

---

## Task 1: `init-project` Skill (Intake)

**File:** Create `.claude/skills/intake/init-project.md`

**Reads:** `ACTIVE_TASK.md → ## Requirement`
**Writes:** nothing to ACTIVE_TASK (scaffold output is file system) — logs scaffold summary to `## Requirement` as addendum
**Hard block:** if `## Requirement` empty → tell user to run `capture-requirements` first

**What it does:** Given structured requirement, scaffold project structure — directory layout, config files, tooling, `ACTIVE_TASK.md` with fixed schema — for any tech stack.

- [x] **Step 1: Write the skill file**

```markdown
# Init Project

Scaffold project structure from a structured requirement: directories, config files, tooling, ACTIVE_TASK.md — stack-agnostic.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement`
Writes: project file system + appends scaffold summary to `ACTIVE_TASK.md → ## Requirement`

**Hard block:** If `## Requirement` is empty:
> "Run `capture-requirements` first. Output required in ACTIVE_TASK.md → ## Requirement."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Requirement`: extract `type`, `goal`, `techStack`, `constraints`.

**Analyze:**
- What tech stack is specified or implied?
- What project type? (CLI, REST API, frontend, library, microservice)
- What testing framework is standard for this stack?
- What minimum config files are needed to build + test?

**Generate:**
1. **Directory tree** — recommended layout for this stack and project type
2. **Config file list** — e.g., `package.json`, `pyproject.toml`, `Cargo.toml`
3. **`ACTIVE_TASK.md`** — copy the fixed schema template into project root
4. **`CLAUDE.md` content** — build, test, lint commands for this stack
5. **First commit checklist** — which files to create before writing any feature code
6. **Questions** — clarifications needed (e.g., monorepo? Docker?)

## Pattern

```javascript
// Self-inject from ACTIVE_TASK.md
const requirement = readActiveTask("## Requirement");
if (!requirement) hardBlock("capture-requirements");

// Generate scaffold
const scaffold = await agent(enrichedMetaPrompt, { schema: SCAFFOLD_SCHEMA });
// Output: { directoryTree, configFiles, claudeMdContent, firstCommitChecklist, questions }

// Write scaffold summary back to ACTIVE_TASK → ## Requirement as addendum
appendToActiveTask("## Requirement", `\n### Scaffold\n${scaffold.summary}`);
```

## Trigger Points

- After `capture-requirements` outputs structured requirement
- User says "scaffold", "init", "set up project structure", "create new project"
- Greenfield project with no existing structure

## Output

Appends scaffold summary to `ACTIVE_TASK.md → ## Requirement`:
- Directory tree
- Config files to create
- First commit checklist

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Detect or confirm tech stack
- [ ] Generate directory structure appropriate for stack + project type
- [ ] List required config files with minimal viable content
- [ ] Draft CLAUDE.md with build + test + lint commands
- [ ] Produce first-commit checklist
- [ ] Ask clarifying questions for ambiguous choices
- [ ] Append scaffold summary to ACTIVE_TASK.md → ## Requirement
- [ ] Next: run `architecture-design`

## Example

**Input (ACTIVE_TASK.md → ## Requirement):**
```
type: feature, goal: "Build a REST API for user management",
techStack: "Python/FastAPI", constraints: { timeline: "2 weeks" }
```

**Output (appended to ## Requirement):**
```
### Scaffold
- directoryTree: src/, src/main.py, src/routes/, src/models/, tests/, pyproject.toml
- configFiles: pyproject.toml (FastAPI + pytest + ruff), .env.example
- claudeMd: "Build: uvicorn src.main:app | Test: pytest | Lint: ruff check ."
- firstCommitChecklist: [pyproject.toml, src/main.py stub, tests/conftest.py]
```

---

*Next: `architecture-design` (Planning phase).*
```

- [x] **Step 2: Verify structure matches canonical pattern** (Prerequisites, Meta-Prompt, Pattern, Trigger Points, Output, Checklist, Example with hard block shown, footer)

- [x] **Step 3: Commit**

```bash
git add .claude/skills/intake/init-project.md
git commit -m "feat(skills): add init-project intake skill"
```

---

## Tasks 2–14: Planning, Implementation, Testing, Review, Integration Skills

Follow canonical skill structure for each. Pattern: read prior section → hard block → self-inject → generate → write → suggest next skill.

**Task 2:** `architecture-design.md` — Reads `## Requirement` → Writes `## Design`
**Task 3:** `decision-grill.md` — Reads `## Design` → Writes `## ADRs`
**Task 4:** `risk-assessment.md` — Reads `## Design` + `## ADRs` → Writes `## Risks`
**Task 5:** `code-gen.md` — Reads `## Design` → Writes to filesystem + logs to `## Implementation Log`
**Task 6:** `tdd.md` — Reads `## Requirement` + `## Implementation Log` → Appends to `## Implementation Log`
**Task 7:** `refactor.md` — Reads `## Implementation Log` → Appends to `## Implementation Log`
**Task 8:** `test-design.md` — Reads `## Requirement` + `## Implementation Log` → Writes `## Test Results` (plan section)
**Task 9:** `coverage-analysis.md` — Reads `## Test Results` → Appends gap analysis to `## Test Results`
**Task 10:** `verification.md` — Reads `## Requirement` + `## Test Results` → Appends matrix + verdict to `## Test Results`
**Task 11:** `code-review.md` — Reads `## Test Results` + git diff → Writes `## Review Findings`
**Task 12:** `security-audit.md` — Reads `## Review Findings` + git diff → Appends to `## Review Findings`
**Task 13:** `deploy-checklist.md` — Reads `## Review Findings` → Writes `## Deploy Checklist`
**Task 14:** `post-deploy.md` — Reads `## Deploy Checklist` → Writes `## Post-Deploy`

Each skill:
- Follows canonical structure template
- Includes Prerequisites block with hard block logic
- Shows pseudocode self-injection from ACTIVE_TASK.md
- Concrete example with Input from ACTIVE_TASK section, Output written to own section

---

## Task 15: Workflow Files

**Files:** Create 4 files in `.claude/workflows/`

Each workflow is a routing-table reference doc — describes phase sequence, gate conditions, decision points, rollback paths. Not an auto-runner.

**`full-sdlc.md`:** Intake → Planning (architecture → decision-grill → risk-assessment) → Implementation (code-gen → tdd → refactor) → Testing (test-design → coverage-analysis → verification) → Review (code-review → security-audit) → Integration (deploy-checklist → deploy → post-deploy). Gates at each phase. Rollback paths on review failure or post-deploy failure.

**`bug-fix.md`:** Intake (type=bugfix) → Debug (reproduce → isolate → root-cause) → Implementation (tdd: write failing test, fix) → Verification → Code-review → Deploy. No planning unless architectural change needed.

**`feature-build.md`:** Intake → Planning (architecture → decision-grill) → Implementation → Testing → Review → Integration. Skips risk-assessment for small features (optional). Same gates as full-sdlc.

**`refactor.md`:** Intake (type=refactor) → Coverage-analysis (BEFORE refactoring) → Risk-assessment → Refactor → Verification → Code-review. No deployment unless config/DB touched. Tests must pass before refactor begins.

---

## Task 16: `SKILL_REGISTRY.md`

**File:** Create `docs/SKILL_REGISTRY.md`

Single-page lookup index. Table format: Name | Phase | File | Trigger | Reads from ACTIVE_TASK | Writes to ACTIVE_TASK. One row per skill, one per workflow. Enables quick "what skill handles X?" lookup.

---

## Task 17: Example Walkthroughs

**Files:** Create `examples/python-cli-walkthrough.md` and `examples/typescript-api-walkthrough.md`

Narrative showing harness applied end-to-end on two stacks. Shows actual `ACTIVE_TASK.md` section outputs at each phase. Proves agnosticism.

**python-cli:** Task "Add CSV export to a Python CLI tool" — shows requirement → design (CSVExporter component) → ADRs (streaming vs. load-all) → implementation log (tdd test + impl) → test results (3 criteria, all pass, 87% coverage) → review findings (1 minor naming issue) → deploy checklist (PyPI packaging, docs).

**typescript-api:** Task "Add rate limiting to TypeScript REST API" — same flow, NestJS/Jest context. Shows how meta-prompt injects `techStack` and generates different output (ThrottlerModule, Jest patterns, NestJS guards) vs. Python example.

---

## Task 18: `CLAUDE.md` + Update `README.md`

**File:** Create `CLAUDE.md` at repo root; update `README.md`

**CLAUDE.md:**
- Session init: read HARNESS_DESIGN.md, SKILL_REGISTRY.md
- How to use: start with capture-requirements, or jump to workflow for your task type
- State: all outputs in ACTIVE_TASK.md (fixed schema)
- Gates: every skill hard-blocks if prior section missing
- Skill pattern: read → guard → self-inject → write → suggest next
- Forbidden: skip phase order, skip verification, skip review before deploy

**README.md:** Update status checklist — check off each item as tasks complete.

---

## Verification

After all tasks complete:

**1. File count check**
```bash
find /Users/fkolatau/Documents/claude-code-harness/.claude -name "*.md" | sort
# Expected: 14 skills + 4 workflows = 18 files
```

**2. Pattern check** — open any 3 skill files, each must have: Prerequisites (with hard block), Meta-Prompt (with self-inject from ACTIVE_TASK), Checklist (read+guard as first item, write+next as last items), Example with Input labeled "(from ACTIVE_TASK.md → ## [Section])".

**3. Registry completeness** — open `SKILL_REGISTRY.md`, verify all 15 skills + 4 workflows appear.

**4. ACTIVE_TASK schema** — verify the fixed schema in `CLAUDE.md` matches all section names referenced across all skill Prerequisites blocks.

**5. End-to-end trace** — read `examples/python-cli-walkthrough.md`, follow each ACTIVE_TASK section forward through the registry, confirm every section gets populated in order.

---

## Summary

| Category | Count | Tasks |
|---|---|---|
| Skills | 14 (1 updated, 13 created) | Tasks 0–14 |
| Workflows | 4 | Task 15 |
| Docs/Examples | 4 | Tasks 16–18 |
| **Total files** | **22** | **19 tasks** |

Key changes from original plan:
- No `agents/` directory — orchestration embedded in workflows
- Every skill self-injects from `ACTIVE_TASK.md` — no separate meta-prompter invocation
- Hard phase gating on every skill
- `ACTIVE_TASK.md` fixed schema is the state backbone
