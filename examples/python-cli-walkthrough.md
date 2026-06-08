# Example Walkthrough: Python CLI — Add CSV Export

End-to-end harness run for: **"Add CSV export to a Python CLI tool"**
Stack: Python 3.11, Click, pytest, ruff
Workflow: `feature-build`

Shows actual ACTIVE_TASK.md section output at each phase.

---

## Phase 1: Intake

### `/task`

**Input:** "We need to add a CSV export command to our data pipeline CLI. Users run `pipeline export` and get a CSV file of the last run's results. We have 2 weeks and one engineer."

**ACTIVE_TASK.md → ## Requirement:**
```
type: feature
goal: "Add CSV export command to data pipeline CLI"
techStack: Python 3.11, Click, pytest, ruff
acceptanceCriteria:
  - `pipeline export` command outputs CSV to stdout by default
  - `--output FILE` flag writes to file instead of stdout
  - CSV includes header row with column names from last run results
  - Empty result set produces header-only CSV (no error)
  - Large result sets (>100k rows) stream without loading all into memory
scope:
  inScope: [export command, CSV formatting, streaming, --output flag]
  outOfScope: [other formats, scheduled exports, cloud upload]
constraints:
  timeline: "2 weeks"
  teamSize: 1
  compatibility: "must not break existing `pipeline run` command"
successMetrics:
  - "CSV export end-to-end test passes"
  - "Streaming: 100k rows exported in < 5s, < 50MB memory"
  - "Coverage >= 85%"
questions:
  - "Should column order match DB query order or be alphabetical?"
```

---

## Phase 2: Planning

### `/design`

**ACTIVE_TASK.md → ## Design:**
```
### Components
- ExportCommand   — Click command handler, parses flags, calls ExportService
- ExportService   — orchestrates result fetch + CSV streaming, no CLI knowledge
- CsvFormatter    — formats rows to CSV, handles header, streams via generator
- ResultRepository — existing component (read-only) — fetches last run results

### Data Flow
pipeline export [--output FILE]
→ ExportCommand (parse flags)
→ ExportService.export(destination: IO)
→ ResultRepository.stream_last_run() → row generator
→ CsvFormatter.write(rows, destination)
→ stdout or file

### API Contracts (internal)
ExportService.export(destination: IO[str]) → None
CsvFormatter.write(rows: Iterator[dict], dest: IO[str]) → None
ResultRepository.stream_last_run() → Iterator[dict]  ← existing, no change

### Tech Stack
Click: existing CLI framework — forced
csv (stdlib): no new dependency — streaming via csv.writer
pytest + pytest-click: existing test setup

### Open Questions (→ /grill)
- Column order: DB query order vs. alphabetical?
- Output encoding: UTF-8 always, or honour locale?
```

### `/grill`

**Interactive session — grill presents one decision at a time, developer picks by number:**

```
Decision 1/2: CSV Column Order

Columns in export could match DB query order or be sorted alphabetically.
CLI users often pipe output to other tools — column order stability matters.

Options:
  1. DB query order — columns follow the query result set
     Pros: stable, predictable for scripting and piping
     Cons: order changes if query changes (breaking for downstream scripts)

  2. Alphabetical — columns sorted A→Z
     Pros: readable for humans inspecting the file
     Cons: unpredictable for scripts; breaks if column names change

★ Recommendation: Option 1 — CLI tool implies scripting use; stable order is safer.

Reply with the option number, or describe a custom choice.
```

Developer: `1`

```
Recorded: DB query order. Column order is tied to the query — adding/renaming columns is a breaking change for downstream scripts.

Decision 2/2: Output Encoding

CSV encoding choice affects cross-environment compatibility.
Pipeline data is internal; no locale requirements stated.

Options:
  1. UTF-8 always — fixed encoding regardless of system locale
     Pros: portable, standard for data interchange, no surprises across environments
     Cons: Windows Excel may prompt on open (minor UX issue)

  2. Locale-aware — honour system locale setting
     Pros: Excel on Windows opens without prompt
     Cons: silent corruption when files cross environments with different locales

★ Recommendation: Option 1 — internal pipeline tool; portability beats Excel UX.

Reply with the option number, or describe a custom choice.
```

Developer: `1`

```
Recorded: UTF-8 always. Document the Excel encoding prompt as a known limitation for Windows users.
```

