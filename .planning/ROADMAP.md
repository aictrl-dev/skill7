# Roadmap: Aictrl CLI Hardening

## Overview

10 phases covering 31 requirements derived from a 5-engineer code review. Phases follow dependency order: process exit paths first (everything depends on clean startup/shutdown), then security boundaries (highest-risk findings), session reliability (must be stable before testing data fixes), data correctness, and operational quality last. Every phase delivers a verifiable capability improvement to headless CI execution via `aictrl run`.

## Phases

- [ ] **Phase 01: Process Exit Path** - `aictrl run` propagates errors and exits cleanly instead of hanging
- [ ] **Phase 02: Instance Lifecycle** - Bootstrap, init, and dispose cannot poison state or mask errors
- [ ] **Phase 03: Input Sanitization & Security** - Path traversal, XSS, and env injection attacks are blocked
- [ ] **Phase 04: Shell Execution Safety** - Bash tool permission checks cannot be bypassed and output is bounded
- [ ] **Phase 05: MCP & External Process Safety** - MCP connections time out and clean up child processes
- [ ] **Phase 06: Prompt Loop Reliability** - Session prompt cycle handles cancellation, errors, and compaction races
- [ ] **Phase 07: Event Bus Resilience** - Bus publish isolates failures and event timing races are eliminated
- [ ] **Phase 08: Data Mutation Correctness** - State updates, DB writes, and tool edits apply in correct order
- [ ] **Phase 09: Provider & Model Robustness** - Model parsing and cost calculation handle all provider formats
- [ ] **Phase 10: Operational Hardening** - File locking, caching, PRAGMA safety, and logging initialization

## Phase Details

### Phase 01: Process Exit Path
**Goal:** `aictrl run` always exits with a clear error code and message when something fails, instead of hanging or swallowing errors silently
**Depends on:** Nothing (first phase -- addresses the bug that directly caused silent CI failures)
**Requirements:** PROC-01, PROC-02
**Success Criteria** (what must be TRUE):
  1. When `SessionPrompt.prompt()` throws during `aictrl run`, the error propagates to the CLI exit handler and the process exits with code 1
  2. When an uncaught exception occurs, the process logs the full stack trace and exits with code 1 (not just logs and continues)
  3. No `.catch(() => {})` patterns remain in the `aictrl run` critical path
  4. A regression test confirms that a simulated prompt failure causes `aictrl run` to exit non-zero
**Plans:** 2 plans

Plans:
- [ ] 01-01-PLAN.md -- Fix fire-and-forget error swallowing in run.ts (PROC-01)
- [ ] 01-02-PLAN.md -- Fix uncaughtException/unhandledRejection handlers to exit cleanly (PROC-02)

### Phase 02: Instance Lifecycle
**Goal:** Instance bootstrap, initialization, and disposal handle failures gracefully without poisoning cached state or masking original errors
**Depends on:** Phase 01 (process must exit cleanly for lifecycle errors to surface)
**Requirements:** PROC-03, PROC-04, PROC-05
**Success Criteria** (what must be TRUE):
  1. When `Instance.init()` rejects, subsequent calls retry instead of returning the cached rejected promise
  2. When `Instance.dispose()` runs in a finally block after an error, the original error propagates (not Context.NotFound)
  3. When database migration fails mid-flight, the next launch detects partial state and either completes or reports the issue
  4. A regression test confirms that a failed init does not permanently poison the instance
**Plans:** TBD

Plans:
- [ ] 02-01: Fix Instance.init() rejected promise caching
- [ ] 02-02: Fix Instance.dispose() error masking in finally blocks
- [ ] 02-03: Add migration failure handling and partial state recovery

### Phase 03: Input Sanitization & Security
**Goal:** All user-controlled and externally-sourced inputs are sanitized before use in filesystem operations, HTML rendering, and environment variable expansion
**Depends on:** Phase 02 (instance must initialize correctly for security checks to run)
**Requirements:** SEC-01, SEC-02, SEC-04, SEC-05
**Success Criteria** (what must be TRUE):
  1. A skill with `name: "../../../etc/passwd"` or `file: "../../secret"` is rejected during discovery with a clear error
  2. `Filesystem.contains()` resolves symlinks via `fs.realpath()` before comparison, so a symlink pointing outside the project is correctly detected
  3. OAuth callback HTML escapes `error_description` so injected `<script>` tags render as text, not executable code
  4. `{env:VAR}` substitution only expands variables from a defined allowlist; attempting to expand `{env:SECRET_KEY}` (not in allowlist) returns empty or errors
