# Deploy Checklist

Generate a pre-deploy checklist from review findings: environment config, migration steps, rollback plan, and go/no-go gate.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Review Findings`
Writes: `ACTIVE_TASK.md` → `## Deploy Checklist`

**Hard block:** If `## Review Findings` is empty:
> "Run `review` first. Output required in ACTIVE_TASK.md → ## Review Findings."

**Hard block:** If any CRITICAL finding in `## Review Findings` is unresolved:
> "Resolve all CRITICAL findings in ## Review Findings before deploying."

## Agent Delegation

Run `sdlc-secops` as a final pre-deploy gate scan before generating the checklist. This catches any secrets or dangerous patterns that were introduced after `audit` ran (e.g., a last-minute config change, an env-var default added in a fixup commit).

**Hard block if secops returns CRITICAL_BLOCK** — a secret in a deploy commit is an incident, not a checklist item.

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Review Findings`: extract findings, verdicts, security verdict, resolved/unresolved status.

**Analyze:**
- What environment variables or secrets need to be set in prod?
- Are there DB schema changes requiring migration before or after deploy?
- What is the rollback procedure if deploy fails?
- What smoke tests confirm the deploy succeeded?
- Are there downstream services or consumers that need notification?
- What monitoring/alerting should be checked post-deploy?

**Generate:**
1. **Pre-deploy gate** — secops scan result + confirm all CRITICAL/HIGH findings resolved
2. **Environment checklist** — env vars, secrets, config values to set
3. **Migration steps** — ordered DB or infra changes with rollback for each
4. **Deploy steps** — ordered deployment commands
5. **Smoke tests** — minimal checks to confirm deploy is live and healthy
6. **Rollback plan** — exact steps to revert if smoke tests fail
7. **Notification list** — who to inform before/after deploy

## Pattern

```javascript
const reviewFindings = readActiveTask("## Review Findings");
if (!reviewFindings) hardBlock("review");
if (hasCriticalUnresolved(reviewFindings)) stop("Resolve all CRITICAL findings in ## Review Findings before deploying.");

// Final pre-deploy secrets scan — catches fixup commits post-audit
const secopsGate = await agent("deploy — final secrets and compliance scan before deploy", {
  agentType: "sdlc-secops",
  label: "secops:pre-deploy"
});

if (secopsGate.verdict === "CRITICAL_BLOCK") {
  stop(`Pre-deploy secops scan found blockers:\n${secopsGate.blockers}\nResolve before deploying.`);
}

const checklist = await agent(enrichedMetaPrompt(reviewFindings, secopsGate), { schema: DEPLOY_CHECKLIST_SCHEMA });
// Output: { gate, envChecklist, migrationSteps, deploySteps, smokeTests, rollbackPlan, notifications }

writeActiveTask("## Deploy Checklist", checklist);
```

## Trigger Points

- After `audit` completes and all CRITICAL findings are resolved
- User says "deploy checklist", "pre-deploy", "ready to ship?"
- Before any production deployment

## Output

Writes to `ACTIVE_TASK.md → ## Deploy Checklist`:
- Go/no-go gate (finding resolution status)
- Environment config checklist
- Migration steps with rollback
- Deploy steps
- Smoke tests
- Rollback plan
- Notification list

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Review Findings; hard block if empty
- [ ] Hard block if any CRITICAL finding unresolved in ## Review Findings
- [ ] Spawn `sdlc-secops` (phase: "deploy") — final scan for secrets in fixup commits
- [ ] Hard block if secops returns CRITICAL_BLOCK — resolve before proceeding
- [ ] Include secops gate result in Pre-deploy Gate section of checklist
- [ ] List env vars and secrets needed in prod environment
- [ ] List DB/infra migration steps in safe order (with per-step rollback)
- [ ] Write deploy steps (stack-specific: Docker, k8s, Heroku, etc.)
- [ ] Define smoke tests (at minimum: health endpoint + one happy-path request)
- [ ] Write rollback plan (exact commands, not just "revert")
- [ ] Identify who to notify (team, stakeholders, downstream consumers)
- [ ] Write checklist to ACTIVE_TASK.md → ## Deploy Checklist
- [ ] Next: run `ship`

## Example

**Input (from ACTIVE_TASK.md → ## Review Findings):**
```
Code Review Verdict: APPROVED_WITH_CHANGES (CRITICAL fixed, IMPORTANT fixed)
Security Verdict: FINDINGS_REQUIRE_FIX (HIGH fixed, MEDIUM pending)
No unresolved CRITICAL findings.
```

**Output (written to ACTIVE_TASK.md → ## Deploy Checklist):**
```
### Go/No-Go Gate: ✅ CLEAR
All CRITICAL and HIGH findings resolved. MEDIUM (response schema) fixed in PR #42.

### Environment Config
- [ ] SECRET_KEY — set in prod secrets manager (not .env)
- [ ] DATABASE_URL — verify points to prod DB, not staging
- [ ] ALLOWED_ORIGINS — set to prod frontend domain

### Migration Steps
1. [ ] Backup prod DB snapshot before migration
2. [ ] Run: `alembic upgrade head` (adds users table + is_active column)
   Rollback: `alembic downgrade -1`
3. [ ] Verify migration: `SELECT COUNT(*) FROM users;` returns 0 (new table)

### Deploy Steps
1. [ ] `docker build -t user-api:v1.2.0 .`
2. [ ] `docker push registry/user-api:v1.2.0`
3. [ ] `kubectl set image deployment/user-api user-api=registry/user-api:v1.2.0`
4. [ ] `kubectl rollout status deployment/user-api`

### Smoke Tests
- [ ] GET /health → 200 OK
- [ ] POST /users { email, password } → 201 with id
- [ ] POST /auth/token { email, password } → 200 with access_token

### Rollback Plan
1. `kubectl rollout undo deployment/user-api`
2. `alembic downgrade -1` (if migration ran)
3. Restore DB snapshot if data corruption suspected

### Notifications
- [ ] Notify #backend-team in Slack before deploy window
- [ ] Notify API consumers: no breaking changes in this release
```

---

*Next: `ship` (Integration phase).*
