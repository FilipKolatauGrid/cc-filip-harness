# Architecture Design

Translate a structured requirement into a concrete system design: components, data flow, API contracts, and tech stack decisions.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement`
Writes: `ACTIVE_TASK.md` → `## Design`

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

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
2. **Data model** — entities, fields, relationships (ERD or table format)
3. **API contracts** — endpoints, methods, request/response shapes, error codes
4. **Data flow** — step-by-step request lifecycle through components
5. **Tech stack decisions** — confirmed choices with one-line rationale each
6. **Open questions** — design choices that need ADR (hand off to `grill`)

## Agent Delegation

For existing projects (non-greenfield): spawn `sdlc-investigator` before designing. Pass `"design"` (phase) and the goal from `## Requirement`. Investigator maps existing components, patterns, and conventions — design must not duplicate or contradict them.

For greenfield: skip investigator, no existing codebase to scan.

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
if (!requirement) hardBlock("task");

// Pre-step: map existing codebase (skip on greenfield)
let existingMap = null;
if (!isGreenfield(requirement)) {
  existingMap = await agent("design — map existing code for: " + requirement.goal, {
    agentType: "sdlc-investigator",
    label: "investigate:pre-design"
  });
  // existingMap: { files, symbols, patterns, gaps }
}

const design = await agent(enrichedMetaPrompt(requirement, existingMap), { schema: DESIGN_SCHEMA });
// Output: { components, dataModel, apiContracts, dataFlow, techStack, openQuestions }

writeActiveTask("## Design", design);
```

## Trigger Points

- After `task` or `init` outputs structured requirement
- User says "design this", "architect this", "what's the system design?"
- Before any implementation work begins

## Output

Write to `ACTIVE_TASK.md → ## Design`:
- Component map with responsibilities
- Data model (entities + relationships)
- API contracts (if applicable)
- Data flow narrative
- Tech stack decisions
- Open questions flagged for `grill`

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] If existing project: spawn `sdlc-investigator` (pass: "design", goal from ## Requirement)
- [ ] Use investigator PATTERNS output to avoid duplicating existing conventions
- [ ] Use investigator GAPS output to identify what's missing vs. what to extend
- [ ] Map components with single-line responsibilities
- [ ] Define data model (entities, fields, relationships)
- [ ] Specify API contracts (endpoints, payloads, errors)
- [ ] Describe request lifecycle (data flow)
- [ ] Confirm tech stack decisions; flag open choices for decision-grill
- [ ] Write output to ACTIVE_TASK.md → ## Design
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
- AuthService — JWT issue/verify, password hashing (bcrypt)

### Data Model
users: id (UUID), email (unique), password_hash, created_at, is_active

### API Contracts
POST /users          → 201 { id, email } | 409 email exists
GET  /users/{id}     → 200 { id, email, created_at } | 404
PUT  /users/{id}     → 200 { id, email } | 404 | 409
DELETE /users/{id}   → 204 | 404
POST /auth/token     → 200 { access_token, token_type } | 401

### Data Flow
Request → UserRouter (validate) → UserService (business rules)
→ UserRepository (DB) → UserService (format) → UserRouter (respond)

### Tech Stack
- FastAPI: forced by techStack constraint
- SQLAlchemy + alembic: standard ORM for FastAPI
- bcrypt: password hashing (open question: argon2? → flag for decision-grill)

### Open Questions (→ decision-grill)
- Password hashing: bcrypt vs. argon2?
- Token storage: stateless JWT vs. refresh token DB table?
```

---

*Next: `grill` (Planning phase).*
