# Claude Code SDLC Harness

End-to-end software development harness for Claude Code. Meta-prompted skills, agents, workflows covering:
- Requirements intake
- Architecture & planning
- Implementation
- Testing & verification
- Code review
- Deployment

**Goal:** Representative SWAT skills covering complete SDLC, agnostic to tech stack.

## Quick Start

```bash
cd claude-code-harness
# (instructions TBD during implementation)
```

## Structure

- `.claude/skills/` — Phase-specific skills (intake, planning, implementation, testing, review, integration)
- `.claude/agents/` — Custom agents (orchestrator, meta-prompter, debugger, reviewer)
- `.claude/workflows/` — Multi-step pipelines (full-sdlc, bug-fix, feature-build, refactor)
- `docs/` — Design docs, meta-prompting patterns, examples
- `examples/` — Real SDLC walkthroughs (Python, Rust, TypeScript, etc.)

## Status

- [ ] Intake phase skill
- [ ] Planning phase skill
- [ ] Implementation phase skill
- [ ] Testing phase skill
- [ ] Review phase skill
- [ ] Integration phase skill
- [ ] Meta-prompter agent
- [ ] Orchestrator workflow
- [ ] Example walkthroughs

## References

- [Harness Engineering Principles](https://walkinglabs.github.io/learn-harness-engineering/en/)
- [Superpowers harness](https://github.com/anthropics/anthropic-sdk-python/tree/main/examples/harness-engineering)
- [SWAT methodology](https://www.anthropic.com)
