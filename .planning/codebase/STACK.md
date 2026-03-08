# Technology Stack

**Analysis Date:** 2026-03-08

## Languages

**Primary:**
- TypeScript 5.8.2 - All application code across every package
- SQL (SQLite dialect) - Database migrations in `packages/cli/migration/`

**Secondary:**
- Shell/Bash - CI workflows in `.github/workflows/`, container scripts in `packages/containers/`
- WASM - tree-sitter grammars loaded at runtime for bash parsing (`packages/cli/src/tool/bash.ts`)

## Runtime

**Environment:**
- Bun 1.3.10 - Primary runtime for CLI execution, testing, and builds
- Node.js 22 - Used in CI for npm publishing (OIDC trusted publishing requires npm >= 11.5.1)

**Package Manager:**
- Bun (workspace protocol) - Monorepo dependency management
- Lockfile: `bun.lockb` (binary lockfile, present)

**Configuration:**
- `bunfig.toml` - Sets `exact = true` for installs, blocks root-level test runs
- `package.json` field `"packageManager": "bun@1.3.10"`

## Frameworks

**Core:**
- Vercel AI SDK (`ai` 5.0.124) - Unified LLM provider interface, streaming, tool calling
- Yargs 18.0.0 - CLI command framework (`packages/cli/src/index.ts`)
- SolidJS 1.9.10 - TUI rendering via `@opentui/solid` and `@opentui/core` (terminal UI framework)
- Drizzle ORM 1.0.0-beta.12 - Local SQLite database for sessions, messages, projects

**Testing:**
- Bun's built-in test runner (`bun test --timeout 30000`)

**Build/Dev:**
- Turborepo 2.5.6 - Monorepo task orchestration (`turbo.json`)
- SST 3.18.10 (Ion) - Infrastructure-as-code for Cloudflare deployments
- Custom Bun build script (`packages/cli/script/build.ts`) - Compiles platform-specific binaries

## Key Dependencies

**Critical (AI/LLM):**
- `ai` 5.0.124 - Core AI SDK for `streamText`, `generateObject`, tool definitions
- `@ai-sdk/anthropic` 2.0.65 - Anthropic Claude provider
- `@ai-sdk/openai` 2.0.89 - OpenAI provider
- `@ai-sdk/google` 2.0.54 - Google Gemini provider
- `@ai-sdk/google-vertex` 3.0.106 - Google Vertex AI provider
- `@ai-sdk/amazon-bedrock` 3.0.82 - AWS Bedrock provider
- `@ai-sdk/azure` 2.0.91 - Azure OpenAI provider
- `@ai-sdk/xai` 2.0.51 - xAI/Grok provider
- `@ai-sdk/groq` 2.0.34 - Groq provider
- `@ai-sdk/mistral` 2.0.27 - Mistral provider
- `@openrouter/ai-sdk-provider` 1.5.4 - OpenRouter aggregator (patched)
- `@ai-sdk/gateway` 2.0.30 - Vercel AI Gateway
- `@gitlab/gitlab-ai-provider` 3.6.0 - GitLab AI provider
- `ai-gateway-provider` 2.3.1 - Cloudflare AI Gateway
- `@ai-sdk/cerebras` 1.0.36 - Cerebras provider
- `@ai-sdk/cohere` 2.0.22 - Cohere provider
- `@ai-sdk/deepinfra` 1.0.36 - DeepInfra provider
- `@ai-sdk/togetherai` 1.0.34 - Together AI provider
- `@ai-sdk/perplexity` 2.0.23 - Perplexity provider
- `@ai-sdk/vercel` 1.0.33 - Vercel provider

All AI provider SDKs are **optional peerDependencies**, lazy-loaded via dynamic imports in `packages/cli/src/provider/provider.ts` (see `BUNDLED_PROVIDERS` map). They are bundled into compiled binaries at build time.

**Critical (Protocols):**
- `@modelcontextprotocol/sdk` 1.25.2 - MCP client for tool server connectivity
- `@agentclientprotocol/sdk` 0.14.1 - ACP server for agent-to-agent communication
- `vscode-jsonrpc` 8.2.1 - JSON-RPC protocol for LSP communication

**Infrastructure:**
- `drizzle-orm` 1.0.0-beta.12 + `bun:sqlite` - Local SQLite database
- `zod` 4.1.8 - Runtime schema validation everywhere
- `solid-js` 1.9.10 - Terminal UI reactivity
- `@opentui/core` + `@opentui/solid` 0.1.81 - Terminal rendering framework
- `remeda` 2.26.0 - Functional utility library (used instead of lodash)
- `web-tree-sitter` 0.25.10 + `tree-sitter-bash` 0.25.0 - Bash command parsing for security analysis
- `xdg-basedir` 5.1.0 - XDG directory resolution for data/config/cache paths
- `ulid` 3.0.1 - ID generation
- `@octokit/rest` 22.0.0 + `@octokit/graphql` 9.0.2 - GitHub API integration
- `@actions/core` 1.11.1 + `@actions/github` 6.0.1 - GitHub Actions integration
- `turndown` 7.2.0 - HTML-to-markdown conversion (web fetch tool)
- `fuzzysort` 3.1.0 - Fuzzy search for model/command matching
- `jsonc-parser` 3.3.1 - JSONC config file parsing
- `gray-matter` 4.0.3 - Markdown frontmatter parsing (skills/agents)

