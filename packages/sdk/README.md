# @aictrl/sdk

Official SDK for the Aictrl Headless AI Engine.

## Installation

```bash
npm install @aictrl/sdk
```

## Quick Start

### Initialize Client

```typescript
import { createAictrlClient } from "@aictrl/sdk"

const client = createAictrlClient({
  baseUrl: "http://localhost:4096", // Port used by aictrl server
})
```

### Create a Session

```typescript
const session = await client.session.create({
  title: "My Task",
})
```

### Run a Prompt

```typescript
const response = await client.session.prompt({
  sessionID: session.data.id,
  parts: [{ type: "text", text: "Summarize this codebase" }],
})
```

### Subscribe to Events

```typescript
const events = await client.event.subscribe()

for await (const event of events.stream) {
  if (event.type === "message.part.updated") {
    const part = event.properties.part
    if (part.type === "text") {
      process.stdout.write(part.text)
    }
  }
}
```

## Features

- **Typed API:** Full TypeScript support for sessions, tools, and events.
- **Event Streaming:** Real-time feedback via an event stream.
- **MCP Integration:** Manage MCP servers programmatically.
- **V2 API:** Includes the new V2 API for more granular control.

## Documentation

For more information, visit [aictrl.ai](https://aictrl.ai).
