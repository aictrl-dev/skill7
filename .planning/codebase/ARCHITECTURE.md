# Architecture

**Analysis Date:** 2026-03-08

## Pattern Overview

**Overall:** Headless AI Agent Engine with Event-Driven Architecture

The CLI is a headless execution engine for AI agent skills. It uses a layered namespace-based architecture with an event bus for cross-component communication. The core loop is: user prompt -> session -> LLM stream -> tool execution -> response. Multiple project instances can run concurrently via `AsyncLocalStorage` context isolation.

**Key Characteristics:**
- TypeScript namespace modules (`export namespace Foo {}`) as the primary code organization pattern
- Event bus (pub/sub) for decoupled communication between components
- `AsyncLocalStorage`-based context for per-project instance isolation
- Lazy-loaded AI provider SDKs via dynamic imports
- SQLite (bun:sqlite + Drizzle ORM) for persistent storage
- Zod schemas for all data types, used for both validation and OpenAPI generation
- Plugin system with lifecycle hooks for extensibility

## Layers

**CLI Layer (Entry & Commands):**
- Purpose: Parse CLI arguments, dispatch to handlers
- Location: `packages/cli/src/cli/`
- Contains: Yargs command definitions, UI helpers, bootstrap logic
- Depends on: Session, Agent, Provider, Config
- Used by: End users via `aictrl` binary
- Key files:
  - `packages/cli/src/index.ts` - Main entry point, yargs setup, command registration
  - `packages/cli/src/cli/cmd/run.ts` - Primary `run` command (send message, stream events)
  - `packages/cli/src/cli/cmd/cmd.ts` - Command helper wrapper
  - `packages/cli/src/cli/bootstrap.ts` - Instance bootstrap wrapper
  - `packages/cli/src/cli/ui.ts` - Terminal output helpers

**Project/Instance Layer:**
- Purpose: Per-project context isolation and lifecycle management
- Location: `packages/cli/src/project/`
- Contains: Project detection (git), instance context, VCS integration, bootstrap
- Depends on: Database, Global, Config
- Used by: All layers that need project-scoped state
- Key files:
  - `packages/cli/src/project/instance.ts` - `Instance.provide()` creates AsyncLocalStorage context; `Instance.state()` creates per-instance memoized state
  - `packages/cli/src/project/bootstrap.ts` - `InstanceBootstrap()` initializes plugins, LSP, file watcher, VCS, snapshots, truncation
  - `packages/cli/src/project/project.ts` - Project detection from directory (git worktree resolution)
  - `packages/cli/src/project/vcs.ts` - VCS integration

**Session Layer:**
- Purpose: Manage AI chat sessions, messages, parts, and the LLM interaction loop
- Location: `packages/cli/src/session/`
- Contains: Session CRUD, message/part storage, prompt construction, LLM streaming, compaction, retry, status
- Depends on: Database, Bus, Agent, Provider, Tool, Permission, Config
- Used by: CLI commands, SDK server
- Key files:
  - `packages/cli/src/session/index.ts` - Session namespace: CRUD operations, message/part management, cost calculation
  - `packages/cli/src/session/prompt.ts` - `SessionPrompt.prompt()` and `SessionPrompt.command()` - orchestrates the full LLM loop
  - `packages/cli/src/session/llm.ts` - `LLM.stream()` - wraps Vercel AI SDK `streamText()` with system prompts, tool config, provider transforms
  - `packages/cli/src/session/processor.ts` - `SessionProcessor` - processes LLM stream events (tool calls, text, reasoning, step boundaries)
  - `packages/cli/src/session/system.ts` - `SystemPrompt` - provider-specific system prompts (anthropic, gemini, codex, etc.)
  - `packages/cli/src/session/instruction.ts` - Instruction loading (AGENTS.md, config markdown)
  - `packages/cli/src/session/compaction.ts` - Context window compaction
  - `packages/cli/src/session/status.ts` - Session status tracking (idle/busy/retry)
  - `packages/cli/src/session/message-v2.ts` - Message and Part type definitions
  - `packages/cli/src/session/session.sql.ts` - Drizzle schema for sessions, messages, parts, todos, permissions

