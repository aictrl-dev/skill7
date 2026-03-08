# Codebase Structure

**Analysis Date:** 2026-03-08

## Directory Layout

```
opencode/
├── packages/
│   ├── cli/                  # Core CLI application (main package)
│   │   ├── bin/              # Binary wrapper scripts
│   │   ├── dist/             # Build output (compiled binaries)
│   │   ├── migration/        # Drizzle SQLite migrations
│   │   ├── script/           # Build scripts (build.ts)
│   │   ├── src/              # Source code
│   │   └── test/             # Test files
│   ├── sdk/                  # Public SDK for external consumers
│   │   └── src/              # SDK source (client, server, v2 types)
│   ├── plugin/               # Plugin type definitions and interfaces
│   │   └── src/              # Plugin types, tool definition types
│   ├── util/                 # Shared utility library
│   │   └── src/              # Error types, identifiers, slugs, etc.
│   ├── script/               # Infra/deployment scripts
│   ├── containers/           # Docker container definitions
│   └── identity/             # Brand assets (logos, marks)
├── .opencode/                # Project-level aictrl configuration
│   ├── agent/                # Custom agent definitions (.md)
│   ├── command/              # Custom command templates (.md)
│   ├── glossary/             # Translation glossaries
│   ├── skills/               # Skill definitions (SKILL.md)
│   ├── themes/               # UI themes (.json)
│   ├── tool/                 # Custom tool implementations (.ts)
│   └── opencode.jsonc        # Project config file
├── .github/                  # GitHub workflows and CI config
├── infra/                    # SST infrastructure definitions
├── sdks/                     # External SDK extensions (vscode)
├── specs/                    # Project specifications
├── nix/                      # Nix flake scripts
├── script/                   # Root-level utility scripts
├── patches/                  # Dependency patches
├── .planning/                # GSD planning documents
├── package.json              # Root workspace manifest
├── turbo.json                # Turborepo configuration
├── sst.config.ts             # SST infrastructure config
├── tsconfig.json             # Root TypeScript config
├── bunfig.toml               # Bun configuration
└── AGENTS.md                 # AI agent instructions for this repo
```

## Directory Purposes

