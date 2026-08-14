# MCP Configuration Examples

## Claude Desktop (macOS)

File: `~/Library/Application Support/Claude/claude_desktop_config.json`

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

## Claude Desktop (Windows)

File: `%APPDATA%\Claude\claude_desktop_config.json`

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

## Cursor

File: `.cursor/mcp.json` (project-level) or global settings

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

## HTTP Transport (Any Client)

For clients that support HTTP-based MCP:

```json
{
  "mcpServers": {
    "omniroute": {
      "type": "http",
      "url": "http://localhost:20128/api/mcp/stream"
    }
  }
}
```

## SSE Transport

```json
{
  "mcpServers": {
    "omniroute": {
      "type": "sse",
      "url": "http://localhost:20128/api/mcp/sse"
    }
  }
}
```

## Docker-Based MCP

When running OmniRoute in Docker, map the port and use HTTP transport:

```bash
docker run -p 20128:20128 -e OMNIROUTE_ENABLE_MCP=true diegosouzapw/omniroute
```

Then configure the client to connect via HTTP: `http://localhost:20128/api/mcp/stream`

## Environment Variables for MCP

```bash
# Enable MCP server
OMNIROUTE_ENABLE_MCP=true

# Custom port (applies to all transports)
OMNIROUTE_PORT=20128

# Log MCP tool calls
OMNIROUTE_LOG_LEVEL=debug
```
