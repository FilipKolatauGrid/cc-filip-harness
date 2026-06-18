---
name: validate-harness
description: >
  Validate the AI agent harness in this repository and produce a structured
  markdown report. Only invoke this skill when the user explicitly runs the
  /validate-harness slash command.
user-invocable: true
allowed-tools: Bash, Read, Write, Glob
---

# Validate Harness

Read-only inspection of the repository harness; produce a scored validation report at `reports/harness-validation-report.md`.

## Principles in Play

**Observability inside the harness.** This skill is itself an observability primitive — it produces external evidence of harness completeness rather than relying on self-reported assessments. The report score is the `verdict-source`.

**Agents declare victory too early.** The validator exists to surface gaps the harness author may have normalized. Score below 65% means the harness is not reliable enough for production sessions.

## Prerequisites

Reads: repository files (read-only — no source file modifications)
Writes: `reports/harness-validation-report.md` (creates `reports/` if absent)

**No ACTIVE_TASK.md phase gate.** This is a meta/diagnostic skill — it runs independently of any active task. It may run against an idle or active harness state.

**Allowed tools:** Bash, Read, Glob, Write (report file only)

---

## Phase 1 — Discovery

Collect facts before evaluating any check. Store in working memory; do not write yet.

```
REPO_ROOT        — pwd
AGENT_FILE       — first match: CLAUDE.md, AGENTS.md, .cursorrules,
                   .github/copilot-instructions.md, or NONE
AGENT_FILE_LINES — wc -l <AGENT_FILE>, or 0
DOCS_DIR         — first match: docs/, doc/, documentation/, or NONE
SKILLS_DIR       — first match: .claude/skills/, .claude/commands/, skills/, or NONE
PROGRESS_FILE    — first match: ACTIVE_TASK.md, PROGRESS.md, TASKS.md, TODO.md, or NONE
ARCH_DOC         — first match: docs/ARCHITECTURE.md, ARCHITECTURE.md,
                   docs/architecture*, or NONE
STYLE_DOC        — first match: .editorconfig, .eslintrc*, .ruff.toml,
                   pyproject.toml, .prettier*, styleguide.md, STYLE.md, or NONE
README           — first match: README.md, README.rst, README.txt, or NONE
HARNESS_TYPE     — "prompt-harness" if SKILLS_DIR contains *.md files and no
                   *.ts/*.py/*.js source files exist at repo root; else "app-repo"
```

Use `Glob` and `Bash` (find, wc -l, head -n 50) for discovery. Do not read entire large files.

---

## Phase 2 — Evaluate Checks

Evaluate every check. For each, produce one of: `PASS`, `FAIL`, `PARTIAL`, `N/A`.

Record a one-sentence **finding** and one-sentence **recommendation** for every non-PASS result.
PASS results need only a short evidence note.

**Section B special rule:** If `HARNESS_TYPE = prompt-harness`, mark B1–B5 as `N/A` with note:
`"Prompt-only harness — no runtime artifact; install/run/lint commands handled by meta-prompting inside skills."`
B6 (build/deploy) remains evaluated.

### Section A — Entry point

| ID | Check | How to evaluate |
|----|-------|----------------|
| A1 | Primary agent instruction file exists at repo root | AGENT_FILE ≠ NONE |
| A2 | File is tracked in git (not gitignored) | `git ls-files <AGENT_FILE>` returns the file |
| A3 | File opens with project overview (purpose, not just rules) | `head -n 20 <AGENT_FILE>` contains prose description |
| A4 | File is ≤ 150 lines | AGENT_FILE_LINES ≤ 150 |
| A5 | Hard constraints appear in first 50 lines | `head -n 50 <AGENT_FILE>` contains at least one explicit prohibition |

### Section B — Developer operations

| ID | Check | How to evaluate |
|----|-------|----------------|
| B1 | Dependency install command documented | Search AGENT_FILE + README for: install, npm, pip, yarn, bundle; `N/A` if prompt-harness |
| B2 | Local start/run command documented | Search for: start, run, serve, dev, `npm run`, `python`; `N/A` if prompt-harness |
| B3 | Test command explicitly stated | Search for: test, pytest, jest, rspec; `N/A` if prompt-harness |
| B4 | Lint or type-check command documented | Search for: lint, eslint, ruff, mypy; `N/A` if prompt-harness — but check if shell scripts in hooks/ would benefit from shellcheck |
| B5 | Composite verification command or CI pipeline exists | Search for: `make check`, `.github/workflows/`, `.gitlab-ci.yml`; `N/A` if prompt-harness |
| B6 | Build or deploy steps documented or linked | Search for: build, deploy, ship skill, pipeline; prompt-harness: evaluate whether deploy/ship skills exist |

### Section C — Repository documentation

