# Security Audit

Audit the implementation for OWASP Top 10 vulnerabilities, secrets exposure, auth flaws, and input validation gaps — appends findings to ## Review Findings.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Review Findings` and current git diff
Writes: appends security findings to `ACTIVE_TASK.md → ## Review Findings`

**Hard block:** If `## Review Findings` is empty:
> "Run `review` first. Output required in ACTIVE_TASK.md → ## Review Findings."

## Agent Delegation

Spawn `sdlc-secops` with phase `"audit"`. Agent fetches diff itself, runs pattern scans across secrets / vuln patterns / compliance, returns structured findings block.

Run two passes in parallel:
1. `sdlc-secops` — mechanical pattern scan (secrets, dangerous calls, compliance drift)
2. Main thread architectural analysis — OWASP Top 10 reasoning that requires reading ACTIVE_TASK.md design context (injection data flow, auth architecture, access control design)

The secops agent is fast (haiku). Use the time it runs to do the architectural pass yourself. Merge both outputs before writing to `## Review Findings`.

**Architectural analysis (main thread — run while secops agent executes):**
- **Injection** — trace user-controlled inputs to DB/shell/template sinks via design data flow
- **Auth flaws** — token validation logic, session management against ## Design auth contracts
- **Access control** — authorization checks on every mutating endpoint vs. ## Design API contracts
- **Cryptography** — algorithm choices, key handling, IV/salt — context from ADRs
- **Dependency risk** — flag for manual `pip audit` / `npm audit` / `cargo audit`

**Severity tiers:** CRITICAL (exploitable now), HIGH (likely exploitable), MEDIUM (defense-in-depth), LOW (hardening)

## Pattern

```javascript
const reviewFindings = readActiveTask("## Review Findings");
if (!reviewFindings) hardBlock("review");

// Parallel: secops scan + main-thread architectural analysis
const [secopsFindings] = await parallel([
  () => agent("audit — scan diff for secrets, vuln patterns, compliance", {
    agentType: "sdlc-secops",
    label: "secops:audit"
  })
  // Main thread architectural analysis runs concurrently (not spawned — stays inline)
]);

// Merge secops findings + architectural findings
const mergedFindings = merge(secopsFindings, architecturalFindings);
const verdict = worstOf(secopsFindings.verdict, architecturalVerdict);

appendToActiveTask("## Review Findings", { findings: mergedFindings, securityVerdict: verdict });
```

## Trigger Points

- After `review` writes ## Review Findings
- User says "security audit", "security review", "check for vulnerabilities"
- Before `deploy` — security audit must complete before deploy

## Output

Appends to `ACTIVE_TASK.md → ## Review Findings`:
- Security findings list (path:line, severity, vuln type, fix)
- Security verdict

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Review Findings; hard block if empty
- [ ] Spawn `sdlc-secops` agent (phase: "audit") — runs pattern scan while you do architectural analysis
- [ ] Architectural analysis (main thread): injection data flow, auth design, access control, crypto choices, dep risk
- [ ] Wait for secops agent output
- [ ] Merge: secops findings (SECRET/VULN_PATTERN/COMPLIANCE) + architectural findings (OWASP)
- [ ] Take worst verdict: CRITICAL_BLOCK > FINDINGS_REQUIRE_FIX > CLEAR
- [ ] State security verdict: CLEAR / FINDINGS_REQUIRE_FIX / CRITICAL_BLOCK
- [ ] Append merged findings + verdict to ACTIVE_TASK.md → ## Review Findings
- [ ] Next: run `deploy` (if CLEAR or all CRITICAL_BLOCK resolved)

## Example

**Input (from ACTIVE_TASK.md → ## Review Findings + git diff):**
```
Code Review Verdict: APPROVED_WITH_CHANGES
Diff: src/services/auth.py, src/routers/users.py, src/repositories/user.py
```

**Output (appended to ACTIVE_TASK.md → ## Review Findings):**
```
### Security Audit Findings
src/repositories/user.py:44: HIGH: SQL Injection: raw string interpolation in search_users query — f"WHERE email LIKE '%{term}%'". Use parameterized query: .filter(User.email.like(f"%{term}%")).
src/routers/users.py:88: MEDIUM: Sensitive data exposure: full user object returned on POST /users including password_hash field. Exclude password_hash from response schema.
src/services/auth.py:12: LOW: Security misconfiguration: SECRET_KEY falls back to hardcoded "dev-secret" if env var missing. Raise startup error instead of using default.
No secrets found in diff. No CVE flags (run `pip audit` before deploy).

### Security Verdict: FINDINGS_REQUIRE_FIX
Fix HIGH before merge. MEDIUM and LOW before deploy.
```

---

*Next: `deploy` (Integration phase).*
