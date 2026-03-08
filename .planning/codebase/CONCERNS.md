# Codebase Concerns

**Analysis Date:** 2026-03-08

## Tech Debt

**Env API vs process.env Inconsistency:**
- Issue: The `Env` namespace (`packages/cli/src/env/index.ts`) creates a shallow copy of `process.env` for isolation, but multiple provider loaders bypass it and write to `process.env` directly because `Env.set` does not propagate to the real environment.
- Files: `packages/cli/src/provider/provider.ts` (lines 208-214, 414-420), `packages/cli/src/env/index.ts`
- Impact: Provider auth keys (AWS_BEARER_TOKEN_BEDROCK, AICORE_SERVICE_KEY) are set on `process.env` directly, defeating the isolation model. Parallel test runs or multi-instance scenarios could leak credentials across contexts.
- Fix approach: Either make `Env.set` write through to `process.env` (with explicit documentation that it's intentional), or refactor provider loaders to pass auth via SDK options rather than environment variables.

**Copilot SDK Fork (2,500+ lines):**
- Issue: The project maintains a full fork of two OpenAI-compatible language model implementations inside `packages/cli/src/provider/sdk/copilot/`. These files total 2,512 lines and contain TODO comments about lost type safety.
- Files: `packages/cli/src/provider/sdk/copilot/responses/openai-responses-language-model.ts` (1,732 lines), `packages/cli/src/provider/sdk/copilot/chat/openai-compatible-chat-language-model.ts` (780 lines)
- Impact: Difficult to keep in sync with upstream AI SDK changes. The comment at line 374 says "TODO we lost type safety on Chunk, most likely due to the error schema. MUST FIX" indicating known regression.
- Fix approach: Track upstream AI SDK releases, evaluate whether custom copilot provider can be upstreamed or reduced. At minimum, restore type safety on the Chunk type.

**Plugin System Type Safety Workarounds:**
- Issue: The plugin hook trigger function has a `@ts-expect-error` with a "try-counter: 2" comment, indicating repeated failed attempts to fix typing. Plugin config hook also uses `@ts-expect-error` for SDK v1/v2 mismatch.
- Files: `packages/cli/src/plugin/index.ts` (lines 111-113, 127-128)
- Impact: Plugin hooks execute with no compile-time type checking. Bugs in hook signatures will only surface at runtime.
- Fix approach: Migrate plugin system to SDK v2 types. Define a proper generic type for the trigger function that preserves input/output typing across all hook names.

**Deprecated Config Fields Still Active:**
- Issue: Multiple config schema fields are marked `@deprecated` but still parsed and handled in runtime code, creating dual code paths.
- Files: `packages/cli/src/config/config.ts` (lines 676, 698, 1010, 1043, 1129)
- Impact: New contributors may use deprecated fields. Dual code paths increase maintenance burden and risk of behavior divergence.
- Fix approach: Add deprecation warnings at runtime when deprecated fields are used. Set a removal timeline and migrate in a major version.

**Pervasive `as any` Type Casts:**
- Issue: Over 40 `as any` casts across the CLI source, concentrated in provider loading, session prompts, storage migration, and bus events.
- Files: `packages/cli/src/provider/provider.ts` (lines 87, 91, 926, 939), `packages/cli/src/session/prompt.ts` (lines 811, 813, 957, 959), `packages/cli/src/storage/json-migration.ts` (lines 154, 188, 314, 351, 376), `packages/cli/src/acp/agent.ts` (lines 173, 1669)
- Impact: Eliminates compile-time safety at critical boundaries (provider initialization, tool schema handling, data migration). Bugs hide until runtime.
- Fix approach: Prioritize removing `as any` from provider loading (most impactful) and session prompt tool registration. The migration file is a one-shot operation and lower priority.

**Dead/Scrap Code:**
- Issue: `packages/cli/src/util/scrap.ts` contains dummy placeholder functions (`foo`, `bar`, `dummyFunction`, `randomHelper`) with no apparent consumers.
- Files: `packages/cli/src/util/scrap.ts`
- Impact: Confusing for contributors, pollutes the codebase.
- Fix approach: Delete the file.

**Reasoning Token Cost Approximation:**
- Issue: Reasoning tokens are charged at the output token rate because models.dev lacks a distinct reasoning token price field.
- Files: `packages/cli/src/session/index.ts` (lines 858-860)
- Impact: Cost calculations are inaccurate for reasoning-heavy models (o3, Claude with extended thinking). Users see incorrect cost estimates.
- Fix approach: Add a `reasoning` cost field to the models.dev schema and consume it in the cost calculation.

**Disabled Directory Tree in System Prompt:**
- Issue: The environment section of the system prompt contains a dead code path: `project.vcs === "git" && false` means the directory tree is never included.
- Files: `packages/cli/src/session/system.ts` (line 48)
- Impact: The `<directories>` XML tag is always empty, wasting tokens on empty markup. Either enable the feature or remove the dead code.
- Fix approach: Remove the `&& false` guard and the empty `<directories>` block, or implement the tree listing properly.

**Permission Ruleset Not Persisted:**
- Issue: The permission "always allow" ruleset is computed at runtime but never saved to disk. Commented-out code shows the intent to persist via DB insert.
- Files: `packages/cli/src/permission/next.ts` (lines 227-229)
- Impact: Users who grant "always allow" permissions lose them on restart. Permissions must be re-granted each session.
- Fix approach: Implement the DB persistence (the commented code is almost complete) and add a UI for managing saved rules.

**Context Overflow Error Not Handled:**
- Issue: When a context overflow error occurs during processing, there is a TODO comment with no implementation.
- Files: `packages/cli/src/session/processor.ts` (line 357)
- Impact: Context overflow errors fall through to the generic retry logic rather than triggering compaction or a user-facing message. This can cause repeated failed retries on an inherently unrecoverable error.
- Fix approach: Trigger `SessionCompaction` when context overflow is detected, or surface a clear error to the user suggesting they start a new session.

## Security Considerations

**Symlink Path Traversal:**
- Risk: The `Filesystem.contains` function (`packages/cli/src/util/filesystem.ts`, line 134) performs lexical-only path comparison using `path.relative()`. Symlinks inside the project directory can point to files outside it, bypassing the containment check.
- Files: `packages/cli/src/util/filesystem.ts` (line 134), `packages/cli/src/file/index.ts` (lines 499-502, 575-578), `packages/cli/src/project/instance.ts` (lines 60, 64)
- Current mitigation: The TODO comments acknowledge the issue. On Linux/macOS, the check prevents basic `../` traversal.
- Recommendations: Use `fs.realpath()` to canonicalize paths before comparison. On Windows, also normalize drive letter casing. Add test cases for symlink traversal scenarios.

**Direct process.env Credential Mutation:**
- Risk: Provider loaders write API keys directly into `process.env` (e.g., `process.env.AWS_BEARER_TOKEN_BEDROCK = auth.key`). These persist for the lifetime of the process and could be read by child processes (bash tool, MCP servers).
- Files: `packages/cli/src/provider/provider.ts` (lines 214, 420)
- Current mitigation: None beyond the Env isolation layer, which is bypassed.
- Recommendations: Pass credentials via SDK constructor options rather than environment variables. If env vars are required by the SDK, set them only for the duration of the SDK call and unset afterward.

**MCP Server Process Tree Cleanup:**
- Risk: MCP server cleanup accesses `(client.transport as any)?.pid` to kill descendant processes. The `as any` cast means this may silently fail if the transport changes shape, leaving orphaned processes.
- Files: `packages/cli/src/mcp/index.ts` (lines 226-232)
- Current mitigation: Wrapped in try/catch, but failure is silent.
- Recommendations: Type the transport properly or add logging when pid is unavailable. Consider using process groups for reliable cleanup.

## Performance Bottlenecks

**Synchronous File Operations in Hot Paths:**
- Problem: Several modules use synchronous filesystem APIs (`readFileSync`, `existsSync`, `statSync`, `readdirSync`) in paths that could be async.
- Files: `packages/cli/src/storage/db.ts` (lines 54, 61, 63 - migration loading), `packages/cli/src/util/filesystem.ts` (lines 13, 18, 24-25), `packages/cli/src/config/config.ts` (lines 185, 299), `packages/cli/src/patch/index.ts` (line 315)
- Cause: Historical convenience. The DB migration loader reads all migration files synchronously at startup.
- Improvement path: For `Filesystem.exists/isDir/stat` in the utility module, these are deliberately sync for simplicity. For `storage/db.ts`, consider reading migrations asynchronously during startup. For `patch/index.ts`, the `readFileSync` at line 315 is in a hot path during file editing and should be async.

**models.dev Fetch on Module Load:**
- Problem: `packages/cli/src/provider/models.ts` (lines 124-132) fires a `ModelsDev.refresh()` fetch at module import time (top-level side effect) and sets up a 1-hour `setInterval`. This blocks or delays startup if the network is slow.
- Files: `packages/cli/src/provider/models.ts` (lines 124-132)
- Cause: Eager refresh to ensure fresh model data.
- Improvement path: The fetch is fire-and-forget (not awaited), but network timeouts (10s) can still impact startup perception. Consider deferring the initial fetch until after the first user interaction, or reducing the timeout for the initial fetch.

**Levenshtein Distance in Edit Tool:**
- Problem: The edit tool uses a full Levenshtein distance computation with O(n*m) time and space for fuzzy matching during file edits. Large files with large search blocks could be slow.
- Files: `packages/cli/src/tool/edit.ts` (lines 165-179, used by `BlockAnchorReplacer` at line 227)
- Cause: Intentional fallback matching strategy for when exact matches fail.
- Improvement path: Add early exit when distance exceeds threshold. Consider using a bounded Levenshtein or switching to a faster similarity metric for large inputs.

## Fragile Areas

**Provider Transform Layer:**
- Files: `packages/cli/src/provider/transform.ts` (955 lines)
- Why fragile: This file contains model-specific branching logic based on string matching of model IDs (e.g., `id.includes("deepseek")`, `id.includes("grok")`, `id.includes("claude")`). Every new model or provider requires adding more string-match branches. The reasoning effort mapping alone spans 200+ lines of conditional logic.
- Safe modification: When adding a new model, add a test case in `packages/cli/test/provider/transform.test.ts` first. Follow the existing pattern of checking model ID substrings.
- Test coverage: Well-tested at 2,353 lines of tests, but new model combinations can still produce unexpected interactions.

**Session Prompt Assembly:**
- Files: `packages/cli/src/session/prompt.ts` (1,983 lines)
- Why fragile: Assembles the full prompt from system prompts, tools, agents, permissions, structured output, and subtask routing. Multiple `as any` casts at tool registration boundaries. The TODO at line 351 acknowledges that "invoke tool" logic is not centralized.
- Safe modification: Use `packages/cli/test/session/prompt.test.ts` for any changes. Be careful with tool ID typing -- the `as any` casts exist because tool IDs are dynamically generated strings that don't match the type system's expectations.
- Test coverage: Has dedicated tests but the interaction between structured output, subtasks, and regular tools is complex.

**GitHub Actions Integration:**
- Files: `packages/cli/src/cli/cmd/github.ts` (1,631 lines)
- Why fragile: Large file handling GitHub Actions workflow (issue triggers, PR creation, branch management, OIDC auth, comment reactions). Heavy use of `console.log` for CI output. Multiple `nothrow()` git commands where failures are silently ignored.
- Safe modification: Test changes against actual GitHub Actions workflows. The `nothrow()` calls mean git failures (network issues, permission problems) are swallowed silently.
- Test coverage: Limited -- `packages/cli/test/cli/github-action.test.ts` and `packages/cli/test/cli/github-remote.test.ts` exist but the file is 1,631 lines.

**ACP Agent Interface:**
- Files: `packages/cli/src/acp/agent.ts` (1,742 lines)
- Why fragile: Second-largest source file. Handles the ACP (Agent Communication Protocol) with event subscription, message handling, permission forwarding, and model resolution. Uses `(event as any)?.payload` for event deserialization (line 173).
- Safe modification: Changes to event handling should be accompanied by updates to `packages/cli/test/acp/agent-interface.test.ts`.
- Test coverage: `packages/cli/test/acp/agent-interface.test.ts` exists but is only 1 file for 1,742 lines of code.

## Scaling Limits

**In-Memory Lock Map:**
- Current capacity: The `Lock` namespace (`packages/cli/src/util/lock.ts`) uses an in-memory `Map` for reader-writer locks.
- Limit: If many concurrent file operations target distinct paths, the map grows unbounded during a session. Locks are cleaned up when released, but under sustained high concurrency the map could become large.
- Scaling path: The current design is appropriate for single-process use. If multi-process coordination is ever needed, consider file-based locks or a lock server.

**SQLite Single-Writer:**
- Current capacity: SQLite with WAL mode supports concurrent reads but serializes writes. `busy_timeout` is set to 5000ms.
- Limit: Under heavy write load (many sessions saving simultaneously, especially during migration), writers can block for up to 5 seconds before failing.
- Files: `packages/cli/src/storage/db.ts` (line 80)
- Scaling path: Current setup is appropriate for a CLI tool. If server mode grows to handle many concurrent sessions, consider batching writes or moving to a client-server database.

## Dependencies at Risk

**Bun Runtime Workarounds:**
- Risk: Two separate workarounds for Bun bugs: `--no-cache` flag forced when proxied/CI due to [bun#19936](https://github.com/oven-sh/bun/issues/19936), and `timeout: false` on fetch due to [bun#16682](https://github.com/oven-sh/bun/issues/16682).
- Files: `packages/cli/src/config/config.ts` (line 271), `packages/cli/src/bun/index.ts` (line 92), `packages/cli/src/provider/provider.ts` (line 1097)
- Impact: Performance degradation from disabled caching. The timeout workaround could mask actual hanging requests.
- Migration plan: Monitor Bun issue tracker. Remove workarounds when upstream fixes are released. Add integration tests that verify the workarounds are still needed.

**Copilot Rate Limits:**
- Risk: The Copilot messages API integration is partially disabled due to rate limits. Comment says "TODO: re-enable once messages api has higher rate limits."
- Files: `packages/cli/src/plugin/copilot.ts` (lines 43-44)
- Impact: Copilot users are forced onto a less capable API path. The "hacky-ness" comment suggests the current workaround is not production-quality.
- Migration plan: Monitor GitHub Copilot API rate limit changes. Re-enable messages API when limits are raised.

**models.dev External Dependency:**
- Risk: Model metadata is fetched from `https://models.dev/api.json` at startup and every hour. If models.dev goes down, new installations without a bundled snapshot would have no model data.
- Files: `packages/cli/src/provider/models.ts` (lines 84-99, 106-121, 124-132)
- Impact: Complete failure to list available models if both the cache file and bundled snapshot are missing and the network request fails.
- Migration plan: The bundled snapshot (`models-snapshot.ts`) is a fallback. Ensure the snapshot is always up-to-date at build time. Consider adding a longer cache TTL or a stale-while-revalidate strategy.

## Test Coverage Gaps

**MCP Integration:**
- What's not tested: MCP server lifecycle management, OAuth flow, process tree cleanup, tool discovery.
- Files: `packages/cli/src/mcp/index.ts` (961 lines), `packages/cli/src/mcp/auth.ts`, `packages/cli/src/mcp/oauth-provider.ts`
- Risk: MCP is a complex subsystem managing external server processes. Silent failures in cleanup (orphaned processes) or auth (token refresh) would go unnoticed.
- Priority: High -- MCP servers are long-lived processes that interact with the OS process table.

**LSP Server Management:**
- What's not tested: LSP server downloading, installation, process lifecycle, auto-detection of language-specific servers.
- Files: `packages/cli/src/lsp/server.ts` (2,057 lines -- largest source file), `packages/cli/src/lsp/index.ts` (485 lines)
- Risk: LSP server installation downloads binaries from GitHub Releases (e.g., zls, clangd) using `as any` on response JSON. Download failures, architecture mismatches, and permission issues are all untested.
- Priority: High -- this file downloads and executes arbitrary binaries.

**Worktree Management:**
- What's not tested: Git worktree creation, cleanup, sandbox registration.
- Files: `packages/cli/src/worktree/index.ts` (643 lines)
- Risk: Worktree operations involve git commands that modify the repository state. Failures could leave orphaned worktrees or corrupt the git index.
- Priority: Medium -- worktrees are used for sandboxed execution.

**Storage Migration (JSON to SQLite):**
- What's not tested while running: The full end-to-end migration from JSON storage to SQLite, including edge cases like missing fields, corrupt JSON, and interrupted migrations.
- Files: `packages/cli/src/storage/json-migration.ts` (403 lines), `packages/cli/src/storage/storage.ts` (217 lines)
- Risk: Data loss during migration if edge cases are hit. The migration uses `any[]` arrays for batch inserts, bypassing type checking.
- Priority: Medium -- migration is a one-time operation but data loss is severe. Test file exists (`packages/cli/test/storage/json-migration.test.ts`, 846 lines) which is good, but uses `as any` extensively.

**Provider Custom Loaders:**
- What's not tested: Most of the 15+ custom provider loaders (AWS Bedrock, Azure, Vertex AI, SAP AI Core, Cloudflare, etc.) are defined in `packages/cli/src/provider/provider.ts` but only a subset have test coverage.
- Files: `packages/cli/src/provider/provider.ts` (lines 98-540)
- Risk: Auth flows, environment variable handling, and SDK initialization for specific providers could break without detection. The Amazon Bedrock test exists but is only 446 lines for a complex auth flow.
- Priority: Medium -- broken provider loading surfaces as user-facing errors.

**Snapshot System:**
- What's not tested: Snapshot creation, pruning, diff generation, and garbage collection via git.
- Files: `packages/cli/src/snapshot/index.ts` (159 lines)
- Risk: The snapshot system runs `git gc` with pruning and creates a separate git directory. Test file exists (`packages/cli/test/snapshot/snapshot.test.ts`, 1,180 lines) which provides good coverage.
- Priority: Low -- well-tested.

---

*Concerns audit: 2026-03-08*