| ID | Check | How to evaluate |
|----|-------|----------------|
| C1 | Architecture or system structure documentation exists | ARCH_DOC ≠ NONE |
| C2 | AGENT_FILE links to supporting docs rather than inlining everything | AGENT_FILE contains relative links (`[`, `./docs`, `see`) to other files |
| C3 | Technology and design choices are explained with rationale | Sample ARCH_DOC or README for: "because", "chosen", "prefer", "instead of" |
| C4 | Code style or editor conventions captured | STYLE_DOC ≠ NONE |

### Section D — State and progress tracking

| ID | Check | How to evaluate |
|----|-------|----------------|
| D1 | A progress or task tracking file exists | PROGRESS_FILE ≠ NONE |
| D2 | The file records live status (done/in-progress/blocked/idle) | Sample PROGRESS_FILE for status keywords, Observation blocks, or idle sentinel |
| D3 | Tasks use structured format | PROGRESS_FILE is JSON, or contains Markdown tables / Observation blocks |
| D4 | Progress file is committed in git | `git ls-files <PROGRESS_FILE>` returns the file |

### Section E — Staged workflow

| ID | Check | How to evaluate |
|----|-------|----------------|
| E1 | Initialization phase defined | Search for: init skill, init.sh, INIT.md, setup phase in AGENT_FILE |
| E2 | Agent instructed to orient before coding | Search AGENT_FILE for session-start sequence: "read", "orient", "session init", "load" |
| E3 | Agent constrained to one task per session | Search AGENT_FILE for: "one task", "one feature", "single task", "reset.*before" |
| E4 | Session-end clean state defined | Search AGENT_FILE for: "close", "commit", "clean state", "archive", "reset" |
| E5 | Completion criteria defined | Search AGENT_FILE for: "done when", "acceptance", "verified", "passes", "evidence" |

### Section F — Reusable skills and modular structure

| ID | Check | How to evaluate |
|----|-------|----------------|
| F1 | Skills or commands directory exists | SKILLS_DIR ≠ NONE |
| F2 | Skills referenced from AGENT_FILE | AGENT_FILE contains references to files in SKILLS_DIR |
| F3 | Hierarchical instruction files exist for major subdirectories | `find . -name "CLAUDE.md" -not -path "./.git/*"` returns > 1 file |

### Section G — SDLC coverage

| ID | Check | How to evaluate |
|----|-------|----------------|
| G1 | Feature implementation guidance present | Search AGENT_FILE + SKILLS_DIR for: "implement", "feature", "code skill" |
| G2 | Bug investigation guidance present | Search for: "bug", "debug", "reproduce", "fix", "investigate" |
| G3 | Testing expectations documented | Search for: "test", "e2e", "end-to-end", "must pass", "evidence" |
| G4 | Self-verification or review steps defined | Search for: "review", "verify", "self-check", "before marking done" |
| G5 | Documentation update expectations stated | Search for: "update docs", "update progress", "write to", "document" |

---

## Phase 3 — Score

```
PASS_COUNT    = count of PASS results
PARTIAL_COUNT = count of PARTIAL results
FAIL_COUNT    = count of FAIL results
NA_COUNT      = count of N/A results
SCORED        = PASS_COUNT + PARTIAL_COUNT + FAIL_COUNT
SCORE_PCT     = round((PASS_COUNT + 0.5 * PARTIAL_COUNT) / SCORED * 100)  if SCORED > 0 else N/A
```

Maturity band:

| Score | Band |
|-------|------|
| 85–100% | **Solid** |
| 65–84% | **Developing** |
| 40–64% | **Minimal** |
| < 40% | **Absent** |

---

## Phase 4 — Write Report

Create `reports/` if needed. Write to `reports/harness-validation-report.md` using this exact template:

````markdown
# Harness Validation Report

**Repository:** {{REPO_ROOT}}  
**Primary instruction file:** {{AGENT_FILE}} ({{AGENT_FILE_LINES}} lines)  
**Harness type:** {{HARNESS_TYPE}}  
**Validated on:** {{ISO_DATE}}  
**Validator:** Claude Code — harness-validate skill  

---

## Summary

| Metric | Value |
|--------|-------|
| Checks evaluated | {{SCORED}} of 32 |
| PASS | {{PASS_COUNT}} |
| PARTIAL | {{PARTIAL_COUNT}} |
| FAIL | {{FAIL_COUNT}} |
| N/A (skipped) | {{NA_COUNT}} |
| **Score** | **{{SCORE_PCT}} %** |
| **Maturity band** | **{{BAND}}** |

> {{ONE_SENTENCE_OVERALL_ASSESSMENT}}

---

## Section A — Entry point

| ID | Check | Result | Notes |
|----|-------|--------|-------|
| A1 | Primary agent instruction file exists | {{A1}} | {{A1_NOTES}} |
| A2 | File is tracked in git | {{A2}} | {{A2_NOTES}} |
| A3 | File opens with project overview | {{A3}} | {{A3_NOTES}} |
| A4 | File is ≤ 150 lines | {{A4}} | {{A4_NOTES}} |
| A5 | Hard constraints in first 50 lines | {{A5}} | {{A5_NOTES}} |

{{A_FINDINGS}}

---

