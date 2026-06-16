---
name: code
description: Code generation — implement from design spec. Generates files, wires components, and satisfies acceptance criteria. Use when the user says "generate the code", "implement this", "write the implementation", "code it up", or after the planning phase (design + ADRs + risks) is complete. Spawns `sdlc-investigator` first on existing projects to locate relevant files — never writes code blind on an existing codebase. Hard-blocks if design is missing.
---

# Code Gen

Generate implementation code from the system design: create files, wire components, satisfy acceptance criteria — stack-agnostic.

## Principles in Play

**Feature lists are harness primitives.** Code must satisfy the acceptance criteria from `## Requirement` — not infer them from design. Before generating, explicitly verify each AC maps to at least one component in `## Design`.

**Agents overreach and under-finish.** Spawns `sdlc-investigator` on existing projects before generating — prevents writing code that duplicates existing implementations, and prevents missing files that need modification rather than creation.

**Agents declare victory too early.** Implementation Log must record actual file paths and status — not just "done". No TODOs, no placeholder logic. Code that compiles but doesn't satisfy AC is not done.

**Observability inside harness.** Implementation Log Observation block records every file created/modified so `tdd`, `refactor`, and `tests` know exactly what to operate on — no guessing from memory.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Design` (stop at next `##`) and `## Requirement` (stop at next `##`). Do NOT read full ACTIVE_TASK.md.
Writes: project filesystem + `ACTIVE_TASK.md` → `## Implementation Log`

**Hard block:** If `## Design` is empty:
> "Run `design` first. Output required in ACTIVE_TASK.md → ## Design."

**Hard block:** If `## Risks` Observation block does not contain `planning-gate: confirmed`:
> "Planning gate not confirmed. Run `risk` and confirm the planning summary before proceeding to `code`."

## Agent Delegation

Before generating any code, spawn `sdlc-investigator` to locate existing files relevant to the design components. Skip only for greenfield projects.

Pass as input: `"code"` (phase) and component names from `## Design`.

Use investigator output to:
- Identify files to modify vs. create fresh
- Avoid regenerating code that already exists
- Anchor imports and wiring to real paths

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Design`: extract `components`, `dataModel`, `apiContracts`, `dataFlow`, `techStack`. Also read `## Requirement` acceptanceCriteria directly — verify each criterion maps to a component before coding.

**Analyze:**
- What files need to be created vs. modified? (investigator output resolves this)
- What is the dependency order? (models before services, services before routers)
- What interfaces/contracts must each component satisfy?
- What are the acceptance criteria this code must pass?

**Generate:**
1. **File list** — each file to create/modify with its purpose
2. **Implementation order** — dependency-safe sequence
3. **Component stubs** — method signatures before bodies
4. **Full implementation** — complete code per file, no TODOs, no placeholder logic
5. **Wiring** — entry point connecting all components

## Pattern

```
// 1. Hard-block: Design empty, planning-gate: confirmed absent from Risks Observation
// 2. Self-inject: components + AC from ## Design + ## Requirement; warn on unmapped ACs
// 3. Spawn sdlc-investigator (existing projects); derive create-vs-modify list
// 4. Generate files in dependency order; no TODOs, no placeholders
// 5. Append Implementation Log + Observation block (files-touched, ac-coverage-verified)
```

## Observation Block

Append after writing `## Implementation Log`:

```
### Observation
- phase: implementation/code
- done-signal: files-written
- done-criteria: all planned files exist, no TODO/placeholder, syntax check passed
- files-touched: [list all created/modified paths]
- ac-coverage-verified: true|false
- investigator-used: yes|no
- verdict-source: filesystem-check
```

## Trigger Points

- After `risk` completes planning phase (or after `design` for lighter workflows)
- User says "generate the code", "implement this", "write the implementation"
- All planning sections (Design, ADRs) present in ACTIVE_TASK.md

## Output

Creates/modifies files on filesystem. Appends to `ACTIVE_TASK.md → ## Implementation Log`:
- Files created/modified (paths)
- Implementation status
- Deviations from design (with reasons)

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Design; hard block if empty
- [ ] Read ACTIVE_TASK.md → ## Requirement → acceptanceCriteria; verify each AC maps to a component
- [ ] Spawn `sdlc-investigator` (skip on greenfield)
- [ ] Merge investigator file map with design components to determine create vs. modify
- [ ] Derive dependency order (models → services → routers)
- [ ] Write stubs (signatures + contracts) before bodies
- [ ] Implement each file fully — no TODOs, no placeholder logic
- [ ] Wire components at entry point
- [ ] Verify code compiles / syntax-checks
- [ ] Append file list + status + Observation block to ACTIVE_TASK.md → ## Implementation Log
- [ ] Next: run `tdd`

---

*Next: `tdd` (Implementation phase).*
