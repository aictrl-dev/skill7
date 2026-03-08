# Coding Conventions

**Analysis Date:** 2026-03-08

## Naming Patterns

**Files:**
- Use `kebab-case` for filenames: `message-v2.ts`, `bus-event.ts`, `json-migration.ts`
- SQL schema files use `.sql.ts` suffix: `session.sql.ts`, `project.sql.ts`, `schema.sql.ts`, `control.sql.ts`
- Module entry points use `index.ts` inside directories: `packages/cli/src/bus/index.ts`, `packages/cli/src/session/index.ts`
- Text prompt files use `.txt` extension: `packages/cli/src/tool/bash.txt`, `packages/cli/src/agent/prompt/title.txt`
- Test files use `.test.ts` suffix: `bash.test.ts`, `session.test.ts`

**Exports / Modules:**
- Use `PascalCase` namespaces for all major modules. Every domain module is a TypeScript `namespace`:
  - `Session`, `Bus`, `Config`, `Provider`, `File`, `Agent`, `Tool`, `Database`, `Instance`, `MCP`, `Plugin`, `Pty`, `Vcs`, `Worktree`, `Shell`, `Global`, `Installation`, `Filesystem`, `Log`, `Ripgrep`, `Identifier`, `Control`, `Storage`
- Prefer `export namespace Foo {}` over `export class Foo {}` or scattered exports
- Namespace members are exported directly: `Session.create()`, `Bus.publish()`, `Config.get()`

**Functions:**
- Use `camelCase` for all functions: `fromRow()`, `toRow()`, `createDefaultTitle()`, `containsPath()`
- Factory functions prefixed with `create`: `createModel()`, `createAictrlClient()`, `createOpencodeServer()`
- Boolean-returning functions prefixed with `is`: `isDefaultTitle()`, `isOverflow()`, `isGpt5OrLater()`

**Variables:**
- Use `camelCase` for local variables: `eventReceived`, `receivedInfo`, `transportCalls`
- Use `UPPER_SNAKE_CASE` for constants: `MAX_METADATA_LENGTH`, `DEFAULT_TIMEOUT`, `OVERFLOW_PATTERNS`, `BUNDLED_PROVIDERS`
- Use `PascalCase` for Zod schemas that double as types: `Session.Info`, `File.Content`, `Agent.Info`

**Types:**
- Zod-inferred types share the name with their schema constant (dual export pattern):
  ```typescript
  export const Info = z.object({ ... })
  export type Info = z.infer<typeof Info>
  ```
- Interface names use `PascalCase`: `Context`, `Options`, `Metadata`
- Type aliases use `PascalCase`: `ParsedStreamError`, `ParsedAPICallError`, `SessionRow`

**Database Columns:**
- Use `snake_case` for all database column names: `project_id`, `time_created`, `share_url`, `summary_additions`
- Table names are `PascalCase` + `Table` suffix: `SessionTable`, `MessageTable`, `PartTable`, `ProjectTable`

## Code Style

**Formatting:**
- Prettier (version 3.6.2) configured in root `package.json`
- `semi: false` (no semicolons)
- `printWidth: 120`
- No `.prettierrc` file; config is inline in `package.json`

**Linting:**
- No ESLint or Biome configured. Prettier is the sole formatting tool.
- Pre-push hook runs `bun typecheck` (not pre-commit): `.husky/pre-push`

**TypeScript:**
- Strict mode via `@tsconfig/bun` base: `packages/cli/tsconfig.json`
- `noUncheckedIndexedAccess: false` (explicitly disabled in CLI package)
- JSX preserve mode with SolidJS: `"jsx": "preserve"`, `"jsxImportSource": "@opentui/solid"`
- Custom conditions: `"customConditions": ["browser"]`
- ESM modules throughout: `"type": "module"` in all package.json files

## Import Organization

**Order:**
1. External workspace packages: `@aictrl/util/error`, `@aictrl/sdk/v2`, `@aictrl/plugin`
2. External npm packages: `zod`, `remeda`, `ai`, `path`, `fs`
3. Path-aliased internal imports: `@/bus`, `@/util/log`, `@/project/instance`
4. Relative imports: `../util/log`, `../../src/tool/bash`

**Path Aliases:**
- `@/*` maps to `./src/*` (CLI package): `import { Bus } from "@/bus"`
- `@tui/*` maps to `./src/cli/cmd/tui/*` (TUI components)
- Both aliases configured in `packages/cli/tsconfig.json`

**Import Style:**
- Use `import z from "zod"` (default import for Zod)
- Use `import type` for type-only imports: `import type { LanguageModelV2 } from "@openrouter/ai-sdk-provider"`
- Imports from workspace packages use subpath exports: `@aictrl/util/error`, `@aictrl/util/slug`, `@aictrl/util/fn`
- Relative imports mix with alias imports in the same file (both `@/` and `../` are used)