**`packages/cli/src/` (Core Application):**
```
src/
├── index.ts              # CLI entry point (yargs setup)
├── headless.ts           # Headless execution mode
├── sql.d.ts              # SQL type declarations
├── acp/                  # Agent Client Protocol implementation
│   ├── agent.ts          # ACP agent handler
│   ├── session.ts        # ACP session management
│   └── types.ts          # ACP type definitions
├── agent/                # AI agent definitions
│   ├── agent.ts          # Built-in agents, config merge, generation
│   └── prompt/           # Agent-specific prompts (.txt files)
├── auth/                 # Authentication (OAuth, API key, well-known)
│   └── index.ts          # Auth CRUD, file-based storage
├── bun/                  # Bun-specific utilities (package install, proc)
├── bus/                  # Event bus system
│   ├── index.ts          # Per-instance Bus (publish/subscribe)
│   ├── global.ts         # GlobalBus (cross-instance EventEmitter)
│   └── bus-event.ts      # Typed event definition factory
├── cli/                  # CLI layer
│   ├── cmd/              # Yargs command handlers
│   │   ├── run.ts        # `aictrl run` - main command
│   │   ├── generate.ts   # `aictrl generate` - structured output
│   │   ├── auth.ts       # `aictrl auth` - provider auth
│   │   ├── agent.ts      # `aictrl agent` - agent management
│   │   ├── mcp.ts        # `aictrl mcp` - MCP server management
│   │   ├── acp.ts        # `aictrl acp` - ACP server
│   │   ├── pr.ts         # `aictrl pr` - PR operations
│   │   ├── github.ts     # `aictrl github` - GitHub integration
│   │   ├── models.ts     # `aictrl models` - list models
│   │   ├── export.ts     # `aictrl export` - export sessions
│   │   ├── import.ts     # `aictrl import` - import sessions
│   │   ├── session.ts    # `aictrl session` - session management
│   │   ├── db.ts         # `aictrl db` - database commands
│   │   ├── stats.ts      # `aictrl stats` - usage statistics
│   │   ├── upgrade.ts    # `aictrl upgrade` - self-update
│   │   ├── uninstall.ts  # `aictrl uninstall` - self-remove
│   │   ├── debug/        # Debug subcommands
│   │   └── cmd.ts        # Command helper wrapper
│   ├── bootstrap.ts      # Instance bootstrap wrapper
│   ├── ui.ts             # Terminal UI helpers
│   └── error.ts          # Error formatting
├── command/              # Slash commands (init, review, custom)
│   ├── index.ts          # Command registry and loading
│   └── template/         # Built-in command templates (.txt)
├── config/               # Configuration loading and merging
│   ├── config.ts         # Multi-source config merger
│   ├── markdown.ts       # Frontmatter markdown parser
│   └── paths.ts          # Config file path resolution
├── control/              # Control plane (enterprise auth)
│   └── index.ts          # OAuth token management
├── env/                  # Per-instance environment variables
│   └── index.ts          # Env.get/set/all (instance-isolated)
├── file/                 # File system operations
│   ├── index.ts          # File info, content, diffing, fuzzy search
│   ├── watcher.ts        # File system watcher
│   ├── ripgrep.ts        # Ripgrep integration
│   └── time.ts           # File modification tracking
├── flag/                 # Feature flags (env vars)
│   └── flag.ts           # All AICTRL_* flags
├── format/               # Code formatting
│   ├── index.ts          # Format initialization
│   └── formatter.ts      # Formatter implementation
├── global/               # Global paths (XDG directories)
│   └── index.ts          # Global.Path.data/cache/config/state
├── id/                   # ID generation (ULID-based)
│   └── id.ts             # Identifier.ascending/descending
├── ide/                  # IDE integration
│   └── index.ts          # IDE detection and commands
├── installation/         # Installation metadata
│   └── index.ts          # VERSION, isLocal(), channel
├── lsp/                  # LSP client integration
│   ├── index.ts          # LSP namespace, diagnostics, symbols
│   ├── client.ts         # LSP client connections
│   └── server.ts         # LSP server management
├── mcp/                  # Model Context Protocol
│   ├── index.ts          # MCP client connections, tool bridging
│   ├── oauth-provider.ts # MCP OAuth flow
│   ├── oauth-callback.ts # MCP OAuth callback
│   └── auth.ts           # MCP auth management
├── patch/                # Patch/diff utilities
├── permission/           # Permission system
│   └── next.ts           # Rule-based permission (allow/deny/ask)
├── plugin/               # Plugin loading and hooks
│   ├── index.ts          # Plugin.init(), trigger(), list()
│   ├── codex.ts          # Built-in Codex auth plugin
│   └── copilot.ts        # Built-in Copilot auth plugin
├── project/              # Project context and detection
│   ├── instance.ts       # Instance context (AsyncLocalStorage)
│   ├── bootstrap.ts      # InstanceBootstrap initialization
│   ├── project.ts        # Project detection (git worktree)
│   ├── project.sql.ts    # Project SQL schema
│   ├── state.ts          # Per-instance state management
│   └── vcs.ts            # VCS (git) integration
├── provider/             # AI model providers
│   ├── provider.ts       # Provider registry (20+ providers)
│   ├── transform.ts      # Provider-specific options
│   ├── models.ts         # models.dev catalog fetching
│   └── sdk/              # Custom provider SDKs
│       └── copilot/      # GitHub Copilot implementation
├── pty/                  # Pseudo-terminal support
├── question/             # Interactive question tool
├── scheduler/            # Periodic task scheduler
│   └── index.ts          # Scheduler.register() with intervals
├── session/              # Session management (core domain)
│   ├── index.ts          # Session CRUD, message/part ops
│   ├── prompt.ts         # Prompt orchestration (LLM loop)
│   ├── llm.ts            # LLM.stream() wrapper
│   ├── processor.ts      # Stream processor (tool calls, text, etc.)
│   ├── system.ts         # System prompts per provider
│   ├── instruction.ts    # Instruction loading (AGENTS.md)
│   ├── compaction.ts     # Context window compaction
│   ├── retry.ts          # LLM retry logic
│   ├── revert.ts         # Session revert (undo changes)
│   ├── status.ts         # Session status (idle/busy/retry)
│   ├── summary.ts        # Session summary generation
│   ├── message-v2.ts     # Message/Part type definitions
│   ├── session.sql.ts    # Drizzle SQL schema
│   ├── todo.ts           # Todo list management
│   └── prompt/           # Prompt templates (.txt files)
├── share/                # Session sharing
│   └── share-next.ts     # Share to opncd.ai
├── shell/                # Shell execution
│   └── shell.ts          # Shell command runner
├── skill/                # Skill system
│   ├── skill.ts          # Skill discovery and loading
│   └── discovery.ts      # Skill file discovery
├── snapshot/             # Git-based file snapshots
│   └── index.ts          # Snapshot tracking, cleanup
├── storage/              # Database and file storage
│   ├── db.ts             # SQLite client (bun:sqlite + Drizzle)
│   ├── schema.ts         # All table re-exports
│   ├── schema.sql.ts     # Shared schema helpers
│   ├── json-migration.ts # JSON -> SQLite migration
│   └── storage.ts        # File-based storage
├── tool/                 # AI tools
│   ├── tool.ts           # Tool.define() factory
│   ├── registry.ts       # ToolRegistry (built-in + custom + plugin)
│   ├── bash.ts           # Shell execution tool
│   ├── read.ts           # File reading tool
│   ├── write.ts          # File writing tool
│   ├── edit.ts           # File editing tool (diff-based)
│   ├── glob.ts           # File glob tool
│   ├── grep.ts           # Content search tool
│   ├── task.ts           # Subagent spawning tool
│   ├── skill.ts          # Skill invocation tool
│   ├── webfetch.ts       # Web fetching tool
│   ├── websearch.ts      # Web search (Exa) tool
│   ├── codesearch.ts     # Code search (Exa) tool
│   ├── todo.ts           # Todo read/write tools
│   ├── plan.ts           # Plan mode enter/exit tools
│   ├── question.ts       # Interactive question tool
│   ├── batch.ts          # Batch execution tool
│   ├── lsp.ts            # LSP tool (experimental)
│   ├── apply_patch.ts    # Apply patch tool (Codex compat)
│   ├── multiedit.ts      # Multi-file edit tool
│   ├── ls.ts             # Directory listing tool
│   ├── invalid.ts        # Invalid tool handler
│   ├── external-directory.ts # External directory permission
│   ├── truncation.ts     # Output truncation
│   └── *.txt             # Tool description templates
├── util/                 # Shared utilities
│   ├── context.ts        # AsyncLocalStorage wrapper
│   ├── filesystem.ts     # File system helpers
│   ├── fn.ts             # Zod-validated function wrapper
│   ├── git.ts            # Git command helpers
│   ├── glob.ts           # Glob pattern matching
│   ├── iife.ts           # Immediately invoked function expression
│   ├── lazy.ts           # Lazy initialization
│   ├── locale.ts         # Locale/i18n helpers
│   ├── lock.ts           # File locking
│   ├── log.ts            # Logging system
│   ├── process.ts        # Process utilities
│   ├── queue.ts          # Work queue
│   ├── rpc.ts            # RPC utilities
│   ├── signal.ts         # Signal handling
│   ├── timeout.ts        # Timeout utilities
│   ├── token.ts          # Token counting
│   ├── wildcard.ts       # Wildcard pattern matching
│   └── ...               # Other utility modules
└── worktree/             # Git worktree management
    └── index.ts          # Worktree CRUD operations
```

