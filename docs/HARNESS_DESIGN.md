# Harness Design

## Goals

1. **End-to-end SDLC coverage** — requirements → planning → implementation → testing → review → deployment
2. **Agnostic** — works on any tech stack (Python, Go, Rust, TypeScript, etc.)
3. **Meta-prompted** — generates task-specific prompts from context, not hand-written
4. **Extensible** — easy to add new phases, skills, agents, workflows
5. **Representative** — demonstrates SWAT skillset (crash course, hands-on, multiple perspectives)

## Architecture

### Phases

| Phase | Skills | Input | Output |
|-------|--------|-------|--------|
| **Intake** | capture-requirements, init-project | User intent | Structured task, project scaffold |
| **Planning** | architecture-design, decision-grill, risk-assessment | Task + codebase | Design doc, ADRs, risk matrix |
| **Implementation** | code-gen, refactor, tdd | Design + codebase | Working code, passing tests |
| **Testing** | test-design, coverage-analysis, verification | Code + design | Test suite, coverage report, verification sign-off |
| **Review** | code-review, security-audit | Code diff + context | Findings, recommendations |
| **Integration** | deploy-checklist, post-deploy | Verified code | Deployment plan, monitoring setup |

### Meta-Prompting

Core mechanism:

```
Input context:
  - Task description
  - Codebase structure
  - Tech stack
  - Current phase
  - Prior decisions

↓ (Meta-Prompter)

Output:
  - Phase-specific prompt template
  - Success criteria
  - Rollback plan
  - Tool usage strategy
```

Each skill embeds a meta-prompt that generates task-specific instructions. Example:

```javascript
// In test-design skill:
const metaPrompt = `
Given a task description and codebase:
Generate a test plan that covers:
  1. Happy path
  2. Edge cases specific to this task
  3. Integration points
Return: test case list + coverage expectations
`;
```

### Agents

**Orchestrator** — routes user intent to appropriate phase/skill
- Parses task type (bug fix, feature, refactor, etc.)
- Selects entry phase (planning for new features, debugging for bugs)
- Sequences phases intelligently

**Meta-Prompter** — generates context-specific prompts
- Analyzes codebase structure
- Infers tech stack
- Generates phase prompts with injected context

**Debugger** — systematic issue diagnosis
- Reproduces bug
- Isolates root cause
- Proposes fix approach

**Reviewer** — adversarial code review
- Multiple review lenses (correctness, security, performance, maintainability)
- Synthesizes findings
- Scores confidence

### Workflows

**Full SDLC**
```
User task → Intake → Planning → Implementation → Testing → Review → Integration → Done
```

**Bug Fix**
```
Bug report → Debugging → Fix implementation → Unit test → Code review → Deploy
```

**Feature Build**
```
Feature request → Design → Implementation → Integration tests → Review → Integration
```

**Refactor**
```
Code analysis → Risk assessment → Implementation → Verification → Review → Deploy
```

## ADRs

| ID | Decision | Reason |
|----|----------|--------|
| ADR-001 | Meta-prompting, not hand-written prompts | Scales; context-aware; less maintenance |
| ADR-002 | Phase-based skills, not tool-based | Better cognitive model; natural SDLC flow |
| ADR-003 | Agents for orchestration + synthesis | Handles complexity; multiple POVs |
| ADR-004 | Examples with varied stacks | Proves agnosticism; shows adaptation patterns |

## Open Questions

- [ ] How to handle project state persistence across phases?
- [ ] When to involve user for decisions vs. auto-proceed?
- [ ] Rollback strategy for failed phases?
- [ ] Multi-developer scenarios (not in scope for v1)?

---

*Last updated: 2026-06-03*