**Agent Layer:**
- Purpose: Define AI agent configurations (permissions, prompts, models)
- Location: `packages/cli/src/agent/`
- Contains: Built-in agents (build, plan, general, explore, compaction, title, summary), custom agent loading from config
- Depends on: Config, Permission, Provider, Plugin, Skill
- Used by: Session layer when starting LLM interactions
- Key files:
  - `packages/cli/src/agent/agent.ts` - Agent namespace: defines built-in agents, merges config overrides, agent generation via LLM
  - `packages/cli/src/agent/prompt/` - Agent-specific prompt templates (.txt files)

**Provider Layer:**
- Purpose: Abstract AI model providers (Anthropic, OpenAI, Google, etc.)
- Location: `packages/cli/src/provider/`
- Contains: Provider/model resolution, lazy-loaded SDK factories, custom loaders (Copilot, Bedrock), model transforms
- Depends on: Config, Auth, ModelsDev, Plugin
- Used by: Session/LLM layer
- Key files:
  - `packages/cli/src/provider/provider.ts` - Provider namespace: `BUNDLED_PROVIDERS` map (20+ providers), `getLanguage()`, `getModel()`, `defaultModel()`
  - `packages/cli/src/provider/transform.ts` - `ProviderTransform` - provider-specific options (max tokens, caching, structured output)
  - `packages/cli/src/provider/models.ts` - `ModelsDev` - fetches model catalog from models.dev
  - `packages/cli/src/provider/sdk/copilot/` - GitHub Copilot provider implementation

**Tool Layer:**
- Purpose: Define tools available to AI agents
- Location: `packages/cli/src/tool/`
- Contains: Built-in tools (bash, read, write, edit, glob, grep, task, skill, etc.), tool registry, truncation
- Depends on: Permission, Plugin, Config, Instance
- Used by: Session/Processor when executing tool calls
- Key files:
  - `packages/cli/src/tool/tool.ts` - `Tool.define()` factory, `Tool.Info` interface, `Tool.Context` type
  - `packages/cli/src/tool/registry.ts` - `ToolRegistry` - loads built-in tools, custom tools from `.aictrl/tool/`, plugin tools
  - `packages/cli/src/tool/bash.ts` - Shell command execution
  - `packages/cli/src/tool/edit.ts` - File editing (diff-based)
  - `packages/cli/src/tool/write.ts` - File writing
  - `packages/cli/src/tool/read.ts` - File reading
  - `packages/cli/src/tool/task.ts` - Subagent spawning
  - `packages/cli/src/tool/skill.ts` - Skill invocation
  - `packages/cli/src/tool/truncation.ts` - Output truncation for large tool results

**Event Bus Layer:**
- Purpose: Decoupled pub/sub communication between components
- Location: `packages/cli/src/bus/`
- Contains: Per-instance Bus, global EventEmitter (GlobalBus), typed event definitions
- Depends on: Instance (per-instance subscriptions)
- Used by: All layers publish/subscribe events
- Key files:
  - `packages/cli/src/bus/index.ts` - `Bus.publish()`, `Bus.subscribe()`, `Bus.subscribeAll()` - per-instance event bus
  - `packages/cli/src/bus/global.ts` - `GlobalBus` - cross-instance EventEmitter, bridges events to SDK/server
  - `packages/cli/src/bus/bus-event.ts` - `BusEvent.define()` - typed event definition factory

**Permission Layer:**
- Purpose: Control tool access per agent/session with pattern-based rules
- Location: `packages/cli/src/permission/`
- Contains: Ruleset merging, wildcard pattern matching, permission requests/replies
- Depends on: Database, Config, Bus
- Used by: Session/Processor before tool execution
- Key files:
  - `packages/cli/src/permission/next.ts` - `PermissionNext` - rule evaluation, `fromConfig()`, `merge()`, ask/reply flow

**Config Layer:**
- Purpose: Load and merge configuration from multiple sources
- Location: `packages/cli/src/config/`
- Contains: Config loading (global, project, managed, inline), markdown-based config, config paths
- Depends on: Instance, Auth, Global
- Used by: All layers
- Key files:
  - `packages/cli/src/config/config.ts` - `Config.get()` - merges configs from 6+ sources (well-known, global, custom, project, .aictrl dirs, inline, managed)
  - `packages/cli/src/config/markdown.ts` - Markdown frontmatter parser for agents/commands/skills
  - `packages/cli/src/config/paths.ts` - Config file path resolution

