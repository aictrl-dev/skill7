# External Integrations

**Analysis Date:** 2026-03-08

## APIs & External Services

**AI/LLM Providers (via Vercel AI SDK):**

All providers are lazy-loaded via dynamic imports in `packages/cli/src/provider/provider.ts` (`BUNDLED_PROVIDERS` map). Model metadata is fetched from models.dev.

- Anthropic (Claude) - `@ai-sdk/anthropic`
  - Auth: `ANTHROPIC_API_KEY` env var or OAuth via plugin
  - Custom headers: `anthropic-beta` for Claude Code features, interleaved thinking, fine-grained tool streaming
- OpenAI - `@ai-sdk/openai`
  - Auth: `OPENAI_API_KEY`
  - Uses Responses API for newer models
- Google Gemini - `@ai-sdk/google`
  - Auth: `GOOGLE_API_KEY` / `GOOGLE_GENERATIVE_AI_API_KEY`
- Google Vertex AI - `@ai-sdk/google-vertex`
  - Auth: `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION` env vars, plus application default credentials
  - Custom URL template with `${GOOGLE_VERTEX_PROJECT}`, `${GOOGLE_VERTEX_LOCATION}` variables
- Amazon Bedrock - `@ai-sdk/amazon-bedrock`
  - Auth: `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or credentials provider chain
- Azure OpenAI - `@ai-sdk/azure`
  - Auth: `AZURE_API_KEY`, `AZURE_RESOURCE_NAME`
  - Supports both Responses and Chat completion APIs via `useCompletionUrls` option
- Azure Cognitive Services - Custom loader in `packages/cli/src/provider/provider.ts`
  - Auth: `AZURE_COGNITIVE_SERVICES_RESOURCE_NAME`
- xAI (Grok) - `@ai-sdk/xai`
  - Auth: `XAI_API_KEY`
- Groq - `@ai-sdk/groq`
  - Auth: `GROQ_API_KEY`
- Mistral - `@ai-sdk/mistral`
  - Auth: `MISTRAL_API_KEY`
- OpenRouter - `@openrouter/ai-sdk-provider` (patched)
  - Auth: `OPENROUTER_API_KEY`
- Cerebras - `@ai-sdk/cerebras`
  - Auth: `CEREBRAS_API_KEY`
- Cohere - `@ai-sdk/cohere`
  - Auth: `COHERE_API_KEY`
- DeepInfra - `@ai-sdk/deepinfra`
  - Auth: `DEEPINFRA_API_KEY`
- Together AI - `@ai-sdk/togetherai`
  - Auth: `TOGETHER_AI_API_KEY`
- Perplexity - `@ai-sdk/perplexity`
  - Auth: `PERPLEXITY_API_KEY`
- Vercel AI - `@ai-sdk/vercel`
  - Auth: via Vercel AI Gateway
- GitLab AI - `@gitlab/gitlab-ai-provider`
  - Auth: GitLab token
- Cloudflare AI Gateway - `ai-gateway-provider`
  - Auth: Cloudflare credentials
- Vercel AI Gateway - `@ai-sdk/gateway`
  - Auth: Vercel token

**GitHub Copilot:**
- Custom OpenAI-compatible provider SDK in `packages/cli/src/provider/sdk/copilot/`
- Full Chat Completions and Responses API implementations
- OAuth device code flow for authentication (`packages/cli/src/plugin/copilot.ts`)
  - Device code URL: `https://github.com/login/device/code`
  - Access token URL: `https://github.com/login/oauth/access_token`
  - Client ID: `Ov23li8tweQw6odWQebz`
- Enterprise Copilot support via custom base URL (`copilot-api.{enterprise-domain}`)

**OpenAI Codex:**
- Auth plugin in `packages/cli/src/plugin/codex.ts`

**models.dev:**
- Model metadata registry at `https://models.dev/api.json`
  - Fetched at runtime or from bundled snapshot (`packages/cli/src/provider/models-snapshot.ts`, auto-generated at build)
  - Cached locally at `~/.cache/aictrl/models.json`
  - Override URL: `AICTRL_MODELS_URL` env var
  - Override file: `AICTRL_MODELS_PATH` env var
  - Implementation: `packages/cli/src/provider/models.ts`

**Exa Web Search:**
- MCP-based web search via `https://mcp.exa.ai/mcp`
  - Implementation: `packages/cli/src/tool/websearch.ts`
  - Auth: `EXA_API_KEY` env var
  - Feature flag: `AICTRL_ENABLE_EXA` or `AICTRL_EXPERIMENTAL`

## Data Storage

