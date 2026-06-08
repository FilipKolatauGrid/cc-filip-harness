# Decision Grill

Interactive ADR session: one decision at a time. Present numbered options + recommendation, wait for developer to pick, then move to the next. Never auto-decide.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design`
Writes: `ACTIVE_TASK.md` → `## ADRs`

**Hard block:** If `## Design` is empty:
> "Run `/design` first. Output required in ACTIVE_TASK.md → ## Design."

## Core Rule

**You are a facilitator, not a decision-maker.** For every open question, you propose options and a recommendation — the developer decides. Never write an ADR until the developer has confirmed their choice.

## Session Flow

```
1. Read ACTIVE_TASK.md → ## Design
2. Extract all open questions
3. Order by dependency (foundational decisions first)
4. For each decision:
   a. Present the question with numbered options + recommendation (see format below)
   b. STOP. Wait for developer response.
   c. Developer replies with a number (or describes a custom choice)
   d. Confirm the choice, record the ADR internally
   e. Move to the next decision
5. After ALL decisions collected → write ## ADRs to ACTIVE_TASK.md in one pass
6. Tell developer: "Next: run /risk"
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
- Recommendation must reference a constraint from ## Design or ## Requirement (timeline, team size, existing stack, reversibility). Never recommend based on general preference alone.
- If a constraint makes one option clearly forced, say so: "Option 2 is forced — your existing stack uses X."

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

- [ ] Read ACTIVE_TASK.md → ## Design; hard block if empty
- [ ] Extract open questions; order by dependency
- [ ] For each decision: present numbered options + recommendation, STOP and wait
- [ ] Record developer's choice after each answer
- [ ] After all choices collected: write ADRs to ACTIVE_TASK.md → ## ADRs
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
