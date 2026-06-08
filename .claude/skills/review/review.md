# Code Review

Review the implementation diff for correctness, design alignment, test quality, and maintainability — one finding per line, severity-tagged.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Test Results` and current git diff
Writes: `ACTIVE_TASK.md` → `## Review Findings`

**Hard block:** If `## Test Results` is empty:
> "Run `tests` first. Output required in ACTIVE_TASK.md → ## Test Results."

**Hard block:** If verification verdict in `## Test Results` is not PASS:
> "Verification must pass before code review. Fix blockers in ## Test Results first."

## Agent Delegation

Spawn `sdlc-reviewer` AND `sdlc-secops` in **parallel** — both read the same diff independently. Neither depends on the other's output.

- `sdlc-reviewer` → correctness, design alignment, test quality, acceptance criteria check
- `sdlc-secops` → secrets, dangerous patterns, compliance drift (first-pass, before full `audit`)

Merge both outputs into `## Review Findings`. Take worst verdict across both agents.

**Why secops here too (not just audit):** `audit` is deep architectural analysis. `secops` at review catches secrets committed in this diff immediately — before audit phase, before deploy gate.

**Severity mapping** (both agents → ACTIVE_TASK.md):
- `🔴 CRITICAL` / SECRET → must resolve before merge
- `🟠 HIGH` → must resolve before merge
- `🟡 MEDIUM` / COMPLIANCE → should resolve, not a blocker
- `🔵 LOW` → optional
- `🟣 SCOPE` → flag only

**Verdict mapping (worst-of):**
- Either agent returns BLOCKED / CRITICAL_BLOCK → BLOCKED
- Both return PASS / PASS_WITH_NOTES / FINDINGS_REQUIRE_FIX → APPROVED_WITH_CHANGES
- Both return PASS / CLEAR → APPROVED

## Pattern

```javascript
const testResults = readActiveTask("## Test Results");
if (!testResults) hardBlock("tests");
if (!verificationPassed(testResults)) hardBlock("verify");

// Parallel: code review + secrets/compliance scan — same diff, independent concerns
const [reviewOutput, secopsOutput] = await parallel([
  () => agent("review — check correctness, design alignment, test quality", {
    agentType: "sdlc-reviewer",
    label: "review:diff"
  }),
  () => agent("review — scan for secrets, vuln patterns, compliance drift", {
    agentType: "sdlc-secops",
    label: "secops:review"
  })
]);

const merged = mergeFindings(reviewOutput, secopsOutput);
const verdict = worstVerdict(reviewOutput.verdict, secopsOutput.verdict);

writeActiveTask("## Review Findings", { ...merged, verdict });
```

## Trigger Points

- After `verify` returns PASS verdict
- User says "review this", "code review", "/code-review"
- Before `audit` and `deploy`

## Output

Writes to `ACTIVE_TASK.md → ## Review Findings`:
- Findings list (path:line, severity, problem, fix)
- Overall verdict

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Test Results; hard block if empty or FAIL verdict
- [ ] Spawn `sdlc-reviewer` + `sdlc-secops` in parallel (same diff, independent agents)
- [ ] Wait for both agents to complete
- [ ] Merge findings: reviewer block first, secops block second
- [ ] Take worst verdict across both (BLOCKED / CRITICAL_BLOCK beats everything)
- [ ] Map merged verdict to APPROVED / APPROVED_WITH_CHANGES / BLOCKED
- [ ] Write merged findings + verdict to ACTIVE_TASK.md → ## Review Findings
- [ ] If BLOCKED: surface all CRITICAL + SECRET blockers to user before proceeding
- [ ] Next: run `audit`

## Example

**Input (from ACTIVE_TASK.md → ## Test Results + git diff):**
```
Verification: ✅ PASS, 18/18 tests, 87% coverage
Diff: src/services/user.py, src/services/auth.py, src/routers/users.py
```

**Output (written to ACTIVE_TASK.md → ## Review Findings):**
```
### Code Review Findings
src/services/auth.py:34: CRITICAL: verify_token catches bare Exception — masks unexpected errors. Catch jwt.ExpiredSignatureError and jwt.InvalidTokenError specifically.
src/services/user.py:61: IMPORTANT: create_user does not strip whitespace from email before uniqueness check — "user@x.com " and "user@x.com" treated as different. Add .strip().lower() normalization.
src/routers/users.py:22: MINOR: variable name `u` in list comprehension — rename to `user` for clarity.

### Verdict: APPROVED_WITH_CHANGES
Fix CRITICAL and IMPORTANT before merge. MINOR at discretion.
```

---

*Next: `audit` (Review phase).*