**Local Database (CLI):**
- SQLite via Bun's native `bun:sqlite` driver
  - Location: `~/.local/share/aictrl/aictrl.db`
  - ORM: Drizzle ORM (`drizzle-orm/bun-sqlite`)
  - Client: `packages/cli/src/storage/db.ts`
  - Schema: `packages/cli/src/storage/schema.ts` (re-exports from domain modules)
  - Migrations: `packages/cli/migration/` (5 SQL migrations)
  - PRAGMA settings: WAL mode, NORMAL sync, 5s busy timeout, 64MB cache, foreign keys ON
  - Tables: `ControlAccountTable`, `SessionTable`, `MessageTable`, `PartTable`, `TodoTable`, `PermissionTable`, `SessionShareTable`, `ProjectTable`

**JSON File Storage (Legacy/Hybrid):**
- JSON files in `~/.local/share/aictrl/storage/`
  - Implementation: `packages/cli/src/storage/storage.ts`
  - Migration from JSON to SQLite: `packages/cli/src/storage/json-migration.ts`
  - Uses file-level read/write locking

**Auth Storage:**
- Local JSON file at `~/.local/share/aictrl/auth.json`
  - Implementation: `packages/cli/src/auth/index.ts`
  - Stored with `0o600` permissions
  - Supports: OAuth (access/refresh tokens with expiry), API keys, well-known auth

**Cloud Database (Console - not CLI):**
- PlanetScale (MySQL) - `infra/console.ts`
  - Organization: `anomalyco`, Database: `aictrl`
  - Per-stage branches (production branch or dev branches)
  - ORM: Drizzle Kit for schema management
  - Connection via PlanetScale password credentials

**Cloud File Storage (Console - not CLI):**
- Cloudflare R2 buckets
  - `Bucket` - API storage (`infra/app.ts`)
  - `ZenData`, `ZenDataNew` - Console data (`infra/console.ts`)
  - `EnterpriseStorage` - Enterprise/Teams data (`infra/enterprise.ts`)

**Caching:**
- Local filesystem cache at `~/.cache/aictrl/`
  - Model data cache
  - Version-tagged cache invalidation (current: version 21)
  - No external cache service

## Authentication & Identity

**CLI Provider Auth:**
- File-based auth store (`~/.local/share/aictrl/auth.json`)
- Three auth types: OAuth (refresh/access tokens), API keys, well-known endpoints
- Plugin-based auth hooks (`packages/cli/src/provider/auth.ts`, `packages/cli/src/plugin/index.ts`)
- Built-in auth plugins: GitHub Copilot OAuth, OpenAI Codex
- External plugins loaded from npm at runtime via `Config.plugin`

**Console Auth (not CLI):**
- OpenAuth (`@openauthjs/openauth`) on Cloudflare Workers
  - Implementation: `packages/console/function/src/auth.ts`
  - Cloudflare KV for auth session storage
  - GitHub OAuth: `GITHUB_CLIENT_ID_CONSOLE`, `GITHUB_CLIENT_SECRET_CONSOLE`
  - Google OAuth: `GOOGLE_CLIENT_ID`
  - Deployed at: `auth.{domain}`

**Enterprise/Control Auth:**
- OAuth refresh token flow in `packages/cli/src/control/index.ts`
- Refresh endpoint: `{url}/oauth/token`
- Stored in SQLite `ControlAccountTable`

## Monitoring & Observability

**Error Tracking:**
- No external error tracking service
- Structured logging to local files via `packages/cli/src/util/log.ts`
- `NamedError` pattern from `@aictrl/util/error` for typed errors

**Logs:**
- Local file-based logging at `~/.local/share/aictrl/log/`
- Structured JSON log entries with service tags
- Log levels: DEBUG, INFO, WARN, ERROR
- Console/cloud: Honeycomb via `HONEYCOMB_API_KEY` (log processor worker in `infra/console.ts`)

**NDJSON Output:**
- `--format json` flag produces NDJSON output for headless execution observability
- Primary interface for CI/automation consumers

## CI/CD & Deployment

