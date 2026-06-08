# Risk Assessment

Identify, score, and plan mitigations for technical, timeline, and dependency risks using the design and ADRs as input.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design` and `## ADRs`
Writes: `ACTIVE_TASK.md` → `## Risks`

**Hard block:** If `## Design` is empty:
> "Run `architecture-design` first. Output required in ACTIVE_TASK.md → ## Design."

**Hard block:** If `## ADRs` is empty:
> "Run `decision-grill` first. Output required in ACTIVE_TASK.md → ## ADRs."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Design` and `## ADRs`: extract components, tech decisions, constraints, rejected options, ADR consequences.

**Analyze:**
- What external dependencies could fail or change? (third-party APIs, libraries, infra)
- What ADR consequences introduce risk?
- What timeline or team-size constraints create delivery risk?
- What are the hardest-to-reverse technical decisions?
- What assumptions are load-bearing but unverified?

**Generate:**
1. **Risk registry** — each risk: id, description, category, likelihood (H/M/L), impact (H/M/L), severity (H×I), mitigation, owner
2. **Top 3 risks** — highest severity, called out explicitly
3. **Assumptions log** — unverified assumptions that, if wrong, create a risk

## Pattern

```javascript
const design = readActiveTask("## Design");
const adrs = readActiveTask("## ADRs");
if (!design) hardBlock("architecture-design");
if (!adrs) hardBlock("decision-grill");

const risks = await agent(enrichedMetaPrompt, { schema: RISK_SCHEMA });
// Output: { registry: [...], top3: [...], assumptions: [...] }

writeActiveTask("## Risks", risks);
```

## Trigger Points

- After `decision-grill` writes ## ADRs
- User says "what could go wrong?", "assess risks", "risk register"
- Before implementation begins

## Output

Write to `ACTIVE_TASK.md → ## Risks`:
- Risk registry (table: id, description, category, L, I, severity, mitigation)
- Top 3 highlighted risks
- Assumptions log

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## ADRs; hard block if empty
- [ ] Identify risks from: external deps, ADR consequences, timeline, team, unverified assumptions
- [ ] Score each risk: likelihood (H/M/L) × impact (H/M/L) = severity
- [ ] Write mitigation for each risk
- [ ] Call out top 3 by severity
- [ ] Log unverified assumptions
- [ ] Write output to ACTIVE_TASK.md → ## Risks
- [ ] Next: run `code-gen`

## Example

**Input (from ACTIVE_TASK.md → ## Design + ## ADRs):**
```
Design: FastAPI + argon2 + stateless JWT, 2-week timeline, 1 engineer
ADR-001: argon2id chosen — consequence: higher memory per login
ADR-002: stateless JWT — consequence: tokens non-revocable
```

**Output (written to ACTIVE_TASK.md → ## Risks):**
```
### Risk Registry
| ID | Description | Category | L | I | Severity | Mitigation |
|----|-------------|----------|---|---|----------|------------|
| R-01 | argon2 memory use spikes under load | Technical | L | M | Low | Tune work factor in staging; set memory limit |
| R-02 | JWT non-revocable — compromised token valid until TTL | Security | M | H | High | Short TTL (15min); rotate signing key procedure documented |
| R-03 | 2-week timeline leaves no buffer for DB migration issues | Timeline | M | H | High | Run alembic migrations on day 1; mock DB in tests |
| R-04 | Single engineer — no review coverage | Team | L | M | Low | Automated linting + test gate before merge |

### Top 3 Risks
1. R-02: JWT non-revocable (High severity) — mitigate with 15min TTL
2. R-03: Timeline with no migration buffer (High severity) — migrate DB on day 1
3. R-04: Single engineer coverage gap (Low severity) — automated gates

### Assumptions Log
- Email sending not in scope (legal said verification not required — confirm)
- Prod DB is PostgreSQL (inferred from FastAPI conventions — verify)
```

---

*Next: `code-gen` (Implementation phase).*
