---
name: ship
description: Ship — validate a completed deployment by running smoke tests, monitoring post-deploy metrics, confirming notifications, and recording the result. Use when the user says "ship", "verify deploy", "deployment done", "check the deploy", or after a production deployment completes. Reads smoke tests and rollback plan from the deploy checklist. If any smoke test fails or a metric is anomalous, executes the rollback plan immediately — does not wait for manual intervention. Required before `close`.
---

# Post-Deploy

Validate a completed deployment: confirm smoke tests pass, monitor for regressions, close the loop on ACTIVE_TASK.md.

## Principles in Play

**Every session must leave clean state.** Ship explicitly records deploy status (DEPLOYED or ROLLED_BACK). Only after ship writes `## Post-Deploy` can `close` archive and reset `ACTIVE_TASK.md`. Ship is the last gate before clean state.

**Agents declare victory too early.** Smoke test results come from actually running the smoke tests — not from assuming they pass because the deploy command exited 0. Monitoring snapshot captures real metric values at T+5, T+15, T+30.

**Observability inside harness.** Post-Deploy Observation block records the exact deploy outcome, smoke test results, and rollback decision — so the task archive in `task-log/` has a complete, auditable record.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Deploy Checklist`
Writes: `ACTIVE_TASK.md` → `## Post-Deploy`

**Hard block:** If `## Deploy Checklist` is empty:
> "Run `deploy` first. Output required in ACTIVE_TASK.md → ## Deploy Checklist."

**Hard block:** If deploy Observation block `done-signal` is not `secops-scan`:
> "Deploy checklist shows no completion evidence. Re-run `deploy` before validating."

## Meta-Prompt

Self-inject from `## Deploy Checklist`: extract `smokeTests`, `rollbackPlan`, `notifications`, monitoring targets.

**Analyze:**
- Did all smoke tests pass?
- Are error rates, latency, and resource usage within normal bounds post-deploy?
- Were unexpected behaviors observed in first minutes after deploy?
- Were all notifications sent?
- Is rollback needed?

**Generate:**
1. **Smoke test results** — each test: pass / fail / timeout
2. **Monitoring snapshot** — key metrics at T+5, T+15, T+30
3. **Rollback decision** — if any smoke test failed or metric spiked: execute rollback immediately
4. **Notification confirmation** — who was notified and when
5. **Task closure** — final deploy status, PR/commit link, lessons learned

## Pattern

```javascript
const deployChecklist = readActiveTask("## Deploy Checklist");
if (!deployChecklist) hardBlock("deploy");

const deployObs = getObservation(deployChecklist, "deploy");
if (!deployObs || deployObs.doneSig !== "secops-scan") {
  hardBlock("Deploy checklist evidence missing. Re-run `deploy` first.");
}

const smokeResults = await runSmokeTests(deployChecklist.smokeTests);
const metrics = await checkMonitoring();

if (smokeResults.anyFailed || metrics.anyAnomalous) {
  await executeRollback(deployChecklist.rollbackPlan);
  writeActiveTask("## Post-Deploy", { status: "ROLLED_BACK", reason: smokeResults.failures });
} else {
  writeActiveTask("## Post-Deploy", { status: "DEPLOYED", smokeResults, metrics });
}

appendObservation("ship", { doneCriteria: "smoke tests run, monitoring checked, rollback decided, status recorded" });
```

## Observation Block

Append after writing `## Post-Deploy`:

```
### Observation
- phase: integration/ship
- done-signal: smoke-tests-run
- done-criteria: all smoke tests run, monitoring snapshot taken, rollback decision recorded
- smoke-tests: PASS|FAIL
- rollback-executed: true|false
- final-status: DEPLOYED|ROLLED_BACK
- verdict-source: external-evidence (smoke tests + monitoring)
```

## Trigger Points

- Immediately after deployment completes
- User says "ship", "verify deploy", "deployment done"
- Monitoring alerts fire after a deploy

## Output

Writes to `ACTIVE_TASK.md → ## Post-Deploy`:
- Smoke test results (pass/fail per test)
- Monitoring snapshot (error rate, latency, resource use at T+5/15/30)
- Rollback decision (executed or not needed)
- Notification log
- Task closure (status, PR link, lessons learned)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Deploy Checklist; hard block if empty
- [ ] Check deploy Observation block — hard block if `done-signal` not `secops-scan`
- [ ] Run each smoke test from ## Deploy Checklist; record actual pass/fail
- [ ] Check monitoring: error rate, p95 latency, CPU/memory vs. baseline
- [ ] If any smoke test fails OR metric anomalous: execute rollback plan immediately
- [ ] Confirm all notifications from checklist were sent; send pending ones
- [ ] Record T+5, T+15, T+30 monitoring snapshots
- [ ] Write final task status: DEPLOYED or ROLLED_BACK (with reason if rolled back)
- [ ] Note lessons learned
- [ ] Write results + Observation block to ACTIVE_TASK.md → ## Post-Deploy
- [ ] Next: run `close`

---

*Next: `close` (archive + reset).*
