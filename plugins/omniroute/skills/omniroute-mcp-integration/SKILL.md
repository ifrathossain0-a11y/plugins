---
name: omniroute-mcp-integration
description: Set up OmniRoute as an MCP server for Claude Desktop, Cursor, Codex, and other MCP clients. Use when integrating OmniRoute with AI coding tools or building MCP-based workflows.
references:
  - mcp-config-examples
---

# OmniRoute MCP Integration Skill

Configure OmniRoute as a Model Context Protocol (MCP) server to expose its 105 tools to AI coding assistants and agents.

## When to Use This Skill

- Connecting OmniRoute to Claude Desktop, Cursor, or Codex
- Setting up MCP-based workflows
- Configuring MCP transport (stdio, HTTP, SSE)
- Exposing OmniRoute tools to agents

## MCP Transport Modes

| Mode | Endpoint | Best for |
|------|----------|----------|
| stdio | `omniroute --mcp` | Local CLI tools (Claude Desktop, Cursor) |
| HTTP | `/api/mcp/stream` | Remote/web integrations |
| SSE | `/api/mcp/sse` | Streaming-capable clients |

## Quick Setup

### Claude Desktop

Add to your Claude Desktop MCP configuration (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "omniroute": {
      "command": "omniroute",
      "args": ["--mcp"]
    }
  }
}
```

### Cursor

Add to Cursor's MCP settings:

```json
{
  "mcpServers": {
    "omniroute": {
      "command": "omniroute",
      "args": ["--mcp"]
    }
  }
}
```

### HTTP Transport (Remote)

For remote or web-based MCP clients, enable the MCP server:

```bash
export OMNIROUTE_ENABLE_MCP=true
omniroute
```

Then connect to:
- HTTP streaming: `http://localhost:20128/api/mcp/stream`
- SSE: `http://localhost:20128/api/mcp/sse`

## Available MCP Tools

OmniRoute exposes 105 MCP tools across 31 scopes:

| Scope | Examples |
|-------|----------|
| Routing | Configure strategies, inspect decisions, manage combos |
| Providers | Connect, disconnect, list, health-check providers |
| Models | Search, list, filter available models |
| Compression | Set modes, inspect stats, tune engines |
| Cache | Clear, inspect, configure caching |
| Memory | Store and retrieve conversation context |
| Quota | View per-provider quota and usage |
| Cost | Estimate and track request costs |
| Audit | View request audit trail |

All tool calls are logged in OmniRoute's audit trail for transparency.

## Integration with Coding Tools

OmniRoute works with 33+ coding tools as a drop-in AI backend:

- **Claude Code** — Set `ANTHROPIC_BASE_URL=http://localhost:20128/v1`
- **Cursor** — Configure OmniRoute as custom API endpoint
- **GitHub Copilot** — Route through OmniRoute proxy
- **Cline** — Set base URL in extension settings
- **Continue** — Add as custom provider in config

## A2A (Agent-to-Agent) Protocol

Beyond MCP, OmniRoute supports A2A for agent delegation:

- Agents can delegate tasks to other agents through OmniRoute
- Supports autonomous multi-agent workflows
- Full audit trail for agent interactions

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| MCP tools not appearing | MCP not enabled | Set `OMNIROUTE_ENABLE_MCP=true` |
| Connection refused | OmniRoute not running | Start with `omniroute` first |
| stdio mode fails | Wrong binary path | Use full path: `which omniroute` |
| Tools timeout | Slow provider response | Check provider health with `omniroute doctor` |