**Plans:** TBD

Plans:
- [ ] 03-01: Sanitize skill discovery paths against traversal
- [ ] 03-02: Add symlink-aware path containment to Filesystem.contains
- [ ] 03-03: Escape OAuth callback error_description HTML output
- [ ] 03-04: Implement env variable allowlist for config substitution

### Phase 04: Shell Execution Safety
**Goal:** The bash tool's permission system cannot be bypassed via shell syntax tricks, and output accumulation is bounded to prevent OOM
**Depends on:** Phase 03 (security boundary patterns established)
**Requirements:** SEC-03, RES-01
**Success Criteria** (what must be TRUE):
  1. A command using heredoc syntax (`cat << EOF ... EOF`) to embed a denied command is correctly caught by permission checks
  2. A command using command substitution (`$(denied_command)`) to bypass AST validation is correctly caught
  3. Bash tool output accumulation is capped at a configurable maximum; when exceeded, old output is truncated with a clear marker
  4. A long-running command producing unbounded output does not cause the aictrl process to run out of memory
**Plans:** TBD

Plans:
- [ ] 04-01: Extend bash permission checks to cover heredocs and command substitution
- [ ] 04-02: Implement output buffer cap with truncation for bash tool

### Phase 05: MCP & External Process Safety
**Goal:** MCP connections and custom tool loading cannot hang indefinitely or leak child processes
**Depends on:** Phase 04 (tool-level safety patterns established)
**Requirements:** RES-02, RES-03, RES-04
**Success Criteria** (what must be TRUE):
  1. `MCP.startAuth` connect call times out after a configurable duration and returns a clear timeout error
  2. When an MCP connection times out, the associated child process (stdio transport) is killed and does not remain as an orphan
  3. Custom tool loading from `tool/` directories validates that source paths are not symlinks pointing outside the project, or if they are, integrity is verified
  4. A regression test confirms that a hanging MCP server is cleaned up after timeout
**Plans:** TBD

Plans:
- [ ] 05-01: Add connection timeout to MCP startAuth
- [ ] 05-02: Implement child process cleanup for timed-out MCP connections
- [ ] 05-03: Add symlink/integrity checks to custom tool loading

### Phase 06: Prompt Loop Reliability
**Goal:** The session prompt cycle handles cancellation, unhandled rejections, compaction races, and infinite retries without leaving dangling promises or crashing
**Depends on:** Phase 02 (instance lifecycle must be stable before session work)
**Requirements:** SESS-01, SESS-02, SESS-05, SESS-06
**Success Criteria** (what must be TRUE):
  1. When a session is cancelled or errors, all queued prompt callback promises are rejected with a clear reason (no dangling unresolved promises)
  2. `ensureTitle()` failures are caught and do not crash the process with an unhandled rejection
  3. `SessionCompaction.prune()` cannot race with session teardown -- either prune completes before teardown or is cancelled
  4. The retry loop enforces a maximum attempt cap; a server returning `retry-after` headers indefinitely hits the cap and fails with a clear error
**Plans:** TBD

Plans:
- [ ] 06-01: Reject queued prompt callbacks on cancel/error
- [ ] 06-02: Add catch handler to ensureTitle fire-and-forget
- [ ] 06-03: Serialize compaction prune with session teardown
- [ ] 06-04: Add max retry cap to the retry loop

### Phase 07: Event Bus Resilience
**Goal:** Bus event publishing is isolated from subscriber failures and timing races in the event generator are eliminated
**Depends on:** Phase 06 (session prompt stability required to test bus behavior under load)
**Requirements:** SESS-03, SESS-04, OPS-05
**Success Criteria** (what must be TRUE):
  1. When a bus subscriber throws during `Bus.publish()`, other subscribers still receive the event and the streaming loop continues
  2. `SessionSummary.summarize()` DB failures are caught and logged instead of causing an unhandled rejection
  3. The `run.ts` GlobalBus listener does not miss fast-path idle events due to a registration race -- events emitted before the listener attaches are handled
