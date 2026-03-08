# Aictrl CLI Hardening

## What This Is

Reliability and security hardening of the aictrl CLI — a headless AI agent execution engine forked from OpenCode. This project addresses 31 findings from a 5-engineer code review covering error handling, security boundaries, resource management, and operational reliability. The primary deployment target is headless CI execution via `aictrl run`.

## Core Value

Every `aictrl run` invocation must either complete successfully or fail with a clear, actionable error — never hang, silently swallow errors, or leak resources.

## Requirements

### Validated

- ✓ Headless execution via `aictrl run` — existing
- ✓ Multi-provider LLM support (Anthropic, OpenAI, Google, etc.) — existing
- ✓ Tool execution (bash, file edit, read, grep, glob) — existing
- ✓ MCP server integration — existing
- ✓ Plugin/skill system with discovery — existing
- ✓ SQLite persistence with Drizzle ORM — existing
- ✓ Session compaction for long conversations — existing
- ✓ NDJSON output format for CI observability — existing
- ✓ Snapshot/undo system via git — existing
- ✓ Per-project context isolation via AsyncLocalStorage — existing

### Active

**CRITICAL — Error Handling & Process Lifecycle**
- [ ] PROC-01: Fire-and-forget in run.ts must propagate errors instead of swallowing with `.catch(() => {})`
- [ ] PROC-02: uncaughtException handler must exit the process cleanly
- [ ] PROC-03: Instance.init rejected promise must not be cached permanently
- [ ] PROC-04: Instance.dispose must not mask original errors with Context.NotFound
- [ ] PROC-05: Migration failure must be caught and marker state handled correctly

**CRITICAL — Security Boundaries**
- [ ] SEC-01: Skill discovery must sanitize paths to prevent traversal attacks
- [ ] SEC-02: Symlink-aware path containment in Filesystem.contains
- [ ] SEC-03: Bash permission checks must align with actual shell execution (heredoc/substitution bypass)
- [ ] SEC-04: OAuth callback must escape error_description to prevent XSS
- [ ] SEC-05: `{env:VAR}` config substitution must have an allowlist

**CRITICAL — Resource Management**
- [ ] RES-01: Bash tool output must be bounded to prevent OOM
- [ ] RES-02: MCP startAuth must have a connection timeout
- [ ] RES-03: Timed-out MCP connections must not leak child processes
- [ ] RES-04: Custom tool loading must not follow symlinks without integrity checks

**CRITICAL — Session Reliability**
- [ ] SESS-01: Queued prompt callbacks must be rejected on cancel/error (no dangling promises)
- [ ] SESS-02: ensureTitle must be awaited or caught
- [ ] SESS-03: SessionSummary.summarize fire-and-forget must handle DB failures
- [ ] SESS-04: Bus publish must not let one bad subscriber crash the streaming loop
- [ ] SESS-05: SessionCompaction.prune must not race with session teardown
- [ ] SESS-06: Retry loop must have a max attempt cap

**IMPORTANT — Data Integrity & Observability**
- [ ] DATA-01: Multi-edit tool must respect per-edit filePath
- [ ] DATA-02: Bus event must be published after in-memory state update (not before)
- [ ] DATA-03: Session.updatePart DB writes must be serialized or awaited
- [ ] DATA-04: Latency tracking must not overwrite stream start time
- [ ] DATA-05: parseModel must handle bare provider strings gracefully

**IMPORTANT — Operational Quality**
- [ ] OPS-01: OAuth token store must handle concurrent access (file locking)
- [ ] OPS-02: URL instruction fetches must be cached (not O(steps × urls))
- [ ] OPS-03: PRAGMA synchronous=OFF must be restored after migration
- [ ] OPS-04: Log.Default must not write before Log.init()
- [ ] OPS-05: GlobalBus listener race in run.ts generator must be fixed
- [ ] OPS-06: Cost calculation for non-Anthropic providers must be corrected

### Out of Scope

- Feature development — this project is purely hardening existing functionality
- Copilot SDK fork reduction — tracked separately, large scope
- Deprecated config field migration — not a reliability issue
- `as any` type safety audit — quality improvement, not hardening
- Dead code cleanup (scrap.ts etc.) — trivial, not worth project overhead
- UI/TUI improvements — headless-first focus
- Performance optimization (sync fs, Levenshtein) — not reliability-critical

## Context

**Origin:** 5-engineer parallel code review of the full CLI codebase (2026-03-08) produced 31 findings ranked by confidence score (80-95). Findings span entry/bootstrap, session/prompt, tools/permissions, provider/streaming, and MCP/plugins/skills.

**Deployment:** Primary use case is headless CI via GitHub Actions (`aictrl run --format json`). The fire-and-forget bug (#1) directly caused silent CI failures. Process lifecycle issues (#14) cause CI jobs to appear hung instead of failing cleanly.

**Codebase:** ~50k lines TypeScript across 5 packages (cli, sdk, plugin, util, script). Bun runtime with compiled binary distribution. See `.planning/codebase/` for full mapping.

**Review findings:** 16 CRITICAL (95-85 confidence), 15 IMPORTANT (88-80 confidence). All findings include exact file paths, line numbers, and concrete fix recommendations.

## Constraints

- **Runtime**: Bun — must work with Bun-specific APIs and known bugs (bun#19936, bun#16682)
- **Backwards compatibility**: Fix must not break existing config files, sessions, or plugin APIs
- **Test coverage**: Every fix must include a regression test
- **No feature changes**: Fixes must be surgical — no refactoring beyond what the fix requires

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Prioritize headless CI path | Primary deployment target; fire-and-forget bug caused real CI failures | — Pending |
| Fix all 16 CRITICAL before IMPORTANT | CRITICAL findings have higher confidence and impact | — Pending |
| Require regression tests per fix | Prevent regressions; current test gaps contributed to these issues | — Pending |

---
*Last updated: 2026-03-08 after initialization*
