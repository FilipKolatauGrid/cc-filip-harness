---
name: risk
description: Risk assessment — identify, score, and plan mitigations for technical, timeline, and dependency risks using the design and locked ADRs. Use when the user says "what could go wrong?", "assess risks", "risk register", "what are the risks?", or after `grill` completes. Always run before implementation begins. Hard-blocks if ADRs are not locked — unresolved decisions are risk multipliers.
---

# Risk Assessment

Identify, score, and plan mitigations for technical, timeline, and dependency risks using the design and ADRs as input.

## Principles in Play

**Agents overreach and under-finish.** Risk assessment hard-blocks on unlocked ADRs. Assessing risk on undecided design is overreach — the risks are undefined until decisions are locked.

**Agents declare victory too early.** Risk is not a rubber stamp. Top 3 risks must be explicitly surfaced with mitigations — not buried in a table. If any risk is HIGH severity with no mitigation, the skill surfaces it as a blocker before implementation.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design` and `## ADRs`
Writes: `ACTIVE_TASK.md` → `## Risks`

**Hard block:** If `## Design` is empty:
> "Run `design` first. Output required in ACTIVE_TASK.md → ## Design."

**Hard block:** If `## ADRs` is empty:
> "Run `grill` first. Output required in ACTIVE_TASK.md → ## ADRs."

**Hard block:** If `## ADRs` does not contain the locked sentinel `<!-- ADRs LOCKED`:
> "ADRs not locked. All design decisions must be confirmed before risk assessment. Re-run `grill` to complete the decision session."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Design` and `## ADRs`: extract components, tech decisions, constraints, rejected options, ADR consequences.

**Analyze:**
- What external dependencies could fail or change?
- What ADR consequences introduce risk (see "Consequences" in each ADR)?
- What timeline or team-size constraints create delivery risk?
- What are the hardest-to-reverse technical decisions?
- What assumptions are load-bearing but unverified?

**Generate:**
1. **Risk registry** — each risk: id, description, category, likelihood (H/M/L), impact (H/M/L), severity (H×I), mitigation, owner
2. **Top 3 risks** — highest severity, called out explicitly with mitigation steps
3. **Assumptions log** — unverified assumptions that, if wrong, create a risk
4. **Blocking risks** — any risk that should pause implementation until mitigated

## Pattern

```javascript
const design = readActiveTask("## Design");
const adrs = readActiveTask("## ADRs");
if (!design) hardBlock("design");
if (!adrs) hardBlock("grill");
if (!adrs.includes("<!-- ADRs LOCKED")) hardBlock("grill — ADRs not locked");

const risks = await agent(enrichedMetaPrompt(design, adrs), { schema: RISK_SCHEMA });
writeActiveTask("## Risks", risks);
appendObservation("risk", { doneCriteria: "registry complete, top3 explicit, assumptions logged" });
```

## Observation Block

Append after writing `## Risks`:

```
### Observation
- phase: planning/risk
- done-signal: schema-populated
- done-criteria: risk registry present, top3 surfaced, assumptions logged, blocking-risks identified
- adrs-locked-verified: true
- verdict-source: self-reported
```

## Trigger Points

- After `grill` writes and locks ## ADRs
- User says "what could go wrong?", "assess risks", "risk register"
- Before implementation begins

## Output

Writes to `ACTIVE_TASK.md → ## Risks`:
- Risk registry (table: id, description, category, L, I, severity, mitigation)
- Top 3 highlighted risks with mitigation steps
- Assumptions log
- Blocking risks (any that should pause implementation)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## ADRs; hard block if empty or missing LOCKED sentinel
- [ ] Identify risks from: external deps, ADR consequences, timeline, team, unverified assumptions
- [ ] Score each risk: likelihood (H/M/L) × impact (H/M/L) = severity
- [ ] Write mitigation for each risk
- [ ] Call out top 3 by severity with explicit mitigation steps
- [ ] Log unverified assumptions
- [ ] Flag any blocking risks (HIGH severity with no clear mitigation)
- [ ] Write output to ACTIVE_TASK.md → ## Risks
- [ ] Append Observation block
- [ ] Next: run `code`

## Example

**Input (from ACTIVE_TASK.md → ## Design + ## ADRs):**
```
Design: FastAPI + argon2id + stateless JWT, 2-week timeline, 1 engineer
ADR-001: argon2id — consequence: higher memory per login
ADR-002: stateless JWT — consequence: tokens non-revocable
```

**Output (written to ACTIVE_TASK.md → ## Risks):**
```
### Risk Registry
| ID | Description | Category | L | I | Severity | Mitigation |
|----|-------------|----------|---|---|----------|------------|
| R-01 | argon2 memory spikes under load | Technical | L | M | Low | Tune work factor; set memory limit |
| R-02 | JWT non-revocable — compromised token valid until TTL | Security | M | H | High | Short TTL (15min); key rotation documented |
| R-03 | 2-week timeline, no migration buffer | Timeline | M | H | High | Run alembic migrations on day 1 |

### Top 3 Risks
1. R-02: JWT non-revocable (High) — mitigate: 15min TTL, key rotation procedure
2. R-03: Timeline with no migration buffer (High) — mitigate: migrate DB day 1
3. R-01: argon2 memory (Low) — mitigate: tune work factor in staging

### Assumptions Log
- Email sending not in scope (confirm with legal)
- Prod DB is PostgreSQL (inferred — verify)
```

---

*Next: `code` (Implementation phase).*
