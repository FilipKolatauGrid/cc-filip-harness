# Code Gen

Generate implementation code from the system design: create files, wire components, satisfy acceptance criteria — stack-agnostic.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design`
Writes: project filesystem + appends entry to `ACTIVE_TASK.md → ## Implementation Log`

**Hard block:** If `## Design` is empty:
> "Run `architecture-design` first. Output required in ACTIVE_TASK.md → ## Design."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Design`: extract `components`, `dataModel`, `apiContracts`, `dataFlow`, `techStack`.

**Analyze:**
- What files need to be created or modified?
- What is the dependency order for creating components? (models before services, services before routers)
- What interfaces/contracts must each component satisfy?
- What are the acceptance criteria this code must pass?

**Generate:**
1. **File list** — each file to create with its purpose
2. **Implementation order** — dependency-safe creation sequence
3. **Component stubs** — each component with method signatures and docstrings before bodies
4. **Full implementation** — complete code per file, no TODOs, no placeholder logic
5. **Wiring** — entry point / composition root connecting components

## Pattern

```javascript
const design = readActiveTask("## Design");
if (!design) hardBlock("architecture-design");

const plan = await agent(planningMetaPrompt, { schema: FILE_PLAN_SCHEMA });
// Output: { files: [{ path, purpose, dependencies }], order: [...] }

for (const file of plan.files) {
  await agent(implementationMetaPrompt(file, design), { schema: CODE_SCHEMA });
  // Writes file to filesystem
}

appendToActiveTask("## Implementation Log", {
  filesCreated: plan.files.map(f => f.path),
  status: "initial-implementation",
  nextStep: "tdd"
});
```

## Trigger Points

- After `risk-assessment` completes planning phase
- User says "generate the code", "implement this", "write the implementation"
- All planning sections (Design, ADRs, Risks) present in ACTIVE_TASK.md

## Output

Creates files on filesystem per design. Appends to `ACTIVE_TASK.md → ## Implementation Log`:
- Files created (paths)
- Implementation status
- Any deviations from design (with reasons)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design; hard block if empty
- [ ] Derive file list and dependency order from components
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