**Storage Layer:**
- Purpose: SQLite database and file-based storage
- Location: `packages/cli/src/storage/`
- Contains: Database client (bun:sqlite + Drizzle), migrations, JSON-to-SQLite migration, file storage
- Depends on: Global (data directory)
- Used by: Session, Project, Control, Permission
- Key files:
  - `packages/cli/src/storage/db.ts` - `Database.Client()` - lazy SQLite init with WAL mode, `Database.use()` for synchronized access
  - `packages/cli/src/storage/schema.ts` - Re-exports all SQL table definitions
  - `packages/cli/src/storage/schema.sql.ts` - Shared schema helpers (Timestamps)
  - `packages/cli/src/storage/json-migration.ts` - One-time migration from JSON files to SQLite
  - `packages/cli/src/storage/storage.ts` - File-based storage (legacy)

**Plugin Layer:**
- Purpose: Extensibility via external plugins and built-in auth plugins
- Location: `packages/cli/src/plugin/`
- Contains: Plugin loading (npm packages, local files), hook trigger system, built-in Codex/Copilot auth plugins
- Depends on: Config, Instance, BunProc
- Used by: Tool registry, Session, Provider
- Key files:
  - `packages/cli/src/plugin/index.ts` - `Plugin.init()`, `Plugin.trigger()`, `Plugin.list()` - load and invoke plugin hooks

**Skill Layer:**
- Purpose: Markdown-based reusable agent skills (SKILL.md files)
- Location: `packages/cli/src/skill/`
- Contains: Skill discovery from .aictrl/skills/, .claude/skills/, .agents/skills/, global skills
- Depends on: Config, Instance, ConfigMarkdown
- Used by: Agent layer (skill directories for permissions), Tool layer (SkillTool)
- Key files:
  - `packages/cli/src/skill/skill.ts` - `Skill.state()` discovers and loads SKILL.md files
  - `packages/cli/src/skill/discovery.ts` - Skill file discovery logic

**MCP Layer:**
- Purpose: Model Context Protocol client integration
- Location: `packages/cli/src/mcp/`
- Contains: MCP client connections (stdio, SSE, HTTP), tool bridging, OAuth support
- Depends on: Config, Instance
- Used by: Session layer (additional tools from MCP servers)
- Key files:
  - `packages/cli/src/mcp/index.ts` - `MCP` namespace - client lifecycle, tool listing, resource access

**ACP Layer:**
- Purpose: Agent Client Protocol server implementation
- Location: `packages/cli/src/acp/`
- Contains: ACP server, session management for ACP clients
- Depends on: SDK, Session
- Key files:
  - `packages/cli/src/acp/agent.ts` - ACP agent implementation
  - `packages/cli/src/acp/session.ts` - ACP session management
  - `packages/cli/src/acp/types.ts` - ACP type definitions

## Data Flow

**User Prompt to AI Response:**

1. User invokes `aictrl run "message"` -> `packages/cli/src/index.ts` parses args
2. `RunCommand` handler calls `bootstrap()` -> `Instance.provide()` creates project context
3. `InstanceBootstrap()` initializes plugins, LSP, file watcher, VCS, snapshots
4. `Session.createNext()` creates session in SQLite, publishes `Session.Event.Created`
5. `SessionPrompt.prompt()` builds user message, resolves agent + model
6. `LLM.stream()` constructs system prompts, loads tools from `ToolRegistry`, calls Vercel AI SDK `streamText()`
7. `SessionProcessor.process()` iterates the LLM stream:
   - Text parts -> stored as `TextPart` in DB, published via Bus
   - Tool calls -> permission check -> `tool.execute()` -> result stored as `ToolPart`
   - Step boundaries -> triggers next iteration if more tool calls needed
8. On completion, `SessionStatus.set(sessionID, { type: "idle" })` published
9. `RunCommand` event loop receives `session.status` idle event, exits

**Event Flow (Bus Architecture):**

1. Components publish typed events via `Bus.publish(EventDef, properties)`
2. Per-instance subscriptions receive matching events
3. `GlobalBus.emit("event", payload)` bridges to cross-instance listeners (SDK server, CLI event loop)
4. SDK server streams events to connected clients via SSE

**State Management:**
- Per-instance state via `Instance.state(() => initializer)` - memoized per project directory
- Global state via `Global.Path` (XDG directories)
- Database state via `Database.use(db => ...)` - synchronous SQLite access
- Context propagation via `AsyncLocalStorage` (Node.js `async_hooks`)

## Key Abstractions

