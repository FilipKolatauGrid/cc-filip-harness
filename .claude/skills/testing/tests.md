# Test Design

Design a complete test plan: test types, scenarios, data, and coverage targets derived from acceptance criteria and the implementation log.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement` and `## Implementation Log`
Writes: `ACTIVE_TASK.md` → `## Test Results` (plan section)

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

**Hard block:** If `## Implementation Log` is empty:
> "Run `code` first. Output required in ACTIVE_TASK.md → ## Implementation Log."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Requirement` (acceptanceCriteria, successMetrics) and `## Implementation Log` (filesCreated, tdd entries).

**Analyze:**
- Which acceptance criteria have existing TDD tests vs. need new tests?
- What test types are appropriate? (unit, integration, e2e, contract, load)
- What boundary conditions and edge cases does each criterion imply?
- What test data is needed? (fixtures, factories, seed data)
- What is a meaningful coverage target for this project type?

**Generate:**
1. **Test plan** — test type per criterion, scenario descriptions, pass/fail conditions
2. **Edge cases** — boundary values, error paths, empty/null inputs
3. **Test data spec** — fixtures or factories needed
4. **Coverage target** — justified by project type and risk profile
5. **Test execution order** — unit → integration → e2e

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
const implLog = readActiveTask("## Implementation Log");
if (!requirement) hardBlock("task");
if (!implLog) hardBlock("code");

const testPlan = await agent(enrichedMetaPrompt, { schema: TEST_PLAN_SCHEMA });
// Output: { scenarios: [...], edgeCases: [...], testData: [...], coverageTarget, executionOrder }

writeActiveTask("## Test Results", { plan: testPlan, status: "planned" });
```

## Trigger Points

- After `refactor` completes implementation phase
- User says "design tests", "what tests do we need?", "test plan"
- Before `coverage` or `verify`

## Output

Writes to `ACTIVE_TASK.md → ## Test Results`:
- Test plan (scenarios, types, pass conditions)
- Edge cases per criterion
- Test data spec
- Coverage target with justification

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## Implementation Log; hard block if empty
- [ ] Map each acceptance criterion to test type(s)
- [ ] Enumerate edge cases: boundary values, error paths, nulls
- [ ] Specify test data (fixtures, factories, seed data)
- [ ] Set coverage target with rationale
- [ ] Define execution order (unit → integration → e2e)
- [ ] Write test plan to ACTIVE_TASK.md → ## Test Results
- [ ] Next: run `coverage`

## Example

**Input (from ACTIVE_TASK.md → ## Requirement + ## Implementation Log):**
```
acceptanceCriteria: ["Email uniqueness enforced", "JWT expires in 15min", "CRUD for users"]
Implementation Log: 14 TDD tests green, 81% coverage, files: src/services/, src/routers/
```

**Output (written to ACTIVE_TASK.md → ## Test Results):**
```
### Test Plan
| Criterion | Test Type | Scenario | Pass Condition |
|-----------|-----------|----------|----------------|
| Email uniqueness | Unit | POST /users with duplicate email | 409 Conflict returned |
| Email uniqueness | Integration | Two users, same email, DB constraint | IntegrityError raised |
| JWT expiry | Unit | Token with exp=now-1s | verify_token raises ExpiredToken |
| JWT expiry | Integration | Request with expired token | 401 Unauthorized |
| CRUD users | Integration | Create → Read → Update → Delete cycle | All 204/200/201 returned |

### Edge Cases
- Empty email string → 422 Unprocessable
- Email with leading/trailing spaces → normalize or reject (decision needed)
- Password < 8 chars → 422 with field error
- GET /users/{nonexistent-uuid} → 404

### Test Data
- UserFactory: generates valid user payload with unique email per call
- Fixtures: test_db (in-memory SQLite), auth_headers (valid JWT)

### Coverage Target
85% — REST API with auth; critical paths need high confidence; UI-less so 85% is achievable.

### Execution Order
1. Unit (services, auth) → 2. Integration (routers + DB) → 3. E2E (full request cycle)
```

---

*Next: `coverage` (Testing phase).*
