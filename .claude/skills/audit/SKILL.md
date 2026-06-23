---
name: audit
description: Security audit — deep OWASP review of implementation changes including injection, auth flaws, access control, cryptography, and dependency risk. Use when the user says "security audit", "security review", "check for vulnerabilities", "OWASP check", or after `review` completes. Runs `sdlc-secops` for pattern scan in parallel with main-thread architectural analysis. Hard-blocks if review findings section is missing. Required before `deploy`.
---

# Security Audit

Audit the implementation for OWASP Top 10 vulnerabilities, secrets exposure, auth flaws, and input validation gaps — appends findings to `## Review Findings`.

## Principles in Play

**Observability inside harness.** Audit reads the review Observation block to confirm the code review actually ran with agents (not self-reported). Audit is a second, independent pass — not a re-run of the same check.

**Agents overreach and under-finish.** Audit splits work: `sdlc-secops` runs the mechanical pattern scan while main thread does architectural OWASP analysis. Both must complete — neither substitutes for the other.

**Every session must leave clean state.** Audit findings appended to `## Review Findings` serve as the gate for `deploy`. Unresolved CRITICALs from audit block deploy. No clean audit = no deploy.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Review Findings` and current git diff
Writes: appends security findings to `ACTIVE_TASK.md → ## Review Findings`

**Hard block:** If `## Review Findings` is empty:
> "Run `review` first. Output required in ACTIVE_TASK.md → ## Review Findings."

**Hard block:** If review Observation block `done-signal` is not `diff-reviewed`:
> "Code review shows no completion evidence. Re-run `review` before security audit."

## Agent Delegation

Two passes in parallel:
1. `sdlc-secops` (haiku) — mechanical pattern scan: secrets, dangerous calls, compliance drift
2. Main thread — architectural OWASP analysis using `## Design` and `## ADRs` context

The secops agent is fast. Use the time it runs to do the architectural pass inline.

**Architectural analysis (main thread):**
- **Injection** — trace user-controlled inputs to DB/shell/template sinks via design data flow
- **Auth flaws** — token validation logic, session management vs. ## Design auth contracts
- **Access control** — authorization checks on every mutating endpoint vs. API contracts
- **Cryptography** — algorithm choices, key handling, IV/salt from ADRs
- **Dependency risk** — flag for manual `pip audit` / `npm audit` / `cargo audit`

## Pattern

```javascript
const reviewFindings = readActiveTask("## Review Findings");
if (!reviewFindings) hardBlock("review");

const reviewObs = getObservation(reviewFindings, "review");
if (!reviewObs || reviewObs.doneSig !== "diff-reviewed") {
  hardBlock("Code review evidence missing. Re-run `review` first.");
}

// Parallel: secops pattern scan + main-thread architectural analysis
const [secopsFindings] = await parallel([
  () => agent("audit — scan diff for secrets, vuln patterns, compliance", {
    agentType: "sdlc-secops",
    label: "secops:audit"
  })
  // Architectural analysis runs inline concurrently
]);

const architecturalFindings = analyzeArchitecture(
  readActiveTask("## Design"),
  readActiveTask("## ADRs")
);

const mergedFindings = merge(secopsFindings, architecturalFindings);
const securityVerdict = worstOf(secopsFindings.verdict, architecturalVerdict);

appendToActiveTask("## Review Findings", { findings: mergedFindings, securityVerdict });
appendObservation("audit", { doneCriteria: "secops scan complete, architectural analysis done, findings merged" });
```

## Observation Block

Append after audit:

```
### Observation
- phase: review/audit
- done-signal: secops-scan
- done-criteria: sdlc-secops ran, architectural analysis complete, findings merged, verdict set
- secops-scan-verdict: CLEAR|FINDINGS_REQUIRE_FIX|CRITICAL_BLOCK
- arch-analysis-complete: true
- architectural-analysis-verdict: CLEAR|FINDINGS_REQUIRE_FIX|CRITICAL_BLOCK
- verdict-source: external-evidence (secops agent + architectural analysis)
```

## Severity Tiers

- CRITICAL (exploitable now) — must fix before merge
- HIGH (likely exploitable) — must fix before deploy
- MEDIUM (defense-in-depth) — should fix
- LOW (hardening) — optional

## Trigger Points

- After `review` writes ## Review Findings
- User says "security audit", "OWASP check", "check for vulnerabilities"
- Before `deploy` — always required

## Output

Appends to `ACTIVE_TASK.md → ## Review Findings`:
- Security findings (path:line, severity, vuln type, fix)
- Security verdict (CLEAR / FINDINGS_REQUIRE_FIX / CRITICAL_BLOCK)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Review Findings; hard block if empty
- [ ] Check review Observation block — hard block if `done-signal` not `diff-reviewed`
- [ ] Spawn `sdlc-secops` (phase: "audit") — runs while you do architectural analysis
- [ ] Architectural analysis (inline): injection data flow, auth design, access control, crypto, dep risk
- [ ] Wait for secops output
- [ ] Merge: secops (SECRET/VULN_PATTERN/COMPLIANCE) + architectural (OWASP)
- [ ] Take worst verdict: CRITICAL_BLOCK > FINDINGS_REQUIRE_FIX > CLEAR
- [ ] Append merged findings + verdict + Observation block to ACTIVE_TASK.md → ## Review Findings
- [ ] Next: run `deploy` (if CLEAR or all CRITICAL resolved)

---

*Next: `deploy` (Integration phase).*
