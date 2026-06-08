# Init Project

Scaffold project structure from a structured requirement: directories, config files, tooling, ACTIVE_TASK.md — stack-agnostic.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement`
Writes: project file system + appends scaffold summary to `ACTIVE_TASK.md → ## Requirement`

**Hard block:** If `## Requirement` is empty:
> "Run `task` first. Output required in ACTIVE_TASK.md → ## Requirement."

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
3. **`ACTIVE_TASK.md`** — copy the fixed schema template into project root
4. **`CLAUDE.md` content** — build, test, lint commands for this stack
5. **First commit checklist** — which files to create before writing any feature code
6. **Questions** — clarifications needed (e.g., monorepo? Docker?)

## Pattern

```javascript
// Self-inject from ACTIVE_TASK.md
const requirement = readActiveTask("## Requirement");
if (!requirement) hardBlock("task");

// Generate scaffold
const scaffold = await agent(enrichedMetaPrompt, { schema: SCAFFOLD_SCHEMA });
// Output: { directoryTree, configFiles, claudeMdContent, firstCommitChecklist, questions }

// Write scaffold summary back to ACTIVE_TASK → ## Requirement as addendum
appendToActiveTask("## Requirement", `\n### Scaffold\n${scaffold.summary}`);
```

## Trigger Points

- After `task` outputs structured requirement
- User says "scaffold", "init", "set up project structure", "create new project"
- Greenfield project with no existing structure

## Output

Appends scaffold summary to `ACTIVE_TASK.md → ## Requirement`:
- Directory tree
- Config files to create
- First commit checklist

## Checklist

- [ ] Read ACTIVE_TASK.md → ## Requirement; hard block if empty
- [ ] Detect or confirm tech stack
- [ ] Generate directory structure appropriate for stack + project type
- [ ] List required config files with minimal viable content
- [ ] Draft CLAUDE.md with build + test + lint commands
- [ ] Produce first-commit checklist
- [ ] Ask clarifying questions for ambiguous choices
- [ ] Append scaffold summary to ACTIVE_TASK.md → ## Requirement
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
