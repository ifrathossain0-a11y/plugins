# OmniRoute API Reference

## Base URL

```
http://localhost:20128/v1
```

Default port is `20128`, configurable via `OMNIROUTE_PORT`.

## Endpoints

### Chat Completions

```
POST /v1/chat/completions
```

OpenAI-compatible chat completion endpoint. Supports streaming (`stream: true`).

```bash
curl http://localhost:20128/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "auto",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": false
  }'
```

### Embeddings

```
POST /v1/embeddings
```

### Image Generation

```
POST /v1/images/generate
```

### Audio Transcription

```
POST /v1/audio/transcriptions
```

### Audio Translation

```
POST /v1/audio/translations
```

### OCR (Mistral)

```
POST /v1/ocr
```

### Models List

```
GET /v1/models
```

Returns all available models grouped by provider.

### Auto-Combo Candidates

```
GET /v1/auto-combo/{channel}/candidates
```

Read-only view of the live candidate pool for a routing channel.

## Response Headers

| Header | Description |
|--------|-------------|
| `X-OmniRoute-Decision` | Routing strategy used, selected provider, latency |
| `X-OmniRoute-Compression` | Compression mode and engine pipeline applied |
| `X-OmniRoute-Cost` | Estimated USD cost for the request |

## Authentication

The API key field accepts any value when using OmniRoute as a local proxy — authentication is handled at the provider level, not at the gateway. For remote/shared deployments, configure OIDC via `OMNIROUTE_AUTH_OIDC_*` environment variables.

## CLI Commands

| Command | Description |
|---------|-------------|
| `omniroute` | Start the gateway server |
| `omniroute chat` | Interactive TUI chat |
| `omniroute setup` | Guided first-run configuration |
| `omniroute doctor` | Diagnose connectivity and config |
| `omniroute providers list` | List available providers |
| `omniroute providers connect <name>` | Connect a provider |
| `omniroute models list` | List available models |
| `omniroute models search <query>` | Search for models |
| `omniroute combo list` | List routing combos |
| `omniroute combo create` | Create a routing combo |
| `omniroute quota` | View provider quotas |
| `omniroute usage` | View usage statistics |
| `omniroute cost` | View cost breakdown |
| `omniroute logs` | View request logs |
| `omniroute cache clear` | Clear the cache |
| `omniroute health` | Health check |
| `omniroute audit` | View audit log |
