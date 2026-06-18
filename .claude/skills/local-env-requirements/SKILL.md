---
name: local-env-requirements
description: >
  Produce a requirements specification for a containerized local development
  environment. Documents WHAT the environment must provide — not HOW to
  implement it. Use when the user asks to document, specify, or plan a local
  dev environment setup using containers (Docker, Compose, etc.), or wants to
  capture containerized setup requirements without prescribing implementation.
  Trigger when the user says: "document local environment requirements",
  "write a spec for containerized local dev", "what should our local Docker
  setup look like", "capture requirements for local env", or "help me plan a
  containerized local environment for this project". Also trigger when
  CLAUDE.md mentions host-installed software that should be containerized.
  Fits in the design phase — run after `task` captures the requirement.
user-invocable: true
allowed-tools: Read, Write, Bash, Glob
---

# Local Environment Requirements

Produce a requirements specification for a containerized local development environment.
Documents **what** the environment must provide — not **how** to implement it.

## Principles in Play

**Initialization needs its own phase.** Read project context before writing anything.
The spec quality depends entirely on understanding what the project currently installs
on the host and why. Don't generate a generic template — derive from actual project docs.

**Feature lists are harness primitives.** The output is a requirements document, not an
implementation. Every requirement must be declarative ("must persist", "must be
accessible only from localhost") not prescriptive ("use a named volume", "bind to 127.0.0.1").

**Agents overreach and under-finish.** Scope is strictly local dev environment.
Out of scope: production deployment, TLS/HTTPS, CI/CD, automated test infrastructure.
Do not add these even if the project would benefit from them.

## Prerequisites

Reads: `ACTIVE_TASK.md` → `## Requirement` (for project context; soft read — not a hard block)
Also reads: `CLAUDE.md`, `docs/techstack.md`, `docs/dependencies.md`, `docs/architecture.md`
(reads what exists; notes what's missing)

Writes:
- `ACTIVE_TASK.md` → `## Design` — summary of deliverables produced
- `docs/local-environment.md` — main requirements spec (created)
- `CLAUDE.md` — short pointer note added to Getting Started section
- `docs/architecture.md` — local dev section appended (created if missing)

**Soft read — ACTIVE_TASK.md:** If `## Requirement` is populated, extract `techStack`,
`constraints`, and `goal` to inform the spec. If empty or missing, proceed using
project docs only. Do not hard-block.

**Hard block — ## Design already populated:**
> "## Design already contains content. If this is a new spec, run `close` to
> archive the current task first. If this is an update to an existing spec,
> edit `docs/local-environment.md` directly."

---

## Phase 1 — Understand the Project

Before writing anything, read existing project documentation:

1. `CLAUDE.md` — what software does the project currently ask developers to install on host?
2. `docs/techstack.md` (if exists) — runtime names and versions; reference this file, don't copy values
3. `docs/dependencies.md` (if exists) — runtime vs dev-tool distinction
4. `docs/architecture.md` (if exists) — system topology, service boundaries
5. `ACTIVE_TASK.md` → `## Requirement` (if populated) — extract `techStack` and `constraints`

Identify:
- **Containerize** — runtimes, databases, web servers, background workers
- **Keep on host** — application code, dev tools (editors, CLIs), build tools
- **Gaps** — files that don't exist; note them in the spec

---

## Meta-Prompt

Self-inject from project docs:
- `HOST_SOFTWARE` — list of software currently installed on host (from CLAUDE.md)
- `TECH_STACK` — runtimes and versions (from techstack.md, or CLAUDE.md if missing)
- `RUNTIME_DEPS` — services that must run for the app to work (databases, queues, servers)
- `DEV_TOOLS` — tools that stay on host (linters, editors, package managers for code editing)
- `MISSING_DOCS` — which of the four source docs don't exist

**Analyze:**
- Which host-installed items are runtime dependencies vs. dev tools?
- What must persist across container restarts (data, uploads)?
- What must be accessible from localhost only?
- What credentials or secrets does the app need?
- Which platforms must be supported (Linux, macOS, Windows)?

**Generate:**
1. Updated CLAUDE.md pointer (2–4 lines)
2. `docs/local-environment.md` — full requirements spec (see structure below)
3. Architecture section (5–10 lines)

---

## Phase 2 — Generate Deliverables

### Deliverable 1: CLAUDE.md update

In the "Getting Started" section (or equivalent), add a short note:

```markdown
### Local Development Environment

A containerized local setup is available. See `docs/local-environment.md`
for requirements. Only Docker is required on the host — no direct installation
of [list runtimes from HOST_SOFTWARE] needed.

> The bare-metal instructions below remain valid as an alternative.
```

Preserve all existing CLAUDE.md content. Do not remove bare-metal instructions.

### Deliverable 2: `docs/local-environment.md`

Write a requirements specification with these sections (use this exact structure):

```markdown
# Local Development Environment Requirements

> This document specifies **what** a containerized local development environment
> must provide. It is not an implementation guide. No Dockerfiles, no
> docker-compose.yml, no shell scripts.

## Purpose and Scope

[1–2 sentences: why this document exists and what problem it solves]

**Out of scope:** production deployment, HTTPS/TLS termination, CI/CD pipelines,
automated test infrastructure.

## Principles

- **Isolation** — project runtimes run in containers; application code stays on host
- **Reproducibility** — only Docker required on host; identical setup across machines
- **Localhost-only** — no services exposed beyond 127.0.0.1
- **Persistence** — data survives container restarts; destroyed only on explicit reset

## Requirements

### 1. Containerization Scope

**Must run in containers:**
[list items from RUNTIME_DEPS]

**Stays on host:**
- Application source code
[list items from DEV_TOOLS]

All containers use official/stock images. No custom image builds.

### 2. Environment Consistency

- Docker (and Docker Compose if multi-service) are the only host prerequisites
- Version requirements: see `docs/techstack.md`
- No project-specific software installed on the host machine

### 3. Network Isolation

- All services accessible only from `127.0.0.1` (localhost)
- No service binds to `0.0.0.0` or an external interface
- Inter-service communication uses the container network, not host networking

### 4. Credentials and Secrets

- Database credentials configurable without modifying application code
- Secure defaults provided for local development
- Credentials stored in a `.env` file excluded from version control (`.gitignore`)
- Rotating credentials requires only updating `.env` and restarting containers

### 5. Data Persistence

- Database data must persist across container stop/start cycles
- User-uploaded files must persist across container stop/start cycles
- **Stop** (preserve data): containers halt, volumes remain
- **Destroy** (wipe data): containers and volumes removed; fresh state

### 6. Application Code Availability

- Application directory is made available inside containers via bind mount
- Code changes on the host are immediately visible inside containers without rebuild

### 7. Simplicity

| Operation | Requirement |
|-----------|-------------|
| Start full local instance | Single command |
| Stop while preserving data | Single command |
| Destroy and reset to initial state | Single command |

### 8. Observability

- Application logs viewable in real time without entering containers
- Database logs viewable on demand
- Database accessible directly via CLI tool from host

### 9. Cross-Platform

- Must work on Linux and macOS
- [List any platform-specific configuration or known issues found in project docs,
   or note "No platform-specific issues identified"]

## Do NOT

The implementation must never:

- Expose services on non-localhost interfaces (`0.0.0.0`, external IP)
- Modify application source code or database schema
- Pin versions that differ from `docs/techstack.md`
- Build custom container images when stock images suffice
- Store secrets in version-controlled files

## Success Criteria

1. Reading this document tells an implementer what the environment must provide,
   without prescribing how.
2. The "Do NOT" section prevents future implementations from violating constraints.
3. A developer with Docker installed can hand this document to an implementer and
   receive a working local environment without further clarification.

## Related Documents

- `docs/techstack.md` — runtime versions (authoritative; this document does not repeat them)
- `docs/dependencies.md` — runtime vs. dev-tool classification (if exists)
- `docs/architecture.md` — system topology including local dev environment section
```

### Deliverable 3: `docs/architecture.md` — Local Dev section

Append (or create file with) this section:

```markdown
## Local Development Environment

The local development environment is containerized and differs from production:

- **No TLS** — plain HTTP on localhost; no certificate management
- **Localhost-only** — all services bound to 127.0.0.1, not exposed externally
- **Persistent volumes** — data stored in named Docker volumes instead of managed storage
- **Single-command lifecycle** — start, stop, and destroy operations are one command each

See `docs/local-environment.md` for the full requirements specification.
```

---

## Phase 3 — Write to ACTIVE_TASK.md

Write a summary to `ACTIVE_TASK.md → ## Design`:

```markdown
## Design

**Skill:** local-env-requirements  
**Deliverables produced:**
- `docs/local-environment.md` — requirements spec (created)
- `CLAUDE.md` — Getting Started section updated with containerized env pointer
- `docs/architecture.md` — local dev section appended (created if missing)

**Containerize:** [list from RUNTIME_DEPS]  
**Keep on host:** application code, [list from DEV_TOOLS]  
**Missing source docs:** [MISSING_DOCS list, or "none"]
```

Then append the Observation block.

---

## Observation Block

Append to `ACTIVE_TASK.md → ## Design` after writing:

```
### Observation
- phase: planning/local-env-requirements
- done-signal: spec-written
- done-criteria: docs/local-environment.md created, CLAUDE.md updated, architecture.md updated
- files-written: docs/local-environment.md, CLAUDE.md, docs/architecture.md
- missing-source-docs: [list or "none"]
- verdict-source: filesystem-check
```

---

## Checklist

- [ ] Read CLAUDE.md — identify HOST_SOFTWARE (what currently installed on host)
- [ ] Read docs/techstack.md (if exists) — note TECH_STACK; flag if missing
- [ ] Read docs/dependencies.md (if exists) — classify runtime vs dev-tool; flag if missing
- [ ] Read docs/architecture.md (if exists) — understand topology; flag if missing
- [ ] Read ACTIVE_TASK.md → ## Requirement (soft read — extract context if populated)
- [ ] Hard block if ## Design already populated — prompt user
- [ ] Derive RUNTIME_DEPS and DEV_TOOLS from project docs (no invention)
- [ ] Write CLAUDE.md pointer (preserve all existing content)
- [ ] Create docs/local-environment.md (exact section structure above)
- [ ] Append local dev section to docs/architecture.md (create if missing)
- [ ] Write design summary to ACTIVE_TASK.md → ## Design
- [ ] Append Observation block
- [ ] Do NOT generate docker-compose.yml, Dockerfile, or any implementation artifact

*Next: `grill` (interrogate design decisions) or `risk` (identify containerization risks).*

---

## Writing Style

- Declarative: "must persist" not "consider persisting"
- Reference other docs by filename; do not copy version numbers or dependency lists
- No implementation details: no volume names, no port numbers, no service names
- If a required source doc is missing, note it explicitly in the spec under a "## Notes" section
