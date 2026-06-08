# Code Review

Review the implementation diff for correctness, design alignment, test quality, and maintainability — one finding per line, severity-tagged.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Test Results` and current git diff
Writes: `ACTIVE_TASK.md` → `## Review Findings`

**Hard block:** If `## Test Results` is empty:
> "Run `tests` first. Output required in ACTIVE_TASK.md → ## Test Results."

**Hard block:** If verification verdict in `## Test Results` is not PASS:
> "Verification must pass before code review. Fix blockers in ## Test Results first."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Test Results` (verdict, matrix) and git diff of implementation files.

**Analyze:**
- Does the implementation match the design in ## Design?
- Are there correctness bugs (off-by-one, null handling, race conditions)?
- Is error handling complete and consistent?
- Are tests meaningful — do they test behavior or just coverage?
- Is naming clear and consistent with the codebase conventions?
- Are there reuse opportunities (duplication, missing abstractions)?
- Is complexity justified?

**Generate:**
1. **Findings list** — `path:line: <severity>: <problem>. <fix>.`
2. **Severity tiers** — CRITICAL (ship-blocker), IMPORTANT (should fix), MINOR (optional)
3. **Verdict** — APPROVED / APPROVED_WITH_CHANGES / BLOCKED

## Pattern

```javascript
const testResults = readActiveTask("## Test Results");
if (!testResults) hardBlock("tests");
if (!verificationPassed(testResults)) hardBlock("verify");

const diff = await runGitDiff();

const findings = await agent(enrichedMetaPrompt(testResults, diff), {
  schema: REVIEW_FINDINGS_SCHEMA
});
// Output: { findings: [...], verdict: "APPROVED"|"APPROVED_WITH_CHANGES"|"BLOCKED" }

writeActiveTask("## Review Findings", findings);
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
- [ ] Get git diff of implementation files
- [ ] Check correctness: null handling, error paths, edge cases in code
- [ ] Check design alignment: does code match ## Design components and contracts?
- [ ] Check test quality: tests assert behavior, not just coverage lines
- [ ] Check naming, consistency, duplication, unjustified complexity
- [ ] Tag each finding: CRITICAL / IMPORTANT / MINOR
- [ ] State verdict: APPROVED / APPROVED_WITH_CHANGES / BLOCKED
- [ ] Write findings + verdict to ACTIVE_TASK.md → ## Review Findings
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