## Error Handling

**Patterns:**
- Custom typed errors via `NamedError.create()` factory from `@aictrl/util/error`:
  ```typescript
  export const NotFoundError = NamedError.create(
    "NotFoundError",
    z.object({ message: z.string() }),
  )
  ```
- Error checking via `.isInstance()` static method: `Config.JsonError.isInstance(input)`
- `FormatError()` function in `packages/cli/src/cli/error.ts` formats known error types for user display
- Unknown errors handled in catch blocks with type narrowing: `if (e instanceof Error)`, `if (e instanceof NamedError)`
- API errors parsed via dedicated `ProviderError` namespace: `packages/cli/src/provider/error.ts`
- Provider overflow detection uses regex pattern matching against error messages
- Use `Error` with `cause` option for wrapping: `throw new Error("message", { cause: error })`

**Throw patterns:**
- Throw `Error` directly for tool validation failures
- Throw `NamedError` subclasses for domain-specific errors
- Catch blocks use `try {} catch {}` (no variable) for optional parsing: `try { JSON.parse(...) } catch {}`

## Logging

**Framework:** Custom `Log` namespace at `packages/cli/src/util/log.ts`

**Patterns:**
- Create scoped loggers with `Log.create({ service: "name" })`:
  ```typescript
  const log = Log.create({ service: "session" })
  log.info("publishing", { type: def.type })
  ```
- Default logger: `Log.Default.error("fatal", data)`
- Log levels: `DEBUG`, `INFO`, `WARN`, `ERROR`
- Logs write to file by default, stderr only in dev/print mode
- Initialize logging early: `Log.init({ print: false, dev: true, level: "DEBUG" })`
- Log cleanup keeps last 5 log files

## Comments

**When to Comment:**
- Use comments sparingly; code is the documentation
- Use `//` inline comments for non-obvious logic: `// Windows can keep SQLite WAL handles alive until GC finalizers run`
- Use `TODO:` for known improvements: `// TODO: we may wanna rename this tool so it works better on other shells`

**JSDoc/TSDoc:**
- Minimal JSDoc usage (~142 occurrences across 38 files, mostly in copilot SDK adapter code)
- JSDoc used primarily in plugin interface definitions (`packages/cli/src/plugin/index.ts`) for hook descriptions
- Source code in `packages/cli/src/` rarely uses JSDoc; prefer self-documenting code

## Function Design

**Size:** Functions are generally small (10-30 lines). Complex functions split into helper functions within the same namespace.

**Parameters:**
- Use object parameters for functions with 3+ arguments:
  ```typescript
  export async function provide<R>(input: { directory: string; init?: () => Promise<any>; fn: () => R })
  ```
- Zod schemas define tool parameters inline

**Return Values:**
- Functions return plain objects, not class instances
- Async functions return `Promise<T>` (never callbacks)
- Use `iife()` helper from `packages/cli/src/util/iife.ts` for inline async computation
- Use `lazy()` helper from `packages/cli/src/util/lazy.ts` for deferred initialization

## Module Design

**Exports:**
- Each major module is a namespace (`export namespace Session {}`)
- Namespace contains both runtime code and type definitions
- Zod schemas serve as both runtime validators and type sources (dual pattern)
- Bus events defined via `BusEvent.define()` with Zod schemas for type-safe event payloads

**Barrel Files:**
- No barrel files (`index.ts` re-exporting from siblings). Each `index.ts` is the module itself.
- SDK package uses standard re-exports: `export * from "./client.js"`

**State Management:**
- Module-scoped state via `Instance.state()`: creates per-project-instance state with automatic cleanup
- `AsyncLocalStorage`-based context via `Context.create()` from `packages/cli/src/util/context.ts`
- Global singletons for cross-instance state: `GlobalBus`, `Database`

## Zod Usage

**Schema Definition:**
- Always use `.meta({ ref: "Name" })` on top-level schemas for OpenAPI/JSON Schema generation:
  ```typescript
  export const Info = z.object({ ... }).meta({ ref: "Session" })
  ```
- Use `z.enum()` for string unions: `z.enum(["added", "deleted", "modified"])`
- Use `z.discriminatedUnion()` for tagged unions
- Identifier schemas use prefix validation: `Identifier.schema("session")`

**Validation:**
- Tool parameters validated via Zod `.parse()` in `Tool.define()` wrapper
- Config validated via Zod schemas with detailed error reporting

## Async Patterns

**Conventions:**
- Use `await using` for disposable resources (TC39 Explicit Resource Management):
  ```typescript
  await using tmp = await tmpdir({ git: true })
  ```
- Use `AbortSignal` for cancellation: `abort: AbortSignal.any([])`
- Use `Promise.allSettled()` for concurrent operations that may fail independently
- Use `Bun.sleep()` instead of `setTimeout` for simple delays in Bun context

---

*Convention analysis: 2026-03-08*
