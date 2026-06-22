---
name: init
description: Initialize project scaffold — greenfield project setup from requirements. Use when starting a brand-new project that has no existing source files, when the user says "scaffold", "init", "set up project structure", "create new project", or after `task` completes for a greenfield requirement. Always check for existing files before scaffolding — if source files are detected, warn rather than overwrite. Skip this skill and run `design` instead if the project already has code.
---

# Init Project

Scaffold project structure from a structured requirement: directories, config files, tooling — stack-agnostic.

## Principles in Play

**Initialization needs its own phase.** Scaffolding is a distinct phase from design — it creates the surface `design` will reason about. Running scaffold after design, or design before scaffold, produces conflicts. This skill enforces the intake→scaffold→design order.

**Every session must leave clean state.** If existing source files are detected, init warns rather than silently overwriting — protecting in-progress work.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement`
Writes: project filesystem + appends scaffold summary to `ACTIVE_TASK.md → ## Requirement`

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

**Warning (not block):** If any of `src/`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml` exist at project root:
> "Existing project detected. `init` scaffolds greenfield projects — it may overwrite existing structure. Confirm to continue or run `design` for an existing project."

## Meta-Prompt

Self-inject from `ACTIVE_TASK.md → ## Requirement`: extract `type`, `goal`, `techStack`, `constraints`.

**Analyze:**
- What tech stack is specified or implied?
- What project type? (CLI, REST API, frontend, library, microservice)
- What testing framework is standard for this stack?
- What minimum config files are needed to build + test?

**Generate:**
1. **Directory tree** — recommended layout for this stack and project type
2. **Config file list** — e.g., `package.json`, `pyproject.toml`, `Cargo.toml`
3. **`ACTIVE_TASK.md`** — copy the fixed schema template into project root if not present
4. **`CLAUDE.md` content** — build, test, lint commands for this stack
5. **First commit checklist** — which files to create before writing any feature code
6. **Questions** — clarifications needed (e.g., monorepo? Docker?)

## Pattern

```javascript
const requirement = readActiveTask("## Requirement");
if (!requirement) hardBlock("task");

// Safety: detect existing project files
const existingFiles = detectProjectFiles(["src/", "package.json", "pyproject.toml", "go.mod"]);
if (existingFiles.length > 0) {
  warn(`Existing project detected (${existingFiles.join(", ")}). Confirm to scaffold or run \`design\` instead.`);
}

const scaffold = await agent(enrichedMetaPrompt(requirement), { schema: SCAFFOLD_SCHEMA });

// B1–B5: Run stack detection after scaffold files are written
bash(".claude/hooks/stack-detect.sh");  // writes .claude/stack-profile.json
const stackProfile = readFile(".claude/stack-profile.json");
appendToActiveTask("## Requirement", `\n### Scaffold\n${scaffold.summary}\n\n### Stack Profile\n${formatStackProfile(stackProfile)}`);
appendObservation("init", { doneCriteria: "directory tree created, config files written, CLAUDE.md present, stack-profile.json written" });
```

## Stack Detection (B1–B5)

After scaffold files are written, run `.claude/hooks/stack-detect.sh` (or it has already run at SessionStart). Read `.claude/stack-profile.json` and append a `### Stack Profile` subsection to `## Requirement`:

```markdown
### Stack Profile
- B1 package-manager: <pm> — install: `<install_cmd>`
- B2 start: `<start_cmd>` — entry points: [<list>]
- B3 test-runner: <test_runner> — run: `<test_cmd>`
- B4 lint: `<lint_cmd>` | typecheck: `<typecheck_cmd>` | shellcheck: <true|false>
- B5 verify-chain: [<ordered chain>]
```

If stack-profile.json is absent (stack could not be detected): note "stack: unknown — update CLAUDE.md with build/test/lint commands manually."

## Observation Block

Append after scaffolding:

```
### Observation
- phase: intake/init
- done-signal: filesystem-written
- done-criteria: directory tree exists, config file list written, CLAUDE.md present, stack-profile.json written
- files-touched: [list scaffold files created]
- verdict-source: filesystem-check
```

## Trigger Points

- After `task` outputs structured requirement for a greenfield project
- User says "scaffold", "init", "set up project structure", "create new project"
- Greenfield — no existing `src/`, `package.json`, or equivalent

## Output

Creates project filesystem. Appends scaffold summary to `ACTIVE_TASK.md → ## Requirement`:
- Directory tree
- Config files created
- First commit checklist

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Detect existing project files — warn (not block) if found
- [ ] Detect or confirm tech stack from requirement
- [ ] Generate directory structure appropriate for stack + project type
- [ ] List required config files with minimal viable content
- [ ] Draft CLAUDE.md with build + test + lint commands
- [ ] Produce first-commit checklist
- [ ] Ask clarifying questions for ambiguous choices (monorepo? Docker? CI?)
- [ ] Run `bash .claude/hooks/stack-detect.sh` after scaffold files written
- [ ] Read `.claude/stack-profile.json` and append `### Stack Profile` (B1–B5) to `## Requirement`
- [ ] Append scaffold summary to ACTIVE_TASK.md → ## Requirement
- [ ] Append Observation block
- [ ] Next: run `design`

## Example

**Input (ACTIVE_TASK.md → ## Requirement):**
```
type: feature, goal: "Build a REST API for user management",
techStack: "Python/FastAPI", constraints: { timeline: "2 weeks" }
```

**Output (appended to ## Requirement):**
```
### Scaffold
- directoryTree: src/, src/main.py, src/routes/, src/models/, tests/, pyproject.toml
- configFiles: pyproject.toml (FastAPI + pytest + ruff), .env.example
- claudeMd: "Build: uvicorn src.main:app | Test: pytest | Lint: ruff check ."
- firstCommitChecklist: [pyproject.toml, src/main.py stub, tests/conftest.py]
```

---

*Next: `design` (Planning phase).*
