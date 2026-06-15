---
name: tests
description: Test design — plan complete test scenarios from acceptance criteria and implementation log. Use when the user says "design tests", "what tests do we need?", "test plan", "what should we test?", or after `refactor` completes implementation. Creates the test plan that `coverage` and `verify` will operate against. Hard-blocks if requirement or implementation log is missing. Always includes at least one E2E scenario per acceptance criterion.
---

# Test Design

Design a complete test plan: test types, scenarios, data, and coverage targets derived from acceptance criteria and the implementation log.

## Principles in Play

**End-to-end testing changes results.** Test plan must include at least one E2E scenario per acceptance criterion — a test that exercises the criterion through the full component stack, not just in unit isolation. E2E tests surface integration failures that unit tests miss.

**Feature lists are harness primitives.** Test scenarios are derived directly from `## Requirement` acceptanceCriteria. The test plan must have explicit traceability: each AC maps to at least one test type.

**Agents declare victory too early.** Test plan alone is not test coverage. Coverage is measured by `coverage`. Verify is confirmed by `verify`. This skill plans; it does not certify.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement` and `## Implementation Log`
Writes: `ACTIVE_TASK.md` → `## Test Results` (plan section)

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

**Hard block:** If `## Implementation Log` is empty:
> "Run `code` first. Output required in ACTIVE_TASK.md → ## Implementation Log."

## Meta-Prompt

Self-inject from `## Requirement` (acceptanceCriteria, successMetrics) and `## Implementation Log` (filesCreated, tdd entries).

**Analyze:**
- Which acceptance criteria have existing TDD tests vs. need new tests?
- What test types are appropriate per criterion? (unit, integration, e2e)
- What boundary conditions and edge cases does each criterion imply?
- What test data is needed?
- What is a meaningful coverage target for this project type?
- Which criteria REQUIRE an E2E test (not just unit)?

**Generate:**
1. **Test plan** — test type per criterion with explicit AC traceability, scenario descriptions, pass/fail conditions
2. **E2E scenarios** — at least one per AC, describing the full component path tested
3. **Edge cases** — boundary values, error paths, empty/null inputs
4. **Test data spec** — fixtures or factories needed
5. **Coverage target** — justified by project type and risk profile
6. **Test execution order** — unit → integration → e2e

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
const implLog = readActiveTask("## Implementation Log");
if (!requirement) hardBlock("task");
if (!implLog) hardBlock("code");

// Enforce E2E requirement
const criteria = extractAcceptanceCriteria(requirement);
const testPlan = await agent(enrichedMetaPrompt(requirement, implLog), { schema: TEST_PLAN_SCHEMA });

// Validate: every AC has at least one E2E scenario
const missingE2E = criteria.filter(ac => !testPlan.e2eScenarios.some(s => s.criterion === ac));
if (missingE2E.length > 0) {
  warn(`Missing E2E scenarios for: ${missingE2E.join(", ")}. Add E2E coverage before proceeding.`);
}

writeActiveTask("## Test Results", { plan: testPlan, status: "planned" });
appendObservation("tests", { doneCriteria: "all AC mapped to test types, E2E per AC present, coverage target justified" });
```

## Observation Block

Append after writing `## Test Results`:

```
### Observation
- phase: testing/tests
- done-signal: schema-populated
- done-criteria: all AC have test scenarios, ≥1 E2E per AC, coverage target set with rationale
- ac-count: N
- e2e-coverage: N/N AC have E2E scenario
- verdict-source: self-reported
```

## Trigger Points

- After `refactor` completes implementation phase
- User says "design tests", "what tests do we need?", "test plan"
- Before `coverage` or `verify`

## Output

Writes to `ACTIVE_TASK.md → ## Test Results`:
- Test plan with AC traceability (criterion → test type → scenario)
- E2E scenarios (≥1 per AC)
- Edge cases per criterion
- Test data spec
- Coverage target with justification
- Execution order

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## Implementation Log; hard block if empty
- [ ] Map each acceptance criterion to test type(s) — explicit traceability
- [ ] Verify at least one E2E scenario per acceptance criterion — warn if missing
- [ ] Enumerate edge cases: boundary values, error paths, nulls
- [ ] Specify test data (fixtures, factories, seed data)
- [ ] Set coverage target with rationale
- [ ] Define execution order (unit → integration → e2e)
- [ ] Write test plan to ACTIVE_TASK.md → ## Test Results
- [ ] Append Observation block
- [ ] Next: run `coverage`

## Example

**Output excerpt (written to ACTIVE_TASK.md → ## Test Results):**
```
### Test Plan (AC Traceability)
| Criterion | Test Type | Scenario | Pass Condition | E2E? |
|-----------|-----------|----------|----------------|------|
| Email uniqueness | Unit | POST /users with duplicate email | 409 Conflict | No |
| Email uniqueness | E2E | Two users, same email, full request cycle | 409 at HTTP layer | Yes ✓ |
| JWT expiry | Unit | Token with exp=now-1s | ExpiredToken raised | No |
| JWT expiry | E2E | Request with expired token to protected endpoint | 401 Unauthorized | Yes ✓ |

### E2E Scenarios
1. Criterion: "Email uniqueness enforced" — full HTTP request cycle, two POST /users with same email, assert 409
2. Criterion: "JWT expires in 15min" — issue token, advance time 16min, send request, assert 401

### Coverage Target
85% — REST API with auth; critical paths need high confidence. Achievable without UI.
```

---

*Next: `coverage` (Testing phase).*
