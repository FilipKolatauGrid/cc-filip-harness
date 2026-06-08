# Post-Deploy

Validate a completed deployment: confirm smoke tests pass, monitor for regressions, close the loop on ACTIVE_TASK.md.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Deploy Checklist`
Writes: `ACTIVE_TASK.md` → `## Post-Deploy`

**Hard block:** If `## Deploy Checklist` is empty:
> "Run `deploy` first. Output required in ACTIVE_TASK.md → ## Deploy Checklist."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Deploy Checklist`: extract smokeTests, rollbackPlan, monitoringTargets, notifications.

**Analyze:**
- Did all smoke tests pass?
- Are error rates, latency, and resource usage within normal bounds post-deploy?
- Were any unexpected behaviors observed in the first minutes after deploy?
- Were all required notifications sent?
- Is rollback needed?

**Generate:**
1. **Smoke test results** — each test: pass / fail / timeout
2. **Monitoring snapshot** — key metrics at T+5min, T+15min, T+30min
3. **Incident flag** — if any smoke test failed or metric spiked: rollback decision
4. **Notification confirmation** — who was notified and when
5. **Task closure** — final status of ACTIVE_TASK, link to PR/commit, lessons learned

## Pattern

```javascript
const deployChecklist = readActiveTask("## Deploy Checklist");
if (!deployChecklist) hardBlock("deploy");

const smokeResults = await runSmokeTests(deployChecklist.smokeTests);
const metrics = await checkMonitoring(deployChecklist.monitoringTargets);

if (smokeResults.anyFailed || metrics.anyAnomalous) {
  await executeRollback(deployChecklist.rollbackPlan);
}

const postDeploy = await agent(enrichedMetaPrompt(smokeResults, metrics), {
  schema: POST_DEPLOY_SCHEMA
});

writeActiveTask("## Post-Deploy", postDeploy);
```

## Trigger Points

- Immediately after deployment completes
- User says "ship", "verify deploy", "deployment done"
- Monitoring alerts fire after a deploy

## Output

Writes to `ACTIVE_TASK.md → ## Post-Deploy`:
- Smoke test results (pass/fail per test)
- Monitoring snapshot (error rate, latency, resource use)
- Rollback decision (executed or not needed)
- Notification log
- Task closure (status, PR link, lessons learned)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Deploy Checklist; hard block if empty
- [ ] Run each smoke test from ## Deploy Checklist; record pass/fail
- [ ] Check monitoring: error rate, p95 latency, CPU/memory vs. baseline
- [ ] If any smoke test fails or metric anomalous: execute rollback plan immediately
- [ ] Confirm all notifications from checklist were sent; send any pending
- [ ] Record T+5, T+15, T+30 monitoring snapshots
- [ ] Write final task status: DEPLOYED / ROLLED_BACK
- [ ] Note lessons learned (what would improve next deploy)
- [ ] Write results to ACTIVE_TASK.md → ## Post-Deploy

## Example

**Input (from ACTIVE_TASK.md → ## Deploy Checklist):**
```
Smoke Tests: [GET /health, POST /users, POST /auth/token]
Rollback Plan: kubectl rollout undo + alembic downgrade -1
Notifications: #backend-team, API consumers
```

**Output (written to ACTIVE_TASK.md → ## Post-Deploy):**
```
### Smoke Tests
- GET /health → 200 OK ✅
- POST /users { email, password } → 201 ✅
- POST /auth/token { email, password } → 200 ✅

### Monitoring Snapshot
| Metric | Baseline | T+5min | T+15min | T+30min | Status |
|--------|----------|--------|---------|---------|--------|
| Error rate | 0.1% | 0.1% | 0.1% | 0.1% | ✅ |
| p95 latency | 45ms | 48ms | 46ms | 45ms | ✅ |
| CPU | 12% | 18% | 14% | 13% | ✅ |

### Rollback: Not needed

### Notifications
- #backend-team notified at 14:32 UTC ✅
- API consumer email sent at 14:35 UTC ✅

### Task Closure
Status: ✅ DEPLOYED
Commit: abc1234 — feat: user management REST API
PR: #42 (merged)
Lessons learned: alembic migration took 8min on prod data volume — add index before migration next time.
```