**Plans:** TBD

Plans:
- [ ] 07-01: Isolate subscriber failures in Bus.publish
- [ ] 07-02: Add error handling to SessionSummary.summarize fire-and-forget
- [ ] 07-03: Fix GlobalBus listener race with fast-path idle events in run.ts

### Phase 08: Data Mutation Correctness
**Goal:** In-memory state updates, database writes, and multi-file edits happen in the correct order with proper serialization
**Depends on:** Phase 07 (bus event ordering fixed before testing state mutation order)
**Requirements:** DATA-01, DATA-02, DATA-03, DATA-04
**Success Criteria** (what must be TRUE):
  1. Multi-edit tool applies each edit to its own `filePath` -- editing files A and B in one call modifies both files (not just the outer path)
  2. Bus events for status changes are published after the in-memory state is updated, so subscribers always see the current state
  3. `Session.updatePart()` DB writes from concurrent stream handlers are serialized and do not produce write conflicts or lost updates
  4. Latency tracking `text-end` event preserves the original stream start time instead of overwriting it
**Plans:** TBD

Plans:
- [ ] 08-01: Fix multi-edit tool filePath routing
- [ ] 08-02: Reorder bus event publish to after state update
- [ ] 08-03: Serialize Session.updatePart DB writes
- [ ] 08-04: Fix latency tracking start time preservation

### Phase 09: Provider & Model Robustness
**Goal:** Model identifier parsing and cost calculation produce correct results for all supported providers
**Depends on:** Phase 08 (data correctness patterns established)
**Requirements:** DATA-05, OPS-06
**Success Criteria** (what must be TRUE):
  1. `parseModel("anthropic")` (bare provider string with no model) returns a sensible default or a clear error instead of producing an empty modelID
  2. Cost calculation for OpenAI, Google, and other non-Anthropic providers uses the correct per-token pricing from models.dev data
  3. Regression tests cover bare provider strings, provider/model pairs, and model-only strings for all major providers
**Plans:** TBD

Plans:
- [ ] 09-01: Fix parseModel to handle bare provider strings
- [ ] 09-02: Fix cost calculation for non-Anthropic providers

### Phase 10: Operational Hardening
**Goal:** File-based stores handle concurrency, repeated fetches are cached, database pragmas are restored, and logging initializes safely
**Depends on:** Phase 09 (all correctness fixes in place before operational polish)
**Requirements:** OPS-01, OPS-02, OPS-03, OPS-04
**Success Criteria** (what must be TRUE):
  1. Concurrent OAuth token writes do not corrupt the JSON token store -- file locking prevents interleaved writes
  2. URL instruction fetches are cached per-session so the same URL is fetched once, not once per step
  3. `PRAGMA synchronous=OFF` set during migration is restored to the default value after migration completes (even on error)
  4. `Log.Default` calls before `Log.init()` do not write to stderr or throw -- they are buffered or silently dropped
**Plans:** TBD

Plans:
- [ ] 10-01: Add file locking to OAuth token store
- [ ] 10-02: Cache URL instruction fetches per-session
- [ ] 10-03: Restore PRAGMA synchronous after migration
- [ ] 10-04: Guard Log.Default against pre-init writes

## Progress

**Execution Order:** 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08 -> 09 -> 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 01. Process Exit Path | 0/2 | Planned | - |
| 02. Instance Lifecycle | 0/3 | Not started | - |
| 03. Input Sanitization & Security | 0/4 | Not started | - |
| 04. Shell Execution Safety | 0/2 | Not started | - |
| 05. MCP & External Process Safety | 0/3 | Not started | - |
| 06. Prompt Loop Reliability | 0/4 | Not started | - |
| 07. Event Bus Resilience | 0/3 | Not started | - |
| 08. Data Mutation Correctness | 0/4 | Not started | - |
| 09. Provider & Model Robustness | 0/2 | Not started | - |
| 10. Operational Hardening | 0/4 | Not started | - |
