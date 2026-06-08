# Decision Grill

Relentless interactive ADR session. Walk every branch of the design tree. One decision at a time: present numbered options + recommendation, wait for developer to pick, move to next. Never auto-decide. Never stop early — cover the full design, not just flagged questions.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design`, codebase (when a decision can be resolved by reading existing code)
Writes: `ACTIVE_TASK.md` → `## ADRs`

**Hard block:** If `## Design` is empty:
> "Run `/design` first. Output required in ACTIVE_TASK.md → ## Design."

## Core Rules

1. **You are a facilitator, not a decision-maker.** Propose options and a recommendation — the developer decides. Never write an ADR until the developer confirms.
2. **Walk the full design tree.** Don't stop at flagged open questions. Every component, interface contract, tech stack choice, and data flow decision is fair game.
3. **Explore the codebase before asking.** If a decision can be resolved by reading existing code (existing patterns, already-chosen libraries, schema in use), read it and skip the question — or pre-answer it with evidence.
4. **Dependency order.** Foundational decisions first. Never present a question that depends on an unanswered earlier question.

## Session Flow

```
Before first question:
  - Read ACTIVE_TASK.md → ## Design (and ## Requirement for constraints)
  - Scan codebase for existing patterns relevant to the design
  - Map ALL decision points across the full design tree (not just openQuestions)
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
  - "Next: run /risk"
```

**One question per message. Never batch multiple decisions in one output.**

## Question Format

Present each decision exactly like this:

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

  3. [Option name] — [one-line description] (if applicable)
     Pros: [key strengths]
     Cons: [key weaknesses]

★ Recommendation: Option [N] — [reason in one sentence, tied to constraints/timeline/stack]

Reply with the option number, or describe a custom choice.
```

## Rules for Options

- 2–4 options max per decision. Don't pad with non-viable options.
- Order options from most to least conventional/safe.
- Recommendation must reference a constraint from `## Design` or `## Requirement` (timeline, team size, existing stack, reversibility). Never recommend based on general preference alone.
- If a constraint makes one option clearly forced, say so: "Option 2 is forced — your existing stack uses X."
- If the codebase already resolves the question, skip the options format entirely: `"Resolved from codebase: [file:line evidence]. Recording as ADR-NNN."` Then move on.

## Decision Tree Scope

These branches must all be walked — not just the `openQuestions` list in `## Design`:

- **Tech stack choices** — libraries, frameworks, versions not yet pinned
- **Component interfaces** — how components communicate (REST vs events, sync vs async)
- **Data model decisions** — schema shape, normalization, storage format
- **Error handling strategy** — fail-fast vs graceful, retry policy
- **Auth / security surface** — who can call what, token strategy, secret management
- **Observability** — logging format, metrics, tracing (if in scope)
- **Deployment / config** — env var strategy, feature flags, rollout approach

Skip a branch only if the design explicitly settled it with no alternatives — and note the skip.

## After Developer Picks

Acknowledge with one line: `"Recorded: [Option name]. [One-sentence consequence note if non-obvious.]"`

Then immediately present the next decision. No commentary, no summary, no re-explanation of what was just decided.

## ADR Write Format

After all decisions are collected, write to `ACTIVE_TASK.md → ## ADRs`:

```
### ADR-[NNN]: [Decision Title]
Context: [why this decision was needed]
Options: [comma-separated list]
Decision: [chosen option]
Rationale: [developer's choice + constraint that drove it]
Consequences: [what this means going forward]
Rejected: [other options] — [why each was not chosen]
```

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design and ## Requirement; hard block if Design empty
- [ ] Scan codebase for existing patterns that resolve any decisions preemptively
- [ ] Map full decision tree (all branches, not just openQuestions); order by dependency
- [ ] For each decision: check codebase first → if resolved, record and skip; else present numbered options + recommendation, STOP and wait
- [ ] After each developer pick: acknowledge in one line, move to next immediately
- [ ] Cover all branches: stack, interfaces, data model, error handling, auth, observability, deployment
- [ ] After all decisions: write ADRs to ACTIVE_TASK.md → ## ADRs in one pass
- [ ] Next: run `/risk`

## Example Exchange

**Grill presents:**
```
Decision 1/2: Password Hashing Algorithm

Need to hash passwords at signup and verify at login. Stack is Python (FastAPI).
No existing hashing library in use.

Options:
  1. bcrypt — industry standard, widely supported
     Pros: battle-tested, broad library support (passlib)
     Cons: not OWASP's top pick for new systems, CPU-bound only

  2. argon2id — OWASP recommended for new systems
     Pros: memory-hard (GPU-resistant), OWASP top pick
     Cons: slightly higher memory per login, less familiar

★ Recommendation: Option 2 — greenfield project, no migration cost, OWASP alignment strengthens security posture.

Reply with the option number, or describe a custom choice.
```

**Developer:** `2`

**Grill responds:**
```
Recorded: argon2id. Higher memory use per login (~64MB default) — acceptable at your scale.

Decision 2/2: Token Storage Strategy
...
```

---

*After all decisions: write ADRs, then suggest `/risk`.*