**Workspace Internal:**
- `@aictrl/cli` - Main CLI package (compiled binary)
- `@aictrl/sdk` 0.1.2 - Client/server SDK with OpenAPI-generated types
- `@aictrl/plugin` 1.2.16 - Plugin interface definitions
- `@aictrl/util` 1.2.16 - Shared utilities (error types, etc.)
- `@aictrl/script` 0.1.1 - Build scripting utilities

## Monorepo Structure

**Workspace catalog** (`package.json` `"catalog"` field) pins shared dependency versions across all packages. Dependencies reference `"catalog:"` instead of version numbers.

**Patched dependencies:**
- `@standard-community/standard-openapi@0.2.9` - Patched via `patches/` directory
- `@openrouter/ai-sdk-provider@1.5.4` - Patched via `patches/` directory

**Trusted dependencies** (allowed to run install scripts):
- `esbuild`, `protobufjs`, `tree-sitter`, `tree-sitter-bash`, `web-tree-sitter`

## Configuration

**Environment Variables (CLI runtime):**
- Provider API keys: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `AWS_REGION`, etc. (per provider)
- `AICTRL_CONFIG` - Custom config file path
- `AICTRL_CONFIG_DIR` - Custom config directory
- `AICTRL_CONFIG_CONTENT` - Inline JSON config
- `AICTRL_PERMISSION` - Permission mode override
- `AICTRL_MODELS_URL` - Override models.dev URL (default: `https://models.dev`)
- `AICTRL_MODELS_PATH` - Local models JSON path override
- `AICTRL_DISABLE_SHARE` - Disable session sharing
- `AICTRL_DISABLE_AUTOUPDATE` - Disable auto-update checks
- `AICTRL_DISABLE_DEFAULT_PLUGINS` - Skip default plugins
- `AICTRL_DISABLE_PROJECT_CONFIG` - Skip project-level config
- `AICTRL_DISABLE_MODELS_FETCH` - Skip fetching models from models.dev
- `AICTRL_HEADLESS` - Headless execution mode
- `AICTRL_ENABLE_EXA` - Enable Exa web search tool
- `AICTRL_EXPERIMENTAL` - Enable all experimental features
- Full list in `packages/cli/src/flag/flag.ts`

**Build:**
- `turbo.json` - Turborepo build orchestration with `build`, `typecheck`, `test` tasks
- `sst.config.ts` - SST Ion config (Cloudflare home, Stripe + PlanetScale providers)
- `AICTRL_VERSION` - Injected at build time from release tag, declared as global (`AICTRL_VERSION`)
- `AICTRL_BUILD_SINGLE` - Build single platform binary only (for CI)

**TypeScript:**
- Base: `@tsconfig/bun` extending to Bun-optimized settings
- CLI-specific: `packages/cli/tsconfig.json` adds JSX support (`preserve` mode, `@opentui/solid`), path aliases (`@/*` -> `./src/*`, `@tui/*` -> `./src/cli/cmd/tui/*`)

**XDG Data Paths:**
- Data: `~/.local/share/aictrl/` (database, auth, logs, bin)
- Cache: `~/.cache/aictrl/` (models cache)
- Config: `~/.config/aictrl/` (global config, AGENTS.md)
- State: `~/.local/state/aictrl/`

## Platform Requirements

**Development:**
- Bun >= 1.3.10
- Git (for VCS operations and project identification)
- Optional: LSP servers for code intelligence

**Production (CLI binary):**
- Compiled Bun binary (platform-specific: linux-x64, linux-arm64, darwin-x64, darwin-arm64, win32-x64)
- No runtime dependencies needed - all deps bundled at build time
- SQLite database created automatically at `~/.local/share/aictrl/aictrl.db`
- Binary published as `@aictrl/cli` with platform-specific optional deps (`@aictrl/cli-linux-x64`, etc.)

**Infrastructure (Console/Enterprise):**
- Cloudflare Workers (API, Auth, Console)
- Cloudflare R2 (file storage)
- Cloudflare KV (auth storage, gateway)
- Cloudflare Durable Objects (SyncServer)
- PlanetScale (MySQL - console database)
- Stripe (billing)

---

*Stack analysis: 2026-03-08*