## Key File Locations

**Entry Points:**
- `packages/cli/src/index.ts`: CLI main entry (yargs command registration)
- `packages/cli/bin/aictrl`: Binary wrapper (tries compiled binary, falls back to `bun run src/index.ts`)
- `packages/sdk/src/index.ts`: SDK entry (createOpencode, createAictrlClient)

**Configuration:**
- `packages/cli/src/config/config.ts`: Multi-source config loading
- `packages/cli/src/flag/flag.ts`: All feature flags
- `packages/cli/src/global/index.ts`: XDG path resolution
- `.opencode/opencode.jsonc`: Project-level config

**Core Logic:**
- `packages/cli/src/session/prompt.ts`: Main LLM interaction loop
- `packages/cli/src/session/llm.ts`: LLM stream wrapper
- `packages/cli/src/session/processor.ts`: Stream event processor
- `packages/cli/src/agent/agent.ts`: Agent definitions and loading
- `packages/cli/src/provider/provider.ts`: Provider SDK registry
- `packages/cli/src/tool/registry.ts`: Tool registration and loading

**Database:**
- `packages/cli/src/storage/db.ts`: SQLite client setup
- `packages/cli/src/session/session.sql.ts`: Session/Message/Part/Todo/Permission tables
- `packages/cli/src/project/project.sql.ts`: Project table
- `packages/cli/migration/`: Drizzle migration files

**Testing:**
- `packages/cli/test/`: Test files

## Naming Conventions

**Files:**
- Lowercase with hyphens: `bus-event.ts`, `message-v2.ts`, `share-next.ts`
- SQL schemas: `*.sql.ts` suffix (e.g., `session.sql.ts`, `project.sql.ts`)
- Prompt templates: `.txt` files alongside their consumer (e.g., `bash.txt` next to `bash.ts`)
- Index re-exports: `index.ts` in each directory

