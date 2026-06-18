# Harness Architecture

Component model, data flow, and design rationale for the Claude Code SDLC Harness.

---

## Component Model

```
┌─────────────────────────────────────────────────────┐
│                    CLAUDE.md                        │
│         Primary agent instruction file              │
│  (session init, principles, phase gates, forbidden) │
└────────────────────┬────────────────────────────────┘
                     │ loads at session start
         ┌───────────┼───────────┐
         ▼           ▼           ▼
    Skills        Agents      Hooks
  (.claude/      (.claude/   (.claude/
   skills/)       agents/)    hooks/)
         │           │           │
         └───────────┼───────────┘
                     ▼
              ACTIVE_TASK.md
         (single source of task state)
                     │
                     ▼
              task-log/ + context/
           (archive + codebase snapshot)
```

**Skills** — user-invocable prompt units. Each skill reads a section of ACTIVE_TASK.md,
performs its phase, writes its output back, and appends an Observation block.
Skills enforce sequential phase order via hard blocks.

**Agents** — spawned by skills for specialized work. Never invoked directly.
Four agents: `sdlc-investigator` (locate), `sdlc-reviewer` (diff review),
`sdlc-secops` (security scan), `sdlc-context-builder` (snapshot generation).

**Hooks** — shell scripts wired into Claude Code's hook system. Run automatically
on tool calls and session events. Enforce rules the instruction file cannot enforce
alone (e.g., phase gates at the tool-execution layer, async security scans).

**ACTIVE_TASK.md** — the state machine. Fixed nine-section schema. One section
per SDLC phase. Skills read their upstream section and write their own. Only
`close` reads the full file.

---

## Data Flow Through a Full SDLC Cycle

```
User input
    │
    ▼
/task ──writes──▶ ## Requirement
    │
    ▼
/design ──reads──▶ ## Requirement
        ──writes──▶ ## Design
    │
    ▼
/grill ──reads──▶ ## Design (scoped)
       ──writes──▶ ## ADRs
    │
    ▼
/risk ──reads──▶ ## Design + ## ADRs
      ──writes──▶ ## Risks  [planning-gate: confirmed]
    │                ↑ phase-gate.sh checks this before /code
    ▼
/code ──reads──▶ ## Design + ## Requirement
      ──writes──▶ filesystem + ## Implementation Log
    │
    ▼
/tdd + /tests + /coverage + /verify
      ──reads──▶ ## Requirement + ## Implementation Log
      ──writes──▶ ## Test Results  [verdict: PASS, verdict-source: external-evidence]
    │                ↑ phase-gate.sh checks this before /review
    ▼
/review + /audit
      ──reads──▶ diff + extracted AC + ## Test Results (scoped)
      ──writes──▶ ## Review Findings
    │
    ▼
/deploy + /ship
      ──reads──▶ ## Review Findings + ## Deploy Checklist
      ──writes──▶ ## Deploy Checklist + ## Post-Deploy
    │
    ▼
/close ──reads──▶ full ACTIVE_TASK.md
       ──writes──▶ task-log/  +  .claude/context/  +  ACTIVE_TASK.md (reset)
```

---

## Key Design Decisions

### Why Markdown prompts instead of code?

The harness must work for any language, framework, or project type. A Python-based
harness would require Python. A TypeScript-based one requires Node. Markdown files
have no runtime dependency — they are read by Claude Code directly, which is already
the required tool. Skills can instruct the agent to run any language's toolchain
without the harness itself depending on it.

### Why ACTIVE_TASK.md (flat Markdown file) instead of a database or JSON?

Three reasons:
1. **Claude Code native access** — agents read files directly; no API layer needed.
2. **Git-diffable** — task state is committed; every state transition is auditable.
3. **Human-readable** — a developer can read, edit, or debug state without tooling.

The tradeoff is that the file can become large for complex tasks. The section-scoped
read boundaries in each skill (only read your own section, not the whole file) mitigate
context bloat.

### Why Observation blocks?

Self-reported phase completion ("I implemented X") cannot be verified by downstream
skills. Observation blocks are structured fields that downstream skills can parse:
`verdict-source: external-evidence` means test-runner output was present; `self-reported`
means it wasn't. This enables programmatic gating — phase-gate.sh checks Observation
fields, not section prose.

### Why agents over inline skill logic?

Four operations are expensive on the main context window: file discovery
(`sdlc-investigator`), diff review (`sdlc-reviewer`), security scanning (`sdlc-secops`),
and context snapshot generation (`sdlc-context-builder`). Delegating to sub-agents keeps
each skill's context small and allows parallel execution where the work is independent.

---

## Local Development Environment

The harness has no local development environment in the traditional sense — it is
itself configuration, not an application. There is no database, no server, no runtime
to start.

What a developer does need locally:
- **Claude Code CLI** — the runtime that executes skills
- **Git** — for task archival and context tracking
- **Bash** — for hook execution (hooks/*.sh)
- **Docker** (optional) — only if the *project being developed with the harness* requires it

For projects using the harness that DO have a local environment, use `/local-env-requirements`
to produce a containerized setup specification. See `docs/local-environment.md` (generated
by that skill) for the project-specific requirements.

---

## Harness Health

Run `/validate-harness` to score the harness against the foundational checklist (32 checks,
7 sections). Report written to `reports/harness-validation-report.md`.

The `harness-change-detect.sh` hook fires whenever a harness file is edited and reminds
the session to re-run `/validate-harness` to measure the impact of the change.

Target score: ≥ 85% (Solid band).