**ACTIVE_TASK.md → ## ADRs** (written after all choices collected):
```
### ADR-001: CSV Column Order
Context: Columns could follow DB query order (predictable for scripting) or alphabetical (readable for humans).
Options: DB query order, alphabetical
Decision: DB query order
Rationale: Developer chose option 1. CLI users pipe output to other tools; stable, predictable order is more scriptable.
Consequences: Column order tied to query — adding/renaming columns is a breaking change for downstream scripts.
Rejected: alphabetical — optimises for reading, not scripting.

### ADR-002: Output Encoding
Context: CSV encoding could be UTF-8 always or locale-aware.
Options: UTF-8 always, locale-aware
Decision: UTF-8 always
Rationale: Developer chose option 1. Internal pipeline data; portability across environments takes priority.
Consequences: Windows users opening in Excel may see encoding prompt — document as known limitation.
Rejected: locale-aware — unpredictable across environments.
```

### `/risk` *(skipped — single layer, no external deps, < 3 days scope)*

---

## Phase 3: Implementation

### `/code`

**ACTIVE_TASK.md → ## Implementation Log:**
```
### Implementation — 2024-01-15
Files created:
- src/commands/export.py      (ExportCommand — Click command)
- src/services/export.py      (ExportService — orchestration)
- src/formatters/csv.py       (CsvFormatter — streaming csv.writer)
Status: initial-implementation
Deviations: none
Next: tdd
```

### `/tdd`

**ACTIVE_TASK.md → ## Implementation Log (appended):**
```
### TDD — Criterion: pipeline export outputs CSV to stdout
Test: tests/test_export_command.py::test_export_to_stdout
Red: AssertionError — command not registered
Delta: register ExportCommand in CLI group
Green: ✅

### TDD — Criterion: --output FILE writes to file
Test: tests/test_export_command.py::test_export_to_file
Red: FileNotFoundError — --output not implemented
Delta: ExportCommand passes open(output, 'w') to ExportService
Green: ✅

### TDD — Criterion: CSV includes header row
Test: tests/test_csv_formatter.py::test_header_row_present
Red: AssertionError — no header in output
Delta: CsvFormatter.write() calls csv.writer.writeheader()
Green: ✅

### TDD — Criterion: Empty result set → header-only CSV
Test: tests/test_csv_formatter.py::test_empty_results_header_only
Red: AssertionError — empty output
Delta: CsvFormatter handles empty iterator — writes header then stops
Green: ✅

### TDD — Criterion: 100k rows stream without loading all into memory
Test: tests/test_export_service.py::test_streaming_memory_usage
Red: MemoryError (naive list load)
Delta: ExportService passes generator directly to CsvFormatter (no list materialisation)
Green: ✅
All 5 criteria: ✅ green
```

---

## Phase 4: Testing

### `/tests` + `/coverage` + `/verify`

**ACTIVE_TASK.md → ## Test Results:**
```
### Test Plan
5 acceptance criteria → 7 tests (unit + integration)
Edge cases: empty results, unicode in data, --output to non-writable path

### Coverage Analysis
src/commands/export.py:   92% ✅
src/services/export.py:   88% ✅
src/formatters/csv.py:    95% ✅
Overall: 91% — above 85% target ✅

### Verification — Traceability Matrix
| Criterion | Test | Status |
|-----------|------|--------|
| stdout output | test_export_to_stdout | ✅ |
| --output file | test_export_to_file | ✅ |
| header row | test_header_row_present | ✅ |
| empty → header-only | test_empty_results_header_only | ✅ |
| streaming 100k rows | test_streaming_memory_usage | ✅ |

### Verdict: ✅ PASS
```

---

## Phase 5: Review

### `/review` + `/audit`

**ACTIVE_TASK.md → ## Review Findings:**
```
### Code Review
src/formatters/csv.py:18: MINOR: variable `r` in loop — rename to `row`.
src/services/export.py:34: MINOR: open() call in command layer leaks file handle on exception — use `with` statement or context manager in ExportCommand.

### Security Audit
No injection vectors (csv.writer uses parameterised writing).
No secrets exposure.
No auth surface (CLI tool, local execution only).

### Verdict: APPROVED_WITH_CHANGES
Fix MINOR items before merge (low risk, clean up only).
```

---

## Phase 6: Integration

### `/close`

```
task-log/20240115-[FE]-add-csv-export-to-data-pipeline-cli.md  ← created

Wait — this is a BE/CLI task.

task-log/20240115-[BE]-add-csv-export-to-data-pipeline-cli.md  ← created
.claude/context/BE_CONTEXT.md  ← updated with ExportCommand, ExportService, CsvFormatter
ACTIVE_TASK.md  ← reset to empty schema
```

---

## Key Takeaways

- `risk` correctly skipped for single-layer, no-external-dep, short-timeline feature
- Streaming criterion caught a real bug (naive list load) in TDD phase — not post-hoc
- ADR-001 on column order prevented a design debate during implementation
- `close` correctly tags [BE] from techStack=Python/CLI even though UI has no FE layer
