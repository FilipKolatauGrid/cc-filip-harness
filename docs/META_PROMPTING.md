# Meta-Prompting Pattern

Core pattern: **Generate prompts from context** instead of writing them by hand.

## Example: Test Design Skill

### Inputs

1. **Task description** — "Add pagination to user list API"
2. **Codebase structure** — file tree, tech stack detection
3. **Current implementation** — code snippet being tested
4. **Prior context** — design decisions, constraints

### Meta-Prompt Template

```
You are generating a test plan for a backend feature.

CONTEXT:
- Task: {task_description}
- Tech stack: {detected_stack} (e.g., Python/FastAPI, Node/Express, Rust/Actix)
- Change scope: {files_changed}
- Framework: {test_framework} (e.g., pytest, Jest, cargo test)

GENERATE:
1. Happy path test case (normal pagination: page 1, default size)
2. Edge cases for THIS implementation:
   - Empty result set
   - Last page
   - Invalid page number
   - Boundary conditions (page size limits)
3. Integration test (pagination + filtering)
4. Expected coverage: {minimum_coverage_percent}

OUTPUT FORMAT:
- Test case name
- Setup (fixtures)
- Assertions
- Expected coverage contribution
```

### Runtime Execution

```javascript
// intake-requirements.skill evaluates meta-prompt with context:
const context = {
  task: "Add pagination to user list API",
  files: ["backend/src/users/service.ts", "backend/src/users/controller.ts"],
  stackDetected: "TypeScript/NestJS",
  testFramework: "Jest",
  minCoverage: 85
};

const generatedPrompt = evaluateMetaPrompt(template, context);
// Output: task-specific prompt with concrete test cases

const testPlan = await agent(generatedPrompt, { schema: TEST_PLAN_SCHEMA });
// Output: structured test plan
```

## Pattern: Context Injection

Each skill injects context into its meta-prompt:

| Skill | Context | Generates |
|-------|---------|-----------|
| `task` | User text | Structured task + acceptance criteria |
| `design` | Task + codebase | System design + component diagram |
| `code` | Design + stack | Implementation skeleton + patterns |
| `tests` | Code + coverage gaps | Test case list + fixtures |
| `review` | Diff + context | Review criteria + checklist |

## Pattern: Multi-Shot Prompting

When generating complex outputs, use multiple passes:

```
Pass 1 (Analysis):
  Input: Task description
  Generate: Impact analysis (files affected, risk level)
  
Pass 2 (Planning):
  Input: Task + impact analysis
  Generate: Detailed plan (steps, dependencies, rollback)
  
Pass 3 (Execution):
  Input: Plan + codebase
  Generate: Concrete actions (code, tests, docs)
```

## Pattern: Context Refinement

After each phase, refine context for next phase:

```
Intake output:
  { task, acceptance_criteria, tech_stack, scope }
    ↓
Planning output:
  { task, acceptance_criteria, tech_stack, scope, architecture, risks, decisions }
    ↓
Implementation input:
  { ... + architecture + decisions }
```

## Anti-Patterns

❌ **Hard-coded prompts**
```javascript
// DON'T:
const prompt = `
Write a test for the User model.
Use Jest.
Cover happy path and edge cases.
`;
```

✅ **Meta-prompted**
```javascript
// DO:
const metaPrompt = `
Given a code snippet for {model_name}:
Generate test cases covering:
1. Valid input (from {schema})
2. Invalid input (from {validation_rules})
3. Edge cases (from {constraints})
Return test code in {test_framework}
`;

const prompt = evaluateTemplate(metaPrompt, {
  model_name: "User",
  schema: userSchema,
  validation_rules: userValidationRules,
  constraints: userConstraints,
  test_framework: "Jest"
});
```

## Skill Structure Template

Each skill follows this structure:

```javascript
// .claude/skills/phase/skill-name.md

---
name: skill-name
description: What this skill does
metadata:
  type: skill
  phase: [intake|planning|implementation|testing|review|integration]
  triggers: ["when user says X", "when condition Y"]
---

# Meta-Prompt

Given:
- {input_1}
- {input_2}
...

Generate:
- {output_1}
- {output_2}
...

# Pattern

[Implementation pattern]

# Example

[Real usage example]

# Checklist

- [ ] Item 1
- [ ] Item 2
```

---

*Meta-prompting is the key to a maintainable, scalable, context-aware harness.*
