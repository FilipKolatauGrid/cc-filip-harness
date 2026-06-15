---
name: grill
description: Decision grill — stress-test every design decision interactively and lock them as ADRs. Use when starting the decision-making phase, when the user says "grill this", "let's decide", "what decisions do we need to make?", "ADRs", or after `design` completes. Walks the FULL design tree — not just flagged open questions. One decision per message, never auto-decides. Always reads existing codebase for decisions that can be resolved by evidence before asking. Run before `risk` and before any implementation.
---

# Decision Grill

Relentless interactive ADR session. Walk every branch of the design tree. One decision at a time: present numbered options + recommendation, wait for developer to pick, move to next. Never auto-decide. Never stop early.

## Principles in Play

**Agents declare victory too early.** Grill never self-completes — the developer must explicitly answer each decision. The ADR locked sentinel `<!-- ADRs LOCKED -->` is only appended after the developer confirms all decisions. No sentinel = no downstream gating.

**Agents overreach and under-finish.** Grill scans the codebase for decisions that can be resolved by evidence before asking. Never ask what can be read.

**Observability inside harness.** Each ADR records the developer's exact choice + the constraint that drove it. Future skills reading `## ADRs` see rationale, not just outcomes.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design` and existing codebase patterns
Writes: `ACTIVE_TASK.md` → `## ADRs`

**Hard block:** If `## Design` is empty:
> "Run `design` first. Output required in ACTIVE_TASK.md → ## Design."

**Hard block:** If `## Design` Observation block is missing or shows `done-signal: agent-declared` without schema-populated:
> "Design phase shows no completion evidence. Re-run `design` to produce a verifiable design before grilling decisions."

## Core Rules

1. **Facilitator, not decision-maker.** Present options + recommendation — developer decides. Never write an ADR until developer confirms.
2. **Full tree, not just open questions.** Every component, interface contract, tech stack choice, and data flow decision is fair game.
3. **Codebase-first.** If a decision can be resolved by reading existing code, read it. Skip or pre-answer with evidence — don't waste developer time.
4. **Dependency order.** Foundational decisions first. Never present a question that depends on an unanswered earlier decision.

## Session Flow

```
Before first question:
  - Read ACTIVE_TASK.md → ## Design (and ## Requirement for constraints)
  - Scan codebase for existing patterns relevant to the design
  - Map ALL decision points across the full design tree
  - Order by dependency (foundational first)
  - Note which can be answered from codebase → skip or pre-answer those

For each decision:
  a. If codebase resolves it: state "Resolved from codebase: [finding]. Recording as ADR." No question asked.
  b. Otherwise: present numbered options + recommendation (see format below)
  c. STOP. Wait for developer response.
  d. Developer replies with a number (or custom choice)
  e. "Recorded: [choice]. [Consequence note if non-obvious.]"
  f. Move to next decision immediately

After ALL decisions:
  - Write all ADRs to ACTIVE_TASK.md → ## ADRs in one pass
  - Append ADRs LOCKED sentinel
  - Append Observation block
  - "Next: run `risk`"
```

**One question per message. Never batch multiple decisions.**

## Question Format

```
**Decision [N/total]: [Decision Title]**

[1-2 sentences of context — why this decision matters, what constraints apply]

Options:
  1. [Option name] — [one-line description]
     Pros: [key strengths]
     Cons: [key weaknesses]

  2. [Option name] — [one-line description]
     Pros: [key strengths]
     Cons: [key weaknesses]

★ Recommendation: Option [N] — [reason tied to constraints/timeline/stack]

Reply with the option number, or describe a custom choice.
```

## Decision Tree Scope

All branches must be walked:
- **Tech stack choices** — libraries, frameworks, versions not yet pinned
- **Component interfaces** — how components communicate (REST vs events, sync vs async)
- **Data model decisions** — schema shape, normalization, storage format
- **Error handling strategy** — fail-fast vs graceful, retry policy
- **Auth / security surface** — token strategy, secret management
- **Observability** — logging format, metrics, tracing (if in scope)
- **Deployment / config** — env var strategy, feature flags, rollout approach

## ADR Write Format

```
### ADR-[NNN]: [Decision Title]
Status: locked
Context: [why this decision was needed]
Options: [comma-separated list]
Decision: [chosen option]
Rationale: [developer's choice + constraint that drove it]
Consequences: [what this means going forward]
Rejected: [other options] — [why each was not chosen]
```

After all ADRs, append sentinel:
```
<!-- ADRs LOCKED — all decisions above confirmed by developer. Modification requires explicit `grill` re-run. -->
```

**If sentinel already present:** do not modify any ADR above it. Tell user to re-run `grill` with changed constraints.

## Observation Block

Append after writing `## ADRs`:

```
### Observation
- phase: planning/grill
- done-signal: adrs-locked-sentinel-present
- done-criteria: all decision tree branches walked, each ADR has developer-confirmed rationale
- decisions-total: N
- decisions-from-codebase: N
- decisions-from-developer: N
- verdict-source: developer-confirmed
```

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design and ## Requirement; hard block if Design empty
- [ ] Check Design Observation block — hard block if missing or shows no completion evidence
- [ ] Scan codebase for existing patterns that resolve decisions preemptively
- [ ] Map full decision tree; order by dependency
- [ ] For each decision: check codebase first → if resolved, record and skip; else present options + recommendation, STOP
- [ ] After each pick: acknowledge in one line, move to next immediately
- [ ] Cover all branches: stack, interfaces, data model, errors, auth, observability, deployment
- [ ] Write ADRs in one pass to ACTIVE_TASK.md → ## ADRs
- [ ] Append ADRs LOCKED sentinel
- [ ] Append Observation block
- [ ] Next: run `risk`

---

*After all decisions: write ADRs, then suggest `risk`.*
