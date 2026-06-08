# Code Gen

Generate implementation code from the system design: create files, wire components, satisfy acceptance criteria — stack-agnostic.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design`
Writes: project filesystem + appends entry to `ACTIVE_TASK.md → ## Implementation Log`

**Hard block:** If `## Design` is empty:
> "Run `design` first. Output required in ACTIVE_TASK.md → ## Design."

## Agent Delegation

Before generating any code, spawn `sdlc-investigator` to locate existing files relevant to the design components. Skip this step only for greenfield projects where no source files exist yet.

Pass as input: `"code"` (phase) and the component names from `## Design`.

The investigator returns a FILES table (existing paths + relevance tags). Use it to:
- Identify files to modify vs. create fresh
- Avoid regenerating code that already exists
- Anchor imports and wiring to real paths

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Design`: extract `components`, `dataModel`, `apiContracts`, `dataFlow`, `techStack`. Merge with investigator output.

**Analyze:**
- What files need to be created vs. modified? (investigator output resolves this)
- What is the dependency order for creating components? (models before services, services before routers)
- What interfaces/contracts must each component satisfy?
- What are the acceptance criteria this code must pass?

**Generate:**
1. **File list** — each file to create/modify with its purpose
2. **Implementation order** — dependency-safe creation sequence
3. **Component stubs** — each component with method signatures before bodies
4. **Full implementation** — complete code per file, no TODOs, no placeholder logic
5. **Wiring** — entry point / composition root connecting components

## Pattern

```javascript
const design = readActiveTask("## Design");
if (!design) hardBlock("design");

// Pre-step: locate existing codebase structure
const codebaseMap = await agent("code — locate files for: " + design.components.join(", "), {
  agentType: "sdlc-investigator",
  label: "investigate:pre-code"
});
// codebaseMap: { files: [...], symbols: [...], gaps: [...] }

const plan = await agent(planningMetaPrompt(design, codebaseMap), { schema: FILE_PLAN_SCHEMA });
// Output: { files: [{ path, purpose, dependencies, action: "create"|"modify" }], order: [...] }

for (const file of plan.files) {
  await agent(implementationMetaPrompt(file, design), { schema: CODE_SCHEMA });
}

appendToActiveTask("## Implementation Log", {
  filesCreated: plan.files.map(f => f.path),
  status: "initial-implementation",
  nextStep: "tdd"
});
```

## Trigger Points

- After `risk` completes planning phase
- User says "generate the code", "implement this", "write the implementation"
- All planning sections (Design, ADRs, Risks) present in ACTIVE_TASK.md

## Output

Creates files on filesystem per design. Appends to `ACTIVE_TASK.md → ## Implementation Log`:
- Files created (paths)
- Implementation status
- Any deviations from design (with reasons)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design; hard block if empty
- [ ] Spawn `sdlc-investigator` agent (pass: "code", component names from ## Design) — skip on greenfield
- [ ] Merge investigator file map with design components to determine create vs. modify
- [ ] Derive dependency order (models → services → routers)
- [ ] Write stubs (signatures + contracts) before bodies
- [ ] Implement each file fully — no TODOs, no placeholder logic
- [ ] Wire components at entry point / composition root
- [ ] Verify code compiles / syntax-checks
- [ ] Append file list + status to ACTIVE_TASK.md → ## Implementation Log
- [ ] Next: run `tdd`

## Example

**Input (from ACTIVE_TASK.md → ## Design):**
```
Components: UserRouter, UserService, UserRepository, AuthService
Data Model: users(id, email, password_hash, created_at, is_active)
API: POST /users, GET /users/{id}, POST /auth/token
Tech: Python/FastAPI, SQLAlchemy, argon2id
```

**Output (appended to ACTIVE_TASK.md → ## Implementation Log):**
```
### Implementation — 2024-01-15
Files created:
- src/models/user.py        (SQLAlchemy User model)
- src/repositories/user.py  (UserRepository: CRUD queries)
- src/services/user.py      (UserService: business logic)
- src/services/auth.py      (AuthService: JWT + argon2)
- src/routers/users.py      (UserRouter: FastAPI endpoints)
- src/routers/auth.py       (auth endpoints)
- src/main.py               (FastAPI app + router wiring)
Status: initial-implementation
Deviations: none
Next: tdd
```

---

*Next: `tdd` (Implementation phase).*
