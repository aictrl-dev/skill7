# NDJSON Events

When running `aictrl run --format json`, the CLI emits newline-delimited JSON (NDJSON) events to stdout. Each line is a self-contained JSON object with the following base shape:

```json
{
  "type": "<event_type>",
  "timestamp": 1741500000000,
  "sessionID": "session_01abc..."
}
```

## Lifecycle Events

### `session_start`

Emitted once when the session begins.

```json
{
  "type": "session_start",
  "model": "anthropic/claude-sonnet-4-20250514",
  "agent": "default"
}
```

### `session_complete`

Emitted once when the session ends (success or failure).

```json
{
  "type": "session_complete",
  "durationMs": 12345,
  "error": null
}
```

`error` is `null` on success, or a string describing the failure.

## Message Events

### `message_complete`

Emitted when an assistant message finishes (one per LLM turn).

```json
{
  "type": "message_complete",
  "modelID": "claude-sonnet-4-20250514",
  "providerID": "anthropic",
  "agent": "default",
  "cost": { "input": 0.003, "output": 0.012, "cache": { "read": 0, "write": 0 } },
  "tokens": { "input": 1024, "output": 512, "cache": { "read": 0, "write": 0 } },
  "finish": "tool-calls"
}
```

`finish` values: `"tool-calls"` (model wants to call tools), `"end_turn"` (model is done), `"max_tokens"` (output truncated).

### `text`

Emitted when a text block from the assistant is complete.

```json
{
  "type": "text",
  "part": {
    "type": "text",
    "text": "Here is the result...",
    "time": { "start": 1741500000, "end": 1741500001 }
  }
}
```

### `reasoning`

Emitted when extended thinking content is complete (requires `--thinking` flag).

```json
{
  "type": "reasoning",
  "part": {
    "type": "reasoning",
    "text": "Let me think about this...",
    "time": { "start": 1741500000, "end": 1741500001 }
  }
}
```

## Tool Events

### `tool_use`

Emitted when a tool call completes (success or error).

```json
{
  "type": "tool_use",
  "part": {
    "type": "tool",
    "tool": "bash",
    "state": {
      "status": "completed",
      "input": { "command": "ls" },
      "metadata": { "exit": 0, "output": "..." }
    }
  }
}
```

`state.status` is `"completed"` or `"error"`. On error, `state.error` contains the error message.

### `step_start` / `step_finish`

Emitted at step boundaries during multi-step tool use.

```json
{ "type": "step_start", "part": { "type": "step-start" } }
{ "type": "step_finish", "part": { "type": "step-finish" } }
```

## Skill Events

Skills are loaded progressively. The model first sees skill names and descriptions in the tool schema. Full skill content only enters context when the model explicitly invokes the skill tool.

### `skill_discovered`

Emitted per skill when the skill tool is initialized and skill descriptions are registered in the tool schema. This happens at the start of each LLM turn.

```json
{
  "type": "skill_discovered",
  "name": "commit",
  "description": "Create well-structured git commits",
  "location": "/home/user/.claude/skills/commit/SKILL.md"
}
```

### `skill_loaded`

Emitted when the model invokes the skill tool and the full SKILL.md content enters context.

```json
{
  "type": "skill_loaded",
  "name": "commit",
  "location": "/home/user/.claude/skills/commit/SKILL.md"
}
```

### `skill_resource_loaded`

Emitted when the model reads a file that belongs to a skill directory (e.g., a script, template, or reference file bundled with the skill).

```json
{
  "type": "skill_resource_loaded",
  "skillName": "commit",
  "filePath": "/home/user/.claude/skills/commit/templates/conventional.md"
}
```

## Subagent Events

### `subagent_start`

Emitted when a child session (subagent) is spawned.

```json
{
  "type": "subagent_start",
  "subagentSessionID": "session_01xyz...",
  "parentSessionID": "session_01abc...",
  "title": "Research codebase"
}
```

### `subagent_complete`

Emitted when a child session completes.

```json
{
  "type": "subagent_complete",
  "subagentSessionID": "session_01xyz...",
  "parentSessionID": "session_01abc..."
}
```

## Error Events

### `error`

Emitted when a session error occurs.

```json
{
  "type": "error",
  "error": {
    "name": "Unknown",
    "data": { "message": "Something went wrong" }
  },
  "sourceSessionID": "session_01abc..."
}
```

### `permission_rejected`

Emitted when a permission request is auto-rejected (headless mode has no user to approve).

```json
{
  "type": "permission_rejected",
  "permission": "bash",
  "patterns": ["rm -rf /"]
}
```
