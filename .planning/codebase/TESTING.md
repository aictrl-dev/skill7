# Testing Patterns

**Analysis Date:** 2026-03-08

## Test Framework

**Runner:**
- Bun's built-in test runner (`bun:test`)
- Config: `packages/cli/bunfig.toml` (preload) + `packages/cli/package.json` (timeout)

**Assertion Library:**
- `bun:test` built-in `expect()` (Jest-compatible API)

**Run Commands:**
```bash
cd packages/cli && bun test --timeout 30000   # Run all CLI tests
cd packages/cli && bun test test/tool/bash.test.ts  # Run specific test file
# No watch mode or coverage commands configured
```

**Important:** Tests must NOT be run from the monorepo root. The root `bunfig.toml` intentionally sets `root = "./do-not-run-tests-from-root"` and the root `package.json` script exits with error. Always run tests from `packages/cli/`.

## Test File Organization

**Location:**
- Separate `test/` directory at `packages/cli/test/`
- Test files mirror the `src/` directory structure:
  - `src/tool/bash.ts` -> `test/tool/bash.test.ts`
  - `src/session/index.ts` -> `test/session/session.test.ts`
  - `src/util/lazy.ts` -> `test/util/lazy.test.ts`
  - `src/config/config.ts` -> `test/config/config.test.ts`

**Naming:**
- `{module-name}.test.ts` pattern
- Snapshot files in `__snapshots__/` subdirectory: `test/tool/__snapshots__/tool.test.ts.snap`

**Structure:**
```
packages/cli/test/
├── preload.ts              # Test environment setup (runs before all tests)
├── fixture/
│   └── fixture.ts          # Shared test helpers (tmpdir, etc.)
├── tool/
│   ├── bash.test.ts
│   ├── edit.test.ts
│   ├── read.test.ts
│   ├── grep.test.ts
│   └── __snapshots__/
├── session/
│   ├── session.test.ts
│   ├── compaction.test.ts
│   ├── retry.test.ts
│   └── ...
├── config/
│   ├── config.test.ts
│   └── ...
├── provider/
│   ├── provider.test.ts
│   ├── copilot/
│   │   └── copilot-chat-model.test.ts
│   └── ...
├── util/
│   ├── lazy.test.ts
│   ├── format.test.ts
│   ├── glob.test.ts
│   └── ...
└── ...
```

## Test Preload / Environment Setup

**Preload file:** `packages/cli/test/preload.ts`

This file is critical and runs before all tests. It:

1. Sets XDG env vars to isolate test data in a temp directory per process
2. Clears all provider API key env vars (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, etc.)
3. Sets `AICTRL_MODELS_PATH` to a test fixture JSON
4. Sets `AICTRL_TEST_HOME` to prevent reading real user configs
5. Sets `AICTRL_TEST_MANAGED_CONFIG_DIR` to isolate managed settings
6. Writes a cache version file to prevent migrations
7. Initializes `Log` with `print: false` and `dev: true`
8. Registers `afterAll` hook to close database and clean up temp directory

**Key env vars set by preload:**
- `XDG_DATA_HOME`, `XDG_CACHE_HOME`, `XDG_CONFIG_HOME`, `XDG_STATE_HOME`
- `AICTRL_MODELS_PATH`, `AICTRL_TEST_HOME`, `AICTRL_TEST_MANAGED_CONFIG_DIR`

## Test Structure

**Suite Organization:**
```typescript
import { describe, expect, test } from "bun:test"
import { BashTool } from "../../src/tool/bash"
import { Instance } from "../../src/project/instance"
import { tmpdir } from "../fixture/fixture"

describe("tool.bash", () => {
  test("basic", async () => {
    await Instance.provide({
      directory: projectRoot,
      fn: async () => {
        const bash = await BashTool.init()
        const result = await bash.execute({ command: "echo 'test'", description: "Echo test" }, ctx)
        expect(result.metadata.exit).toBe(0)
        expect(result.metadata.output).toContain("test")
      },
    })
  })
})
```

**Core Pattern: Instance.provide() wrapper:**

Almost every test wraps its logic in `Instance.provide()` which sets up the project context (directory, VCS, config). This is the most critical pattern to follow:

```typescript
await Instance.provide({
  directory: tmp.path,      // Project directory
  init: async () => { ... },  // Optional: run once on first provide
  fn: async () => {
    // Test code runs here with project context
  },
})
```

**Test Context Object:**

