# Example Walkthrough: TypeScript API — Add Rate Limiting

End-to-end harness run for: **"Add rate limiting to TypeScript REST API"**
Stack: TypeScript, NestJS, Jest, PostgreSQL
Workflow: `feature-build`

Shows actual ACTIVE_TASK.md section output at each phase. Compare with Python CLI walkthrough to see how meta-prompts generate stack-specific output.

---

## Phase 1: Intake

### `/capture-requirements`

**Input:** "We need rate limiting on our NestJS API. Too many bots are hammering the /search endpoint. Limit to 100 requests per minute per IP. We have 1 week."

**ACTIVE_TASK.md → ## Requirement:**
```
type: feature
goal: "Add per-IP rate limiting to NestJS REST API"
techStack: TypeScript, NestJS, Jest, PostgreSQL
acceptanceCriteria:
  - Requests beyond 100/min per IP receive 429 Too Many Requests
  - Rate limit applies to all endpoints (global guard)
  - X-RateLimit-Limit and X-RateLimit-Remaining headers returned on every response
  - Whitelisted IPs (configurable) bypass rate limiting
  - Rate limit window resets after 60 seconds
scope:
  inScope: [rate limit guard, response headers, IP whitelist config]
  outOfScope: [per-user limits, per-endpoint limits, distributed rate limiting across nodes]
constraints:
  timeline: "1 week"
  teamSize: 1
  compatibility: "must not affect existing endpoint response shapes"
successMetrics:
  - "429 returned on request 101 within window"
  - "Headers present on all responses"
  - "Coverage >= 85%"
questions:
  - "Is single-node in-memory limiting acceptable, or do we have multiple instances?"
```

---

## Phase 2: Planning

### `/architecture-design`

**ACTIVE_TASK.md → ## Design:**
```
### Components
- RateLimitGuard    — NestJS Guard, extracts IP, checks ThrottlerService, sets headers
- ThrottlerService  — in-memory sliding window counter per IP, handles whitelist
- RateLimitConfig   — config module: limit, window, whitelistedIps (from env)
- RateLimitInterceptor — sets X-RateLimit-* headers on every response

### Data Flow
Request → RateLimitGuard
  → extract IP from X-Forwarded-For or req.ip
  → ThrottlerService.check(ip) → { allowed: bool, remaining: int, resetAt: Date }
  → if !allowed → throw HttpException(429)
  → if allowed → pass to handler
Response → RateLimitInterceptor → set X-RateLimit-Limit, X-RateLimit-Remaining headers

### API Contracts (internal)
ThrottlerService.check(ip: string): ThrottleResult
ThrottleResult: { allowed: boolean; remaining: number; resetAt: Date }
RateLimitConfig: { limit: number; windowMs: number; whitelistedIps: string[] }

### Tech Stack
@nestjs/throttler: NestJS built-in — evaluate vs. custom (→ decision-grill)
NestJS Guards + Interceptors: standard pattern, no new deps
In-memory Map: acceptable for single-node (→ decision-grill)

### Open Questions (→ decision-grill)
- @nestjs/throttler built-in vs. custom ThrottlerService?
- In-memory Map vs. Redis for rate limit storage?
```

### `/decision-grill`

**ACTIVE_TASK.md → ## ADRs:**
```
### ADR-001: @nestjs/throttler vs. Custom Implementation
Context: NestJS ships @nestjs/throttler. Custom gives full control over headers and whitelist.
Options: @nestjs/throttler, custom ThrottlerService
Decision: @nestjs/throttler
Rationale: Requirements fit built-in exactly (per-IP, global, configurable window). Custom adds maintenance burden with no benefit for stated requirements. Whitelist and custom headers configurable via ThrottlerGuard extension.
Consequences: Tied to @nestjs/throttler API — acceptable for this scope.
Rejected: custom — over-engineering for requirements that fit the built-in.

### ADR-002: In-Memory vs. Redis Storage
Context: In-memory is simple but doesn't share state across instances. Redis is distributed but adds infra dependency.
Options: in-memory (Map), Redis
Decision: in-memory
Rationale: Single-node per requirements scope. Out-of-scope: "distributed rate limiting across nodes". In-memory avoids Redis infra cost for stated constraints.
Consequences: Rate limit resets on restart; doesn't work across multiple instances — documented as known limitation.
Rejected: Redis — out of scope, adds infra dependency not justified by requirements.
```

### `/risk-assessment`

**ACTIVE_TASK.md → ## Risks:**
```
### Risk Registry
| ID | Description | L | I | Severity | Mitigation |
|----|-------------|---|---|----------|------------|
| R-01 | IP spoofing via X-Forwarded-For | M | H | High | Trust X-Forwarded-For only behind known proxy; validate with trustProxy config |
| R-02 | In-memory state lost on restart | L | M | Low | Document; acceptable per ADR-002 |
| R-03 | @nestjs/throttler upgrade breaks guard API | L | L | Low | Pin version; test on upgrade |

### Top 3 Risks
1. R-01: IP spoofing (High) — mitigate in RateLimitGuard IP extraction
2. R-02: Memory reset on restart (Low) — documented limitation
3. R-03: Library upgrade breakage (Low) — version pin

### Assumptions Log
- Single NestJS instance (confirmed in requirements scope)
- X-Forwarded-For set by load balancer (not spoofable from public internet — verify infra config)
```