**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`)
  - Trigger: push/PR to main
  - Steps: install (bun), build (turbo), typecheck, test
  - Runner: ubuntu-latest with Bun

**Automated Code Review:**
- GitHub Actions (`.github/workflows/code-review.yml`)
  - Trigger: PR to main/master, or manual workflow_dispatch
  - Uses `aictrl run` CLI with `zai-coding-plan/glm-5` model
  - Auth: `ZHIPUAI_API_KEY`
  - Smart SHA tracking to avoid duplicate reviews

**Publishing:**
- GitHub Actions (`.github/workflows/publish.yml`)
  - Trigger: GitHub Release published
  - npm OIDC trusted publishing (no tokens)
  - Publishes: `@aictrl/util`, `@aictrl/plugin`, `@aictrl/sdk`, `@aictrl/cli-linux-x64`, `@aictrl/cli`
  - CLI dependencies stripped from published package.json (all bundled in binary)

**Cloud Deployment:**
- SST Ion (`sst.config.ts`) - Cloudflare-native deployment
  - Home: Cloudflare
  - Providers: Stripe, PlanetScale
  - Stages: production (`aictrl.ai`), dev (`dev.aictrl.ai`), per-developer branches
  - Components deployed:
    - `Api` - Cloudflare Worker at `api.{domain}` (`infra/app.ts`)
    - `Web` - Astro docs site at `docs.{domain}` (`infra/app.ts`)
    - `WebApp` - Static SolidStart app at `app.{domain}` (`infra/app.ts`)
    - `Console` - SolidStart app at `{domain}` (`infra/console.ts`)
    - `AuthApi` - Auth worker at `auth.{domain}` (`infra/console.ts`)
    - `Teams` - Enterprise SolidStart app at `{shortDomain}` (`infra/enterprise.ts`)

## Protocols

**MCP (Model Context Protocol):**
- Client implementation: `packages/cli/src/mcp/index.ts`
- Transports: Streamable HTTP, SSE, Stdio
- OAuth support for MCP servers: `packages/cli/src/mcp/oauth-provider.ts`, `packages/cli/src/mcp/oauth-callback.ts`
- Configured via `aictrl.json` config file

**ACP (Agent Client Protocol):**
- Server implementation: `packages/cli/src/acp/agent.ts`, `packages/cli/src/acp/session.ts`
- NDJSON streaming over stdio
- Command: `aictrl acp`

**LSP (Language Server Protocol):**
- Client: `packages/cli/src/lsp/client.ts`
- Server management: `packages/cli/src/lsp/server.ts`
- JSON-RPC over stdio (`vscode-jsonrpc`)
- Used for code intelligence (symbols, diagnostics)

## GitHub Integration

**GitHub API:**
- `@octokit/rest` 22.0.0 - REST API client
- `@octokit/graphql` 9.0.2 - GraphQL API client
- Used in: `packages/cli/src/cli/cmd/github.ts`
- Handles: PR review, issue comments, code review workflows

**GitHub Actions:**
- `@actions/core` 1.11.1 - Core actions utilities
- `@actions/github` 6.0.1 - GitHub context access
- Used in: `packages/cli/src/cli/cmd/github.ts`
- Webhook event types from `@octokit/webhooks-types`

**GitHub App (Console):**
- App ID: `GITHUB_APP_ID` secret
- Private key: `GITHUB_APP_PRIVATE_KEY` secret
- Used by API worker (`infra/app.ts`)

## Third-Party Services (Console)

**Stripe (Billing):**
- SST Stripe provider in `sst.config.ts`
- Webhook endpoint at `https://{domain}/stripe/webhook`
- Products: "Aictrl Go" ($10/mo), "Aictrl Black" ($20/$100/$200/mo tiers)
- Events: checkout, charge, invoice, customer, subscription lifecycle
- Secrets: `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET`

**Discord:**
- Support bot integration
- Secrets: `DISCORD_SUPPORT_BOT_TOKEN`, `DISCORD_SUPPORT_CHANNEL_ID`

**Feishu (Lark):**
- App integration
- Secrets: `FEISHU_APP_ID`, `FEISHU_APP_SECRET`

**EmailOctopus:**
- Email marketing/newsletter
- Secret: `EMAILOCTOPUS_API_KEY`

**AWS SES:**
- Transactional email
- Secrets: `AWS_SES_ACCESS_KEY_ID`, `AWS_SES_SECRET_ACCESS_KEY`

## Environment Configuration

**Required env vars (CLI runtime - at least one provider key):**
- At minimum one AI provider API key (e.g., `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`)
- Or OAuth auth stored in `~/.local/share/aictrl/auth.json`

**Optional env vars (CLI):**
- `AICTRL_CONFIG` - Custom config file path
- `AICTRL_MODELS_URL` - Custom models.dev URL
- `EXA_API_KEY` - Exa web search
- `GITHUB_TOKEN` - GitHub API access
- Full feature flags in `packages/cli/src/flag/flag.ts`

**Required env vars (Console/Infrastructure):**
- `STRIPE_SECRET_KEY` - Stripe API
- `CLOUDFLARE_DEFAULT_ACCOUNT_ID` - Cloudflare account
- `CLOUDFLARE_API_TOKEN` - Cloudflare API
- Various secrets managed via SST Secret resources

**Secrets location:**
- CLI: `~/.local/share/aictrl/auth.json` (local, 0600 permissions)
- Infrastructure: SST Secrets (encrypted, per-stage)
- CI: GitHub Actions secrets

## Webhooks & Callbacks

**Incoming:**
- Stripe webhook at `https://{domain}/stripe/webhook` - billing events
- GitHub App webhooks at API worker - PR/issue events

**Outgoing:**
- Session sharing to `https://opncd.ai` (or enterprise URL) - `packages/cli/src/share/share-next.ts`
  - Syncs session, message, and part data
  - Can be disabled via `AICTRL_DISABLE_SHARE=true`
- MCP OAuth callback server (local) - `packages/cli/src/mcp/oauth-callback.ts`

---

*Integration audit: 2026-03-08*