Tool tests create a shared `ctx` object matching `Tool.Context`:
```typescript
const ctx = {
  sessionID: "test",
  messageID: "",
  callID: "",
  agent: "build",
  abort: AbortSignal.any([]),
  messages: [],
  metadata: () => {},
  ask: async () => {},
}
```

## Temporary Directories

**Helper:** `tmpdir()` from `packages/cli/test/fixture/fixture.ts`

```typescript
// Basic temp directory
await using tmp = await tmpdir()

// With git initialization
await using tmp = await tmpdir({ git: true })

// With initial files
await using tmp = await tmpdir({
  init: async (dir) => {
    await Bun.write(path.join(dir, "aictrl.json"), JSON.stringify({ ... }))
  },
})

// With config
await using tmp = await tmpdir({
  config: { model: "test/model" },
})
```

**Key details:**
- Uses `await using` (TC39 Explicit Resource Management) for automatic cleanup
- Returns `{ path: string, extra: T }` where `path` is the real path of the temp dir
- `git: true` initializes a git repo with initial commit
- `config` option writes an `aictrl.json` config file
- `init` callback runs after directory creation for custom setup
- Paths are sanitized to strip null bytes (CI environment defense)

## Mocking

**Framework:** `bun:test` built-in `mock` and `mock.module()`

**Module Mocking Pattern:**
```typescript
import { mock, beforeEach } from "bun:test"

// Mock entire modules BEFORE importing the code under test
mock.module("@modelcontextprotocol/sdk/client/streamableHttp.js", () => ({
  StreamableHTTPClientTransport: class MockStreamableHTTP {
    constructor(url: URL, options?: any) {
      transportCalls.push({ type: "streamable", url: url.toString(), options: options ?? {} })
    }
    async start() {
      throw new Error("Mock transport cannot connect")
    }
  },
}))

// Import AFTER mocking
const { MCP } = await import("../../src/mcp/index")
```

**Function Mocking Pattern:**
```typescript
const createMockFetch = mock(async () => {
  const body = new ReadableStream({
    start(controller) {
      for (const chunk of chunks) {
        controller.enqueue(new TextEncoder().encode(chunk + "\n\n"))
      }
      controller.close()
    },
  })
  return new Response(body, { status: 200, headers: { "content-type": "text/event-stream" } })
})
```

**Inline Test Servers:**
```typescript
import { beforeAll, afterAll } from "bun:test"

let server: ReturnType<typeof Bun.serve>

beforeAll(async () => {
  server = Bun.serve({
    port: 0,  // Random port
    async fetch(req) {
      const url = new URL(req.url)
      // Handle routes...
      return new Response(Bun.file(fullPath))
    },
  })
})

afterAll(async () => {
  server?.stop()
})
```

**What to Mock:**
- External HTTP transports (MCP SDK transports)
- Network fetch calls (provider API responses)
- Module-level dependencies when testing in isolation

**What NOT to Mock:**
- `Instance.provide()` -- always use real project context
- Database/SQLite -- tests use real in-memory database (via preload temp dir)
- Filesystem operations -- tests use real temp directories
- The Bus event system -- tests subscribe to real events

## Fixtures and Factories

**Test Data:**
```typescript
// Factory function for model objects
function createModel(opts: {
  context: number
  output: number
  input?: number
  cost?: Provider.Model["cost"]
}): Provider.Model {
  return {
    id: "test-model",
    providerID: "test",
    name: "Test",
    limit: { context: opts.context, input: opts.input, output: opts.output },
    cost: opts.cost ?? { input: 0, output: 0, cache: { read: 0, write: 0 } },
    capabilities: { toolcall: true, attachment: false, ... },
    api: { npm: "@ai-sdk/anthropic" },
    options: {},
  } as Provider.Model
}
```

**Fixture data inlined in test files:**
- SSE response chunks defined as string arrays (see `packages/cli/test/provider/copilot/copilot-chat-model.test.ts`)
- Config JSON constructed inline in `tmpdir()` init callbacks
- No shared fixture factory module; each test file defines its own helpers

**Fixture files:**
- `packages/cli/test/fixture/fixture.ts` -- shared `tmpdir()` helper
- `packages/cli/test/fixture/skills/` -- skill discovery test fixtures
- `packages/cli/test/tool/fixtures/models-api.json` -- mock models API response

## Coverage

**Requirements:** None enforced. No coverage thresholds configured.

**View Coverage:**
```bash
cd packages/cli && bun test --coverage
```

