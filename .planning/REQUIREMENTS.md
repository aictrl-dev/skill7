# Requirements

## v1 Requirements

### Error Handling & Process Lifecycle

- [ ] **PROC-01**: `aictrl run` must propagate all errors from `SessionPrompt.prompt()` instead of swallowing with `.catch(() => {})` — `run.ts:713-720`
- [ ] **PROC-02**: `uncaughtException` handler must call `process.exit(1)` and preserve stack traces — `index.ts:32-42`
- [ ] **PROC-03**: `Instance.init()` rejected promise must not be cached permanently, poisoning all future calls — `instance.ts:23-43`
- [ ] **PROC-04**: `Instance.dispose()` must not throw `Context.NotFound` in finally blocks, masking the original error — `instance.ts:69-81`
- [ ] **PROC-05**: Database migration failure must be caught; partial migration state must be handled on next launch — `index.ts:92-117`

### Security Boundaries

- [ ] **SEC-01**: Remote skill downloads must sanitize `skill.name`/`file` to prevent path traversal (arbitrary filesystem write) — `discovery.ts:81-86`
- [ ] **SEC-02**: `Filesystem.contains()` must use `fs.realpath()` to resolve symlinks before path comparison — `filesystem.ts:134`
- [ ] **SEC-03**: Bash tool permission checks must cover heredocs and command substitutions that bypass AST-based validation — `bash.ts:93-172`
- [ ] **SEC-04**: OAuth callback HTML must escape `error_description` to prevent XSS — `oauth-callback.ts:94-102`
- [ ] **SEC-05**: `{env:VAR}` config substitution must restrict to an allowlist of safe variables — `paths.ts:86-88`

### Resource Management

- [ ] **RES-01**: Bash tool must cap accumulated output buffer to prevent OOM on long-running commands — `bash.ts:183-205`
- [ ] **RES-02**: MCP `startAuth` connect must have a timeout to prevent permanent hangs — `mcp/index.ts:793`
- [ ] **RES-03**: Timed-out MCP connection promises must clean up child processes (no orphans) — `timeout.ts:1-14`
- [ ] **RES-04**: Custom tool loading from config `tool/` dirs must not follow symlinks without integrity checks — `registry.ts:40-52`

### Session Reliability

- [ ] **SESS-01**: Queued prompt callback promises must be rejected on cancel/error — no dangling promises or memory leaks — `prompt.ts:64-84,279`
- [ ] **SESS-02**: `ensureTitle()` must be awaited or have a catch handler — unhandled rejection currently crashes process — `prompt.ts:328-334`
- [ ] **SESS-03**: `SessionSummary.summarize()` fire-and-forget must handle DB failures explicitly — `processor.ts:278`
- [ ] **SESS-04**: `Bus.publish()` must isolate subscriber failures — one bad subscriber must not crash the streaming loop — `bus/index.ts:52-63`
- [ ] **SESS-05**: `SessionCompaction.prune()` must not race with session teardown — `prompt.ts:738`
- [ ] **SESS-06**: Retry loop must enforce a max attempt cap — `retry-after` header can currently cause infinite retries — `processor.ts:359-370`

### Data Integrity & Observability

- [ ] **DATA-01**: Multi-edit tool must apply each edit to its own `filePath`, not redirect all to the outer param — `multiedit.ts:30`
- [ ] **DATA-02**: Bus events must be published after in-memory state is updated, not before — `status.ts:61-75`
- [ ] **DATA-03**: `Session.updatePart()` DB writes in stream handlers must be serialized or awaited — `prompt.ts:1670`
- [ ] **DATA-04**: Latency tracking `text-end` event must not overwrite the stream start time — `processor.ts:329-332`
- [ ] **DATA-05**: `parseModel()` must handle bare provider strings gracefully instead of producing empty modelID — `provider.ts:1305-1311`

### Operational Quality

- [ ] **OPS-01**: OAuth JSON token store must handle concurrent access with file locking — `mcp/auth.ts:56-78`
- [ ] **OPS-02**: URL instruction fetches must be cached per-session — not O(steps × urls) — `instruction.ts:126-151`
- [ ] **OPS-03**: `PRAGMA synchronous=OFF` set during migration must be restored afterward — `json-migration.ts:49-52`
- [ ] **OPS-04**: `Log.Default` must not write to stderr before `Log.init()` has been called — `log.ts:55-58`
- [ ] **OPS-05**: GlobalBus listener in `run.ts` generator must not race with fast-path idle events — `run.ts:646-671`
- [ ] **OPS-06**: Cost calculation for non-Anthropic providers must use correct token pricing — `session/index.ts:814-820`

## v2 Requirements

(None — all findings scoped to v1)

## Out of Scope

- Copilot SDK fork reduction — separate project, 2,500+ lines of forked code
- `as any` type safety audit — quality improvement, not a reliability fix
- Deprecated config field migration — not causing failures
- Dead code cleanup — trivial, doesn't warrant project overhead
- Performance optimization (sync fs, Levenshtein) — not reliability-critical
- UI/TUI improvements — headless-first focus

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| PROC-01 | — | Pending |
| PROC-02 | — | Pending |
| PROC-03 | — | Pending |
| PROC-04 | — | Pending |
| PROC-05 | — | Pending |
| SEC-01 | — | Pending |
| SEC-02 | — | Pending |
| SEC-03 | — | Pending |
| SEC-04 | — | Pending |
| SEC-05 | — | Pending |
| RES-01 | — | Pending |
| RES-02 | — | Pending |
| RES-03 | — | Pending |
| RES-04 | — | Pending |
| SESS-01 | — | Pending |
| SESS-02 | — | Pending |
| SESS-03 | — | Pending |
| SESS-04 | — | Pending |
| SESS-05 | — | Pending |
| SESS-06 | — | Pending |
| DATA-01 | — | Pending |
| DATA-02 | — | Pending |
| DATA-03 | — | Pending |
| DATA-04 | — | Pending |
| DATA-05 | — | Pending |
| OPS-01 | — | Pending |
| OPS-02 | — | Pending |
| OPS-03 | — | Pending |
| OPS-04 | — | Pending |
| OPS-05 | — | Pending |
| OPS-06 | — | Pending |
