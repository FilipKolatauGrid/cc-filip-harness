# Decision Grill

Stress-test open design decisions from ## Design by producing Architecture Decision Records (ADRs) for each, using relentless one-at-a-time interrogation.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design`
Writes: `ACTIVE_TASK.md` → `## ADRs`

**Hard block:** If `## Design` is empty:
> "Run `design` first. Output required in ACTIVE_TASK.md → ## Design."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Design`: extract `openQuestions`, `techStack`, `components`, `constraints`.

**Analyze:**
- What decisions from ## Design were flagged as open questions?
- What are the alternatives for each decision?
- What constraints force or eliminate options?
- What are the consequences of each choice (reversibility, performance, complexity)?

**Generate:**
1. **ADR per open question** — decision title, context, options considered, chosen option, rationale, consequences
2. **Dependency order** — resolve foundational decisions before dependent ones
3. **Rejected options log** — why each alternative was ruled out

**Invoke grill-me:** For each open question, apply the grill-me pattern — propose your recommended answer with rationale, then interrogate your own reasoning. One decision at a time.

## Pattern

```javascript
const design = readActiveTask("## Design");
if (!design) hardBlock("design");

const openQuestions = extractOpenQuestions(design);

// For each decision: grill-me pattern — recommend + interrogate
const adrs = await agent(enrichedMetaPrompt, { schema: ADR_SCHEMA });
// Output: [{ id, title, context, options, decision, rationale, consequences }]

writeActiveTask("## ADRs", adrs);
```

## Trigger Points

- After `design` flags open questions in ## Design
- User says "what are the tradeoffs?", "help me decide X", "grill me on this design"
- Before implementation begins on any decision point

## Output

Write to `ACTIVE_TASK.md → ## ADRs`:
- One ADR per decision (numbered: ADR-001, ADR-002, …)
- Each ADR: title, context, options, decision, rationale, consequences
- Rejected options with reasons

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design; hard block if empty
- [ ] Extract open questions from ## Design
- [ ] Order decisions by dependency (foundational first)
- [ ] For each decision: enumerate options, apply grill-me interrogation, recommend + rationale
- [ ] Record rejected options with reasons
- [ ] Write ADRs to ACTIVE_TASK.md → ## ADRs
- [ ] Next: run `risk`

## Example

**Input (from ACTIVE_TASK.md → ## Design):**
```
### Open Questions (→ decision-grill)
- Password hashing: bcrypt vs. argon2?
- Token storage: stateless JWT vs. refresh token DB table?
```

**Output (written to ACTIVE_TASK.md → ## ADRs):**
```
### ADR-001: Password Hashing Algorithm
Context: Need password hashing for user auth. bcrypt is standard; argon2 is newer, OWASP-recommended.
Options: bcrypt, argon2id
Decision: argon2id
Rationale: OWASP recommends argon2id for new systems; memory-hard = more resistant to GPU attacks; library support in Python via `argon2-cffi` is stable.
Consequences: Slightly higher memory use per login; no migration needed (greenfield).
Rejected: bcrypt — adequate but not OWASP top pick for new systems.

### ADR-002: Token Storage Strategy
Context: JWT can be stateless (no DB) or use refresh tokens stored in DB (revocable).
Options: stateless JWT (short TTL), refresh token table
Decision: stateless JWT (15min TTL)
Rationale: 2-week timeline; no revocation requirement in acceptance criteria; stateless = simpler ops.
Consequences: Tokens can't be revoked before TTL. Acceptable given no revocation requirement.
Rejected: refresh token table — adds schema + endpoint complexity not justified by requirements.
```

---

*Next: `risk` (Planning phase).*
