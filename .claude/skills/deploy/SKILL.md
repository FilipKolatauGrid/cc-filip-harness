---
name: deploy
description: Deploy checklist — generate pre-deploy checklist from review findings with environment config, migration steps, rollback plan, smoke tests, and go/no-go gate. Use when the user says "deploy checklist", "pre-deploy", "ready to ship?", "generate deploy plan", or after `audit` completes and all CRITICAL findings are resolved. Runs a final `sdlc-secops` scan before generating the checklist — a last-minute fixup commit could introduce a secret. Hard-blocks if review findings are missing or have unresolved CRITICALs.
---

# Deploy Checklist

Generate a pre-deploy checklist from review findings: environment config, migration steps, rollback plan, and go/no-go gate.

## Principles in Play

**Every session must leave clean state.** Deploy is only reached when all CRITICAL findings are resolved and the security audit is complete. No shortcuts. A blocked deploy checklist is informative — it means the gate was correctly enforced.

**Observability inside harness.** A final `sdlc-secops` scan runs at deploy time — not just at review/audit. A last-minute fixup commit may have introduced a secret. The scan result is recorded in the checklist so anyone reading the deploy log knows when it ran and what it found.

**Agents declare victory too early.** Go/no-go is not self-declared. It is derived from: audit Observation verdict + final secops scan verdict + resolved CRITICAL status. Three independent signals.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Review Findings`
Writes: `ACTIVE_TASK.md` → `## Deploy Checklist`

**Hard block:** If `## Review Findings` is empty:
> "Run `review` first. Output required in ACTIVE_TASK.md → ## Review Findings."

**Hard block:** If `## Review Findings` does not contain a `### Security Audit Findings` section:
> "Run `audit` first. Security audit required in ## Review Findings before deploying."

**Hard block:** If audit Observation block `done-signal` is not `secops-scan`:
> "Security audit shows no completion evidence. Re-run `audit` before deploying."

**Hard block:** If any CRITICAL finding in `## Review Findings` is unresolved:
> "Resolve all CRITICAL findings in ## Review Findings before deploying."

## Agent Delegation

Run `sdlc-secops` as a final pre-deploy gate scan. Catches secrets in fixup commits introduced after `audit` ran.

**Hard block if secops returns CRITICAL_BLOCK** — a secret in a deploy commit is an incident, not a checklist item.

## Pattern

```javascript
const reviewFindings = readActiveTask("## Review Findings");
if (!reviewFindings) hardBlock("review");
if (!hasSecurityAuditSection(reviewFindings)) hardBlock("audit");

const auditObs = getObservation(reviewFindings, "audit");
if (!auditObs || auditObs.doneSig !== "secops-scan") {
  hardBlock("Audit evidence missing. Re-run `audit` first.");
}
if (hasCriticalUnresolved(reviewFindings)) {
  hardBlock("Resolve all CRITICAL findings before deploying.");
}

// Final pre-deploy scan — catch fixup-commit secrets
const finalScan = await agent("deploy — final secrets and compliance scan before deploy", {
  agentType: "sdlc-secops",
  label: "secops:pre-deploy"
});

if (finalScan.verdict === "CRITICAL_BLOCK") {
  hardBlock(`Final pre-deploy scan found critical issues:\n${finalScan.blockers}\nResolve before deploying.`);
}

const checklist = await agent(enrichedMetaPrompt(reviewFindings, finalScan), { schema: DEPLOY_CHECKLIST_SCHEMA });
writeActiveTask("## Deploy Checklist", checklist);
appendObservation("deploy", {
  doneCriteria: "final secops scan clean, all gates passed, checklist generated"
});
```

## Observation Block

Append after writing `## Deploy Checklist`:

```
### Observation
- phase: integration/deploy
- done-signal: secops-scan
- done-criteria: final secops clean, all CRITICAL resolved, checklist complete with rollback plan
- final-secops-verdict: CLEAR|FINDINGS_REQUIRE_FIX|CRITICAL_BLOCK
- all-criticals-resolved: true
- rollback-plan-present: true
- smoke-tests-defined: true
- verdict-source: external-evidence (secops agent + gate checks)
```

## Trigger Points

- After `audit` completes and all CRITICAL findings are resolved
- User says "deploy checklist", "pre-deploy", "ready to ship?"
- Before any production deployment

## Output

Writes to `ACTIVE_TASK.md → ## Deploy Checklist`:
- Go/no-go gate with final scan result
- Environment config checklist
- Migration steps with rollback per step
- Deploy steps
- Smoke tests
- Rollback plan (exact commands)
- Notification list

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Review Findings; hard block if empty
- [ ] Verify Security Audit section present in ## Review Findings — hard block if missing
- [ ] Check audit Observation block — hard block if `done-signal` not `secops-scan`
- [ ] Hard block if any CRITICAL finding unresolved
- [ ] Spawn `sdlc-secops` (phase: "deploy") — final scan for fixup-commit secrets
- [ ] Hard block if final scan returns CRITICAL_BLOCK
- [ ] List env vars and secrets needed in prod environment
- [ ] List DB/infra migration steps in safe order (with per-step rollback)
- [ ] Write deploy steps (stack-specific)
- [ ] Define smoke tests (at minimum: health endpoint + one happy-path request)
- [ ] Write rollback plan (exact commands, not just "revert")
- [ ] Identify who to notify
- [ ] Write checklist + Observation block to ACTIVE_TASK.md → ## Deploy Checklist
- [ ] Next: run `ship`

---

*Next: `ship` (Integration phase).*