---

## Phase 3: Implementation

### `/code-gen`

**ACTIVE_TASK.md → ## Implementation Log:**
```
### Implementation — 2024-01-20
Files created:
- src/rate-limit/rate-limit.module.ts     (ThrottlerModule config)
- src/rate-limit/rate-limit.guard.ts      (extends ThrottlerGuard, IP extraction)
- src/rate-limit/rate-limit.interceptor.ts (X-RateLimit-* headers)
- src/rate-limit/rate-limit.config.ts     (env-based config)
- src/app.module.ts                       (updated — register RateLimitModule globally)
Status: initial-implementation
Deviations: none — @nestjs/throttler fits requirements exactly per ADR-001
Next: tdd
```

### `/tdd`

**ACTIVE_TASK.md → ## Implementation Log (appended):**
```
### TDD — Criterion: 429 on request 101 within window
Test: src/rate-limit/rate-limit.guard.spec.ts::should return 429 after limit exceeded
Red: Expected 429, received 200 — guard not registered globally
Delta: Register RateLimitGuard as APP_GUARD in AppModule
Green: ✅

### TDD — Criterion: X-RateLimit headers on every response
Test: src/rate-limit/rate-limit.interceptor.spec.ts::should set rate limit headers
Red: Headers missing — interceptor not wired
Delta: Register RateLimitInterceptor as APP_INTERCEPTOR in AppModule
Green: ✅

### TDD — Criterion: Whitelisted IP bypasses limit
Test: src/rate-limit/rate-limit.guard.spec.ts::should allow whitelisted IP past limit
Red: 429 returned for whitelisted IP
Delta: RateLimitGuard.canActivate() checks whitelist before ThrottlerGuard
Green: ✅

### TDD — Criterion: Window resets after 60s
Test: src/rate-limit/rate-limit.guard.spec.ts::should reset after window
Red: Requests blocked after window (fake timer issue)
Delta: Use Jest fake timers; advance 61000ms; verify request accepted
Green: ✅
All 4 criteria: ✅ green
```

---

## Phase 4: Testing

### `/test-design` + `/coverage-analysis` + `/verification`

**ACTIVE_TASK.md → ## Test Results:**
```
### Coverage Analysis
src/rate-limit/rate-limit.guard.ts:        89% ✅
src/rate-limit/rate-limit.interceptor.ts:  94% ✅
src/rate-limit/rate-limit.config.ts:       100% ✅
Overall: 91% — above 85% target ✅

### Verification — Traceability Matrix
| Criterion | Test | Status |
|-----------|------|--------|
| 429 after limit | should return 429 after limit exceeded | ✅ |
| Headers on all responses | should set rate limit headers | ✅ |
| Whitelist bypass | should allow whitelisted IP past limit | ✅ |
| Window reset | should reset after window | ✅ |

### Verdict: ✅ PASS
```

---

## Phase 5: Review

### `/code-review` + `/security-audit`

**ACTIVE_TASK.md → ## Review Findings:**
```
### Code Review
src/rate-limit/rate-limit.guard.ts:22: IMPORTANT: X-Forwarded-For not sanitised — take only first IP from comma-separated list (proxies can append multiple). Fix: ip.split(',')[0].trim()
src/rate-limit/rate-limit.config.ts:8: MINOR: WHITELISTED_IPS env var not validated — invalid IPs silently ignored. Add IP format check on startup.

### Security Audit
src/rate-limit/rate-limit.guard.ts:22: HIGH: IP Spoofing — X-Forwarded-For header accepts user-supplied value without proxy validation. Mitigate: configure NestJS trustProxy; document infra requirement (load balancer must strip user X-Forwarded-For).
No secrets exposure. No auth surface changes. No SQL queries introduced.

### Verdict: APPROVED_WITH_CHANGES
Fix HIGH (IP spoofing mitigation — trustProxy config + docs) and IMPORTANT before merge.
```

---

## Phase 6: Integration

### `close`

```
task-log/20240120-[BE]-add-rate-limiting-to-nestjs-api.md  ← created
.claude/context/BE_CONTEXT.md  ← updated

BE_CONTEXT.md additions:
  RateLimitGuard    — global IP-based rate limiting (100/min, @nestjs/throttler)
  RateLimitInterceptor — sets X-RateLimit-* headers on all responses
  Known constraint: single-node in-memory only (Redis out of scope — ADR-002)
  Known constraint: requires trustProxy config in infra (X-Forwarded-For hardening)

ACTIVE_TASK.md  ← reset to empty schema
```

---

## Stack Contrast: Python CLI vs. TypeScript API

| Dimension | Python CLI | TypeScript API |
|-----------|-----------|----------------|
| Test framework | pytest + pytest-click | Jest + NestJS testing module |
| Streaming concern | Memory-safe generator | Not applicable |
| Security surface | None (local CLI) | IP spoofing via X-Forwarded-For |
| ADR driver | Column order (UX) | Storage strategy (infra) |
| Risk assessment | Skipped (single layer, no deps) | Required (R-01: IP spoofing High) |
| Close-task tag | `[BE]` (CLI = backend) | `[BE]` |
| Context update | BE_CONTEXT (ExportService) | BE_CONTEXT (RateLimitGuard) |

Same harness, same workflow, different meta-prompt outputs — stack-agnostic confirmed.