## Test Types

**Unit Tests:**
- Pure function tests: `packages/cli/test/util/lazy.test.ts`, `packages/cli/test/util/format.test.ts`
- No `Instance.provide()` needed for pure logic tests
- Direct import and test of module functions

**Integration Tests (majority of tests):**
- Test modules with real database, filesystem, and project context
- Use `Instance.provide()` + `tmpdir()` pattern
- Example: `packages/cli/test/tool/bash.test.ts` runs real shell commands
- Example: `packages/cli/test/config/config.test.ts` reads real config files from temp directories

**Snapshot Tests:**
- Bun snapshot testing via `expect().toMatchSnapshot()`
- Snapshot file: `packages/cli/test/tool/__snapshots__/tool.test.ts.snap`
- Minimal usage (only 1 snapshot file found)

**E2E Tests:**
- Not present in the CLI package test suite
- Playwright is listed as a catalog dependency but used elsewhere (likely `sdks/vscode/`)

## Common Patterns

**Async Testing:**
```typescript
test("creates new file when oldString is empty", async () => {
  await using tmp = await tmpdir()
  const filepath = path.join(tmp.path, "newfile.txt")

  await Instance.provide({
    directory: tmp.path,
    fn: async () => {
      const edit = await EditTool.init()
      const result = await edit.execute(
        { filePath: filepath, oldString: "", newString: "new content" },
        ctx,
      )
      expect(result.metadata.diff).toContain("new content")
      const content = await fs.readFile(filepath, "utf-8")
      expect(content).toBe("new content")
    },
  })
})
```

**Error Testing:**
```typescript
test("throws error when file does not exist", async () => {
  await using tmp = await tmpdir()
  await Instance.provide({
    directory: tmp.path,
    fn: async () => {
      FileTime.read(ctx.sessionID, filepath)
      const edit = await EditTool.init()
      await expect(
        edit.execute({ filePath: filepath, oldString: "old", newString: "new" }, ctx),
      ).rejects.toThrow("not found")
    },
  })
})
```

**Event Testing (Bus events):**
```typescript
test("emits add event for new files", async () => {
  await using tmp = await tmpdir()
  await Instance.provide({
    directory: tmp.path,
    fn: async () => {
      const { Bus } = await import("../../src/bus")
      const { File } = await import("../../src/file")

      const events: string[] = []
      const unsubEdited = Bus.subscribe(File.Event.Edited, () => events.push("edited"))
      const unsubUpdated = Bus.subscribe(FileWatcher.Event.Updated, () => events.push("updated"))

      // ... trigger action ...

      expect(events).toContain("edited")
      unsubEdited()
      unsubUpdated()
    },
  })
})
```

**Permission Testing:**
```typescript
test("asks for bash permission with correct pattern", async () => {
  await using tmp = await tmpdir({ git: true })
  await Instance.provide({
    directory: tmp.path,
    fn: async () => {
      const bash = await BashTool.init()
      const requests: Array<Omit<PermissionNext.Request, "id" | "sessionID" | "tool">> = []
      const testCtx = {
        ...ctx,
        ask: async (req: Omit<PermissionNext.Request, "id" | "sessionID" | "tool">) => {
          requests.push(req)
        },
      }
      await bash.execute({ command: "echo hello", description: "Echo hello" }, testCtx)
      expect(requests.length).toBe(1)
      expect(requests[0].permission).toBe("bash")
    },
  })
})
```

## Test Naming Conventions

**Describe blocks:** Use dotted module path: `"tool.bash"`, `"tool.bash permissions"`, `"tool.bash truncation"`, `"session.started event"`, `"util.lazy"`, `"util.format"`

**Test names:** Descriptive sentence starting with verb or subject:
- `"basic"` (for simple happy path)
- `"creates new file when oldString is empty"`
- `"throws error when file does not exist"`
- `"asks for bash permission with correct pattern"`
- `"returns true when token count exceeds usable context"`
- `"does not ask for external_directory permission when rm inside project"`

## Test-specific Imports

Tests import directly from source using relative paths (not `@/` alias):
```typescript
import { BashTool } from "../../src/tool/bash"
import { Instance } from "../../src/project/instance"
import { tmpdir } from "../fixture/fixture"
```

The `@/` path alias works in test files that import from `@/provider/sdk/copilot/...` (see copilot test), but the majority of tests use `../../src/` relative paths.

---

*Testing analysis: 2026-03-08*
