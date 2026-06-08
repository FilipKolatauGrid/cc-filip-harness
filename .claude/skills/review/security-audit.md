# Security Audit

Audit the implementation for OWASP Top 10 vulnerabilities, secrets exposure, auth flaws, and input validation gaps — appends findings to ## Review Findings.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Review Findings` and current git diff
Writes: appends security findings to `ACTIVE_TASK.md → ## Review Findings`

**Hard block:** If `## Review Findings` is empty:
> "Run `code-review` first. Output required in ACTIVE_TASK.md → ## Review Findings."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Review Findings` (existing findings, verdict) and git diff of implementation files.

**Analyze across OWASP Top 10 and common patterns:**
- **Injection** — SQL, command, LDAP injection vectors in user-controlled inputs
- **Auth flaws** — broken auth, session fixation, token leakage, weak credentials policy
- **Sensitive data exposure** — secrets in code, logs, error messages, responses
- **Input validation** — unvalidated/unsanitized inputs reaching DB, filesystem, or external services
- **Access control** — missing authorization checks, IDOR vulnerabilities
- **Security misconfiguration** — debug mode, default credentials, overly permissive CORS
- **Cryptography** — weak algorithms, hardcoded keys, improper IV/salt handling
- **Dependency risk** — known CVEs in direct dependencies (flag for manual check)

**Generate:**
1. **Security findings** — `path:line: <severity>: <vulnerability type>: <description>. <fix>.`
2. **Severity tiers** — CRITICAL (exploitable now), HIGH (likely exploitable), MEDIUM (defense-in-depth), LOW (hardening)
3. **Security verdict** — CLEAR / FINDINGS_REQUIRE_FIX / CRITICAL_BLOCK

## Pattern

```javascript
const reviewFindings = readActiveTask("## Review Findings");
if (!reviewFindings) hardBlock("code-review");

const diff = await runGitDiff();

const securityFindings = await agent(enrichedMetaPrompt(reviewFindings, diff), {
  schema: SECURITY_FINDINGS_SCHEMA
});
// Output: { findings: [...], verdict: "CLEAR"|"FINDINGS_REQUIRE_FIX"|"CRITICAL_BLOCK" }

appendToActiveTask("## Review Findings", securityFindings);
```

## Trigger Points

- After `code-review` writes ## Review Findings
- User says "security audit", "security review", "check for vulnerabilities"
- Before `deploy-checklist` — security audit must complete before deploy

## Output

Appends to `ACTIVE_TASK.md → ## Review Findings`:
- Security findings list (path:line, severity, vuln type, fix)
- Security verdict

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Review Findings; hard block if empty
- [ ] Get git diff of implementation files
- [ ] Check injection vectors: SQL queries, shell commands, template rendering
- [ ] Check auth: token validation, password handling, session management
- [ ] Check sensitive data: secrets in source, PII in logs/errors, response over-sharing
- [ ] Check input validation: every user-controlled input reaching a sink
- [ ] Check access control: authorization on every mutating endpoint
- [ ] Check crypto: algorithm strength, key/salt handling, no hardcoded secrets
- [ ] Flag dependencies with potential CVEs (note: manual `pip audit` / `npm audit` recommended)
- [ ] State security verdict: CLEAR / FINDINGS_REQUIRE_FIX / CRITICAL_BLOCK
- [ ] Append findings to ACTIVE_TASK.md → ## Review Findings
- [ ] Next: run `deploy-checklist` (if CLEAR or FINDINGS_REQUIRE_FIX resolved)

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

*Next: `deploy-checklist` (Integration phase).*
