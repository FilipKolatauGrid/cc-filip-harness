# Capture Requirements

Parse user intent into structured task definition with acceptance criteria, scope, and success metrics.

## Prerequisites

Reads: nothing (entry point)
Writes: `ACTIVE_TASK.md` → `## Requirement`

**Note:** Create `ACTIVE_TASK.md` at project root if it doesn't exist. Use the fixed schema from the harness `CLAUDE.md`.

## Meta-Prompt

Given user text describing a task (feature request, bug report, refactor request):

**Analyze:**
- Is this a new feature, bug fix, refactor, or improvement?
- What is the primary goal?
- Who is the user (engineer, product manager, end-user)?
- What constraints exist (timeline, compatibility, tech stack)?

**Generate:**
1. **Task Type** — feature|bugfix|refactor|improvement|maintenance
2. **Goal Statement** — 1-2 sentences, clear and measurable
3. **Acceptance Criteria** — bulleted list of "must-have" requirements
4. **Scope** — what's in scope, what's explicitly out
5. **Constraints** — tech stack, compatibility, timeline, team size
6. **Success Metrics** — how to verify task is done
7. **Questions** — clarifications needed before planning

## Pattern

```javascript
// User provides task description
const userInput = `
We need to add email verification to our auth flow.
Currently users sign up with email/password but we don't verify ownership.
Legal team says we need to send a verification email before the account is fully active.
We have 3 weeks and one engineer (me).
`;

// Meta-prompt evaluates against: task type detection, goal clarity, scope inference
// Generates: Structured requirement output

const requirement = await agent(generatedMetaPrompt, { 
  schema: REQUIREMENT_SCHEMA 
});

// Output:
{
  type: "feature",
  goal: "Add email verification requirement to auth flow",
  acceptanceCriteria: [
    "Verify email ownership before account activation",
    "Send verification email on signup",
    "Verification link expires after 24 hours",
    "User can request resend",
    "Unverified accounts can't log in"
  ],
  scope: {
    inScope: ["signup flow", "email sending", "database schema"],
    outOfScope: ["notification preferences", "multi-factor auth"]
  },
  constraints: {
    timeline: "3 weeks",
    teamSize: 1,
    techStack: "inferred from codebase"
  },
  successMetrics: [
    "Email verification process end-to-end",
    "Test coverage >= 85%",
    "No auth regression tests fail"
  ],
  questions: [
    "Should unverified users see a warning message?",
    "Is 24-hour expiry non-negotiable?"
  ]
}
```

## Trigger Points

- User starts new session with a task description
- `/task` command with description
- Team member files an issue that needs structuring

## Output

- Structured task definition (JSON schema)
- Follow-up questions for clarification
- Recommended entry point (planning, implementation, or debugging)

## Checklist

- [ ] Extract task type (feature/bugfix/refactor/other)
- [ ] Identify goal vs. implementation details
- [ ] List acceptance criteria (testable, measurable)
- [ ] Define scope boundaries (in/out)
- [ ] Surface constraints (timeline, team, tech)
- [ ] Propose success metrics
- [ ] Identify ambiguities → ask questions
- [ ] Suggest next phase (usually Planning)
- [ ] Write structured output to ACTIVE_TASK.md → ## Requirement
- [ ] Next: run `init-project` (new project) or `architecture-design` (existing project)

## Example: Bug Report

**Input:**
```
"Users report that the search endpoint times out 
on large datasets. It was fine last week. 
We added a new feature that does bulk upserts. 
Probably that broke something?"
```

**Output:**
```json
{
  "type": "bugfix",
  "goal": "Restore search endpoint performance after bulk upsert feature",
  "acceptanceCriteria": [
    "Search completes in < 500ms on dataset with 1M records",
    "No degradation from baseline (prior week performance)",
    "Bulk upsert feature still works correctly"
  ],
  "scope": {
    "inScope": ["search endpoint", "database queries", "indexing"],
    "outOfScope": ["search UI", "other endpoints"]
  },
  "constraints": {
    "timeline": "ASAP (prod impact)",
    "risk": "HIGH (performance issue)"
  },
  "successMetrics": [
    "Load test: 1M records searched in < 500ms",
    "No regression in bulk upsert tests",
    "Monitoring dashboards show normal latency"
  ],
  "questions": [
    "When did performance degrade? (exact timestamp?)",
    "Which bulk upsert query pattern is slowest?"
  ]
}
```

---

*Next: Pass structured requirement to Planning phase.*