**Directories:**
- Lowercase, single-word or hyphenated: `bus/`, `session/`, `cli/`, `file/`
- Feature-based grouping, not technical-layer grouping

**Code Patterns:**
- TypeScript namespaces: `export namespace Session {}`, `export namespace Config {}`
- Zod schemas: PascalCase matching the type (e.g., `Session.Info`, `Agent.Info`)
- Bus events: `Namespace.Event.EventName` (e.g., `Session.Event.Created`)
- Functions: camelCase (`createNext`, `fromRow`, `getUsage`)
- Constants: UPPER_SNAKE_CASE for env vars (`AICTRL_EXPERIMENTAL`), camelCase for code constants

## Where to Add New Code

**New CLI Command:**
- Create handler: `packages/cli/src/cli/cmd/<name>.ts`
- Pattern: Use `cmd()` helper from `./cmd.ts`, follow RunCommand as template
- Register: Add `.command(<Name>Command)` in `packages/cli/src/index.ts`

**New Tool:**
- Create tool: `packages/cli/src/tool/<name>.ts`
- Create description: `packages/cli/src/tool/<name>.txt`
- Pattern: Use `Tool.define(id, async (initCtx) => ({ description, parameters, execute }))`
- Register: Add to `ToolRegistry.all()` array in `packages/cli/src/tool/registry.ts`

**New Agent:**
- Built-in: Add to `result` record in `packages/cli/src/agent/agent.ts`
- Custom (project): Create `.opencode/agent/<name>.md` with frontmatter
- Custom (config): Add to `agent` section in `aictrl.jsonc`

**New Provider:**
- Add SDK to `BUNDLED_PROVIDERS` in `packages/cli/src/provider/provider.ts`
- Add optional peer dependency in `packages/cli/package.json`
- If custom loading needed, add to `CUSTOM_LOADERS`

**New Bus Event:**
- Define: `BusEvent.define("namespace.event", z.object({ ... }))` in the relevant namespace
- Publish: `Bus.publish(Namespace.Event.EventName, { ... })`
- Subscribe: `Bus.subscribe(Namespace.Event.EventName, handler)`

**New Database Table:**
- Create schema: `packages/cli/src/<feature>/<feature>.sql.ts`
- Re-export: Add to `packages/cli/src/storage/schema.ts`
- Create migration: `bun drizzle-kit generate` from `packages/cli/`

**New Plugin Hook:**
- Add type to `Hooks` interface in `packages/plugin/src/index.ts`
- Add trigger call in relevant code: `Plugin.trigger("hook.name", input, output)`

**New Skill:**
- Create: `.opencode/skills/<name>/SKILL.md` with frontmatter (name, description)
- Pattern: Markdown with YAML frontmatter

**New Custom Tool (project-level):**
- Create: `.opencode/tool/<name>.ts`
- Export a `ToolDefinition` (from `@aictrl/plugin/tool`)

**New Custom Command (project-level):**
- Create: `.opencode/command/<name>.md` with frontmatter
- Supports `$ARGUMENTS` and `$1`, `$2` parameter placeholders

**Utilities:**
- CLI-specific helpers: `packages/cli/src/util/<name>.ts`
- Cross-package helpers: `packages/util/src/<name>.ts`

## Special Directories

**`packages/cli/migration/`:**
- Purpose: Drizzle ORM SQLite migration files
- Generated: Yes, via `bun drizzle-kit generate`
- Committed: Yes
- Pattern: Timestamped directories containing `migration.sql`

**`packages/cli/dist/`:**
- Purpose: Compiled binary output
- Generated: Yes, via `bun run script/build.ts`
- Committed: No (gitignored)

**`packages/sdk/src/gen/`:**
- Purpose: Generated OpenAPI client code
- Generated: Yes, via `@hey-api/openapi-ts`
- Committed: Yes
- Contains: `types.gen.ts`, `client.gen.ts`, `sdk.gen.ts`

**`.opencode/`:**
- Purpose: Project-level aictrl configuration (agents, commands, tools, skills)
- Generated: No (user-created)
- Committed: Yes
- Scanned at runtime by Config, Agent, Command, Tool, and Skill loaders

**`infra/`:**
- Purpose: SST v3 infrastructure definitions (Cloudflare, Stripe, PlanetScale)
- Generated: No
- Committed: Yes

---

*Structure analysis: 2026-03-08*
