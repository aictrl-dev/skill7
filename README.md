# Aictrl Engine

The Lightweight Headless Runtime for AI Agent Skills.

Aictrl is a 100% headless, server-side execution harness designed for autonomous agentic workflows. It provides a secure, modular environment to run, measure, and scale agent skills without the bloat of a desktop or terminal UI.

## Key Features

- **Headless First:** Built specifically for server-side automation, Cloud Run, and CI/CD pipelines.
- **Skill-Native:** Native support for the `SKILL.md` format for modular procedural knowledge.
- **Agent Teams:** Robust support for subagent delegation and parallel execution.
- **Deep Telemetry:** Instrumented with granular hooks for measuring skill usage and subagent lifecycles.
- **Vendor Agnostic:** Compatible with Anthropic, OpenAI, Gemini, and local models via Ollama.
- **MCP Support:** Seamless integration with Model Context Protocol servers.

## Installation

```bash
npm i -g @aictrl/cli
```

## Quick Start

Run a task headlessly:

```bash
s7 run "analyze the security of this repository"
```

## Attribution

Aictrl is based on the [Aictrl](https://aictrl.ai) project and is licensed under the MIT License.

---
© 2026 [aictrl.ai](https://aictrl.ai)