**Instance (Project Context):**
- Purpose: Isolates state per project directory using AsyncLocalStorage
- Implementation: `packages/cli/src/project/instance.ts`
- Pattern: `Instance.provide({ directory, init, fn })` creates/reuses context, `Instance.state()` creates memoized per-instance singletons
- All state-bearing namespaces use `Instance.state()` for isolation

**Tool.Info:**
- Purpose: Defines a tool available to AI agents
- Implementation: `packages/cli/src/tool/tool.ts`
- Pattern: `Tool.define(id, async (initCtx) => ({ description, parameters: zodSchema, execute: async (args, ctx) => result }))`
- Tools receive `Tool.Context` with sessionID, messageID, abort signal, permission asking

**BusEvent.Definition:**
- Purpose: Typed event definitions for the pub/sub bus
- Implementation: `packages/cli/src/bus/bus-event.ts`
- Pattern: `BusEvent.define("event.type", z.object({ ... }))` returns typed definition for `Bus.publish()` / `Bus.subscribe()`

**fn (Validated Functions):**
- Purpose: Runtime-validated function inputs using Zod
- Implementation: `packages/cli/src/util/fn.ts`
- Pattern: `const myFn = fn(zodSchema, async (validatedInput) => result)` - used extensively in Session namespace

**Plugin Hooks:**
- Purpose: Named extension points for plugins to modify behavior
- Implementation: `packages/plugin/src/index.ts` (types), `packages/cli/src/plugin/index.ts` (trigger)
- Pattern: `Plugin.trigger("hook.name", inputContext, mutableOutput)` - plugins can modify the output object
- 15+ hook points: chat.message, chat.params, tool.execute.before/after, permission.ask, etc.

## Entry Points

**CLI Entry (`aictrl` command):**
- Location: `packages/cli/src/index.ts`
- Triggers: User runs `aictrl <command> [args]`
- Responsibilities: Yargs setup, logging init, database migration check, command dispatch

**Bootstrap:**
- Location: `packages/cli/src/cli/bootstrap.ts`
- Triggers: Called by commands that need a project context
- Responsibilities: Creates Instance context, runs InstanceBootstrap, executes callback

**SDK Entry:**
- Location: `packages/sdk/src/index.ts`
- Triggers: External code creates `createOpencode()` or `createAictrlClient()`
- Responsibilities: Spawns aictrl server process, provides typed client

**Plugin Entry:**
- Location: `packages/plugin/src/index.ts`
- Triggers: External plugins implement the Plugin interface
- Responsibilities: Defines plugin types, hook interfaces, tool definition types

## Error Handling

**Strategy:** Named errors with structured data, wrapped in Zod-validated types

**Patterns:**
- `NamedError.create("ErrorName", zodSchema)` creates typed error classes (`packages/util/src/error.ts`)
- `Session.BusyError` for concurrent session access
- `NotFoundError` for missing database records
- `PermissionNext` deny results in tool call failure message to LLM
- Top-level `process.on("unhandledRejection")` and `process.on("uncaughtException")` handlers in `packages/cli/src/index.ts`
- `FormatError()` converts errors to user-friendly messages
- LLM retries handled by `SessionRetry` with exponential backoff

## Cross-Cutting Concerns

**Logging:** `Log.create({ service: "name" })` creates namespaced loggers; logs written to `~/.local/share/aictrl/log/`; configurable via `--log-level` and `--print-logs` flags

**Validation:** Zod schemas for all data types; `fn()` wrapper for runtime input validation; tool parameter validation in `Tool.define()`

**Authentication:** File-based auth storage (`~/.local/share/aictrl/auth.json`); supports OAuth, API key, and well-known auth types; per-provider auth via `Auth.get(providerID)`

**Configuration Precedence (low to high):**
1. Remote `.well-known/aictrl` (org defaults)
2. Global config (`~/.config/aictrl/aictrl.json{,c}`)
3. Custom config (`AICTRL_CONFIG` env var)
4. Project config (`aictrl.json{,c}` in project root)
5. `.aictrl` directories (agents, commands, plugins, tools)
6. Inline config (`AICTRL_CONFIG_CONTENT` env var)
7. Managed config directory (enterprise, `/etc/aictrl`)

**Feature Flags:** `packages/cli/src/flag/flag.ts` - environment variable-based flags for experimental features (`AICTRL_EXPERIMENTAL_*`, `AICTRL_ENABLE_*`, `AICTRL_DISABLE_*`)

---

*Architecture analysis: 2026-03-08*
