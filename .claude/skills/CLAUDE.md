# Skills Directory

This directory contains the canonical skill units for the Claude Code SDLC Harness.
Each subdirectory is one skill. Each skill has exactly one `SKILL.md` file.

---

## What a Skill Is

A skill is a self-contained prompt unit that handles one phase of the SDLC.
It is the authoritative definition of what that phase does, what it reads, what it writes,
and what evidence it produces.

Skills are **not** code. They are instructions that Claude Code executes as an agent.

---

## Required SKILL.md Structure

Every skill must have these sections in this order:

```markdown
---
name: <skill-name>
description: >
  <one-paragraph trigger description — this text appears in the skill registry
   and controls when Claude Code auto-invokes the skill>
user-invocable: true|false
allowed-tools: <comma-separated list>
---

# <Skill Title>

<One sentence: what this skill does and why it exists in the SDLC.>

## Principles in Play

<Which of the 7 AI-native engineering principles this skill enforces, and how.>

## Prerequisites

Reads: <section(s) of ACTIVE_TASK.md or files read>
Writes: <section(s) of ACTIVE_TASK.md or files written>

<Hard block conditions — exact error message the skill emits.>

## Meta-Prompt

<The self-injection pattern: which fields are extracted from upstream sections,
 what the skill analyzes, what it generates. This is the core of the skill.>

## Pattern

<Pseudocode or numbered steps showing the execution sequence.>

## Observation Block

<Exact Observation block the skill appends, with all required fields.>

## Checklist

<Numbered or bulleted checklist — every item the skill must complete.
 Last item must be: "Append Observation block".
 Second-to-last must be: "Write output to ACTIVE_TASK.md → ## <Section>".>

## Trigger Points

<When this skill should be invoked — user phrases, workflow position, conditions.>

*Next: `<next-skill>` (<context>).*
```

---

## The 8-Step Skill Pattern

Every SDLC skill follows this execution sequence:

```
1. Read ACTIVE_TASK.md → required upstream section
2. Hard block if that section is empty (with exact error message)
3. Check prior phase Observation block — hard block if evidence missing
4. Self-inject: extract relevant fields into working context
5. Generate output with external evidence where required
6. Write to ACTIVE_TASK.md → own section
7. Append Observation block with done-signal + verdict-source
8. Tell user: "Next: run [next-skill]"
```

Meta/utility skills (e.g. `validate-harness`) are exempt from steps 1–3 and 6–8
if they have no ACTIVE_TASK.md integration. They must still produce an Observation
block — written to their own output artifact.

---

## Observation Block Fields

```markdown
### Observation
- phase: <category/skill-name>          # e.g. planning/design, testing/verify
- done-signal: <signal>                 # see signal vocabulary below
- done-criteria: <what constitutes completion>
- verdict-source: <self-reported | external-evidence>
```

**Signal vocabulary** (highest trust first):
- `external-evidence` — test runner output, filesystem check, tool output
- `filesystem-check` — file written and verified to exist
- `report-written` — output artifact written (utility skills)
- `coverage-report` — coverage tool output present
- `test-run-output` — actual test runner output present
- `schema-populated` — structured fields written to ACTIVE_TASK.md section
- `self-reported` — no external verification (lowest trust; blocks downstream if required)

Downstream skills that gate on a prior phase read the Observation `done-signal` and
`verdict-source` fields — not just the section prose.

---

## Phase Gate Contract

| Skill | Must find before running | Writes |
|-------|--------------------------|--------|
| `design` | `## Requirement` non-empty | `## Design` |
| `grill` | `## Design` Observation | `## ADRs` |
| `risk` | `## ADRs` (locked sentinel) | `## Risks` + `planning-gate: confirmed` |
| `code` | `planning-gate: confirmed` in `## Risks` Observation | `## Implementation Log` |
| `verify` | `coverage-report` Observation in `## Test Results` | appends to `## Test Results` |
| `review` | `verdict: PASS` + `verdict-source: external-evidence` in `## Test Results` | `## Review Findings` |
| `deploy` | `## Review Findings` + no CRITICAL unresolved | `## Deploy Checklist` |
| `close` | `## Requirement` + `## Review Findings` non-empty | task-log/ + reset |

---

## Adding a New Skill

1. Create `.claude/skills/<name>/SKILL.md` using the structure above
2. Add the skill to the table in `docs/SKILL_REGISTRY.md`
3. Add the skill to the File Map in `docs/HARNESS_REFERENCE.md`
4. Reference it in `CLAUDE.md` if it changes the session-start sequence
5. Run `/validate-harness` to measure harness impact

See `docs/META_PROMPTING.md` for meta-prompting patterns and examples.
