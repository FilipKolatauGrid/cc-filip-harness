---
name: design
description: Architecture design — translate a structured requirement into a concrete system design with components, data model, API contracts, data flow, and tech stack decisions. Use this skill whenever starting the planning phase, when the user says "design this", "architect this", "what's the system design?", "how should we build X?", or before any implementation work begins. Always run after `task` (and `init` for greenfield). For existing projects, spawns `sdlc-investigator` first to map current codebase — never design blind on existing code.
---

# Architecture Design

Translate a structured requirement into a concrete system design: components, data flow, API contracts, and tech stack decisions.

## Principles in Play

**Agents overreach and under-finish.** This skill spawns `sdlc-investigator` for existing projects before designing — prevents overreach by designing components that already exist, and prevents under-finish by missing components that are already partially built.

**Feature lists are harness primitives.** Design is derived from `## Requirement` acceptance criteria. Never reverse-engineer AC from design. The design serves the AC — not the other way around.

**Observability inside harness.** Design writes an Observation block with explicit done-signal so downstream skills (`grill`, `risk`) can verify the design phase actually completed with evidence, not just trust the section is non-empty.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement`
Writes: `ACTIVE_TASK.md` → `## Design`

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

## Agent Delegation

For existing projects (non-greenfield): spawn `sdlc-investigator` before designing. Pass `"design"` (phase) and the goal from `## Requirement`. Investigator maps existing components, patterns, and conventions — design must not duplicate or contradict them.

For greenfield (no src/ or equivalent): skip investigator.

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Requirement`: extract `type`, `goal`, `techStack`, `acceptanceCriteria`, `constraints`.

**Analyze:**
- What system boundaries exist? (services, modules, external integrations)
- What are the primary data entities and their relationships?
- What API contracts are needed? (endpoints, payloads, error codes)
- What tech stack decisions are forced by constraints vs. open?
- What are the main component responsibilities?

**Generate:**
1. **Component map** — named components with single-line responsibility each
2. **Data model** — entities, fields, relationships
3. **API contracts** — endpoints, methods, request/response shapes, error codes
4. **Data flow** — step-by-step request lifecycle through components
5. **Tech stack decisions** — confirmed choices with one-line rationale
6. **Open questions** — design choices that need ADR (hand off to `grill`)

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
if (!requirement) hardBlock("task");

let existingMap = null;
if (!isGreenfield(requirement)) {
  existingMap = await agent("design — map existing code for: " + requirement.goal, {
    agentType: "sdlc-investigator",
    label: "investigate:pre-design"
  });
}

const design = await agent(enrichedMetaPrompt(requirement, existingMap), { schema: DESIGN_SCHEMA });
writeActiveTask("## Design", design);
appendObservation("design", {
  doneCriteria: "all AC mapped to components, API contracts defined, openQuestions listed",
  doneSig: "schema-populated"
});
```

## Observation Block

Append after writing `## Design`:

```
### Observation
- phase: planning/design
- done-signal: schema-populated
- done-criteria: components map present, AC coverage verified, openQuestions listed for grill
- investigator-used: yes|no (greenfield)
- verdict-source: self-reported
```

## Trigger Points

- After `task` or `init` outputs structured requirement
- User says "design this", "architect this", "what's the system design?", "how should we build X?"
- Before any implementation work begins

## Output

Writes to `ACTIVE_TASK.md → ## Design`:
- Component map with responsibilities
- Data model
- API contracts (if applicable)
- Data flow narrative
- Tech stack decisions
- Open questions for `grill`

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Verify each acceptance criterion maps to at least one component
- [ ] If existing project: spawn `sdlc-investigator` (pass: "design", goal from ## Requirement)
- [ ] Use investigator PATTERNS output to avoid duplicating existing conventions
- [ ] Use investigator GAPS output to identify what's missing vs. what to extend
- [ ] Map components with single-line responsibilities
- [ ] Define data model (entities, fields, relationships)
- [ ] Specify API contracts (endpoints, payloads, errors)
- [ ] Describe request lifecycle (data flow)
- [ ] Confirm tech stack decisions; flag open choices for `grill`
- [ ] Write output to ACTIVE_TASK.md → ## Design
- [ ] Append Observation block
- [ ] Next: run `grill`

## Example

**Input (from ACTIVE_TASK.md → ## Requirement):**
```
type: feature, goal: "Build a REST API for user management",
techStack: "Python/FastAPI", constraints: { timeline: "2 weeks" }
acceptanceCriteria: ["CRUD for users", "JWT auth", "email uniqueness enforced"]
```

**Output (written to ACTIVE_TASK.md → ## Design):**
```
### Components
- UserRouter — FastAPI router, handles HTTP layer, input validation
- UserService — business logic, orchestrates repo + auth
- UserRepository — DB queries (SQLAlchemy), no business logic
- AuthService — JWT issue/verify, password hashing (argon2id)

### Data Model
users: id (UUID), email (unique), password_hash, created_at, is_active

### API Contracts
POST /users       → 201 { id, email } | 409
GET  /users/{id}  → 200 { id, email, created_at } | 404
POST /auth/token  → 200 { access_token, token_type } | 401

### Tech Stack
- FastAPI: forced by techStack constraint
- SQLAlchemy + alembic: standard ORM for FastAPI

### Open Questions (→ grill)
- Password hashing: bcrypt vs. argon2id?
- Token storage: stateless JWT vs. refresh token DB?
```

---

*Next: `grill` (Planning phase).*