## Section B — Developer operations

| ID | Check | Result | Notes |
|----|-------|--------|-------|
| B1 | Dependency install command documented | {{B1}} | {{B1_NOTES}} |
| B2 | Local start/run command documented | {{B2}} | {{B2_NOTES}} |
| B3 | Test command explicitly stated | {{B3}} | {{B3_NOTES}} |
| B4 | Lint or type-check command documented | {{B4}} | {{B4_NOTES}} |
| B5 | Composite verification command exists | {{B5}} | {{B5_NOTES}} |
| B6 | Build/deploy steps documented or linked | {{B6}} | {{B6_NOTES}} |

{{B_FINDINGS}}

---

## Section C — Repository documentation

| ID | Check | Result | Notes |
|----|-------|--------|-------|
| C1 | Architecture documentation exists | {{C1}} | {{C1_NOTES}} |
| C2 | AGENT_FILE links to supporting docs | {{C2}} | {{C2_NOTES}} |
| C3 | Technology choices are explained | {{C3}} | {{C3_NOTES}} |
| C4 | Code style config or doc exists | {{C4}} | {{C4_NOTES}} |

{{C_FINDINGS}}

---

## Section D — State and progress tracking

| ID | Check | Result | Notes |
|----|-------|--------|-------|
| D1 | Progress/task tracking file exists | {{D1}} | {{D1_NOTES}} |
| D2 | Progress file records status | {{D2}} | {{D2_NOTES}} |
| D3 | Tasks use structured format | {{D3}} | {{D3_NOTES}} |
| D4 | Progress file is tracked in git | {{D4}} | {{D4_NOTES}} |

{{D_FINDINGS}}

---

## Section E — Staged workflow

| ID | Check | Result | Notes |
|----|-------|--------|-------|
| E1 | Initialization phase defined | {{E1}} | {{E1_NOTES}} |
| E2 | Agent instructed to orient before coding | {{E2}} | {{E2_NOTES}} |
| E3 | Agent constrained to one task per session | {{E3}} | {{E3_NOTES}} |
| E4 | Session-end clean state defined | {{E4}} | {{E4_NOTES}} |
| E5 | Completion criteria defined | {{E5}} | {{E5_NOTES}} |

{{E_FINDINGS}}

---

## Section F — Reusable skills and modular structure

| ID | Check | Result | Notes |
|----|-------|--------|-------|
| F1 | Skills or commands directory exists | {{F1}} | {{F1_NOTES}} |
| F2 | Skills referenced from AGENT_FILE | {{F2}} | {{F2_NOTES}} |
| F3 | Hierarchical instruction files exist | {{F3}} | {{F3_NOTES}} |

{{F_FINDINGS}}

---

## Section G — SDLC coverage

| ID | Check | Result | Notes |
|----|-------|--------|-------|
| G1 | Feature implementation guidance present | {{G1}} | {{G1_NOTES}} |
| G2 | Bug investigation guidance present | {{G2}} | {{G2_NOTES}} |
| G3 | Testing expectations documented | {{G3}} | {{G3_NOTES}} |
| G4 | Self-verification steps defined | {{G4}} | {{G4_NOTES}} |
| G5 | Documentation update expectations stated | {{G5}} | {{G5_NOTES}} |

{{G_FINDINGS}}

---

## Priority actions

{{PRIORITY_ACTIONS}}

---

## Reference

This report was produced against the foundational harness engineering checklist covering entry point quality, developer operations, documentation, state tracking, staged workflow, modular structure, and SDLC coverage.

### Observation
- phase: utility/validate-harness
- done-signal: report-written
- done-criteria: all 32 checks evaluated, score computed, report file written
- score: {{SCORE_PCT}}%
- band: {{BAND}}
- report-path: reports/harness-validation-report.md
- verdict-source: filesystem-check
````

After writing the file, print one line:

```
Harness validation complete. Report written to reports/harness-validation-report.md — score {{SCORE_PCT}}% ({{BAND}}).
```

Do not print the report body.

---

## Observation Block

This skill writes its Observation inside the report file (not ACTIVE_TASK.md). No ACTIVE_TASK.md writes. The report is the sole output artifact.

## Trigger Points

- User runs `/validate-harness` explicitly
- User says "run the harness validator", "check harness health", "score the harness"

## Checklist

- [ ] Collect all DISCOVERY variables (pwd, Glob, find, wc -l)
- [ ] Detect HARNESS_TYPE — auto-set B1–B5 to N/A if prompt-harness
- [ ] Evaluate all 32 checks; record PASS/FAIL/PARTIAL/N/A + finding + recommendation for each non-PASS
- [ ] Compute SCORE_PCT and BAND
- [ ] Create `reports/` if needed
- [ ] Write report to `reports/harness-validation-report.md` (exact template, all placeholders filled)
- [ ] Print single summary line to terminal
- [ ] Do NOT modify any source files

*Next: review `reports/harness-validation-report.md`. Address FAIL items via the appropriate harness skill or manual edit.*
