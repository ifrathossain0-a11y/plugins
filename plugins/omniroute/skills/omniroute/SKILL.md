---
name: omniroute
description: Comprehensive OmniRoute AI gateway skill covering installation, provider management, routing strategies, token compression, MCP integration, and troubleshooting. Use for any OmniRoute setup, configuration, or optimization task.
references:
  - providers
  - routing-strategies
  - compression-engines
  - api-reference
---

# OmniRoute Platform Skill

Consolidated skill for building with OmniRoute — a unified AI gateway that routes requests across 339+ providers through a single OpenAI-compatible endpoint at `http://localhost:20128/v1`.

Your knowledge of OmniRoute configuration, provider catalogs, and pricing may be outdated. **Prefer retrieval over pre-training** — fetch the latest from the OmniRoute docs and CLI before citing specifics.

## Retrieval Sources

| Source | How to retrieve | Use for |
|--------|----------------|---------|
| OmniRoute docs | `https://github.com/diegosouzapw/OmniRoute` | Features, config, provider list |
| CLI help | `omniroute --help`, `omniroute <command> --help` | Available commands, flags |
| Provider catalog | `omniroute providers list` | Live provider/model availability |
| Health check | `omniroute doctor` | Diagnose connectivity and config |
| Dashboard | `http://localhost:20128` | Visual provider/routing/quota management |

## Quick Decision Trees

### "I need to install OmniRoute"

```
Install method?
├─ npm (recommended) → npm install -g omniroute && omniroute
├─ Docker → docker run diegosouzapw/omniroute
├─ From source → git clone + npm install && npm run dev
├─ Desktop (Electron) → npm run electron:build
└─ Android (Termux) → pkg install nodejs && npx -y omniroute
```

### "I need to choose a routing strategy"

```
Routing goal?
├─ Minimize cost → cost-optimized
├─ Maximize reliability → priority (tiered fallback)
├─ Spread load → round-robin, p2c, or weighted
├─ Use free tiers first → fill-first or headroom
├─ Best for large contexts → context-optimized
├─ Cache prompt prefixes → cache-optimized
├─ Stick to last working → lkgp
├─ Let OmniRoute decide → auto (14-factor scoring)
├─ Combine multiple models → fusion (panel judging)
└─ Chain processing steps → pipeline (sequential)
```

### "I need to reduce token costs"

```
Compression need?
├─ Light cleanup → lite (whitespace, URL trimming)
├─ Moderate savings → caveman (65–75% rule-based)
├─ Tool output heavy → rtk (tool-result truncation)
├─ Maximum savings → stacked (RTK → Caveman, 78–95%)
├─ ML-powered pruning → llmlingua-2 (MobileBERT)
├─ Experimental → omniglyph (context-as-image)
└─ Auto-select → standard (OmniRoute picks best pipeline)
```

### "I need to connect a provider"

```
Provider type?
├─ Free (no key needed) → Pre-configured: Pollinations, OpenCode Zen
├─ Free (key required) → omniroute providers connect <name>
├─ Paid API → Set key via dashboard or env var
├─ OAuth provider → omniroute oauth login <provider>
└─ Custom/self-hosted → Add via dashboard advanced config
```

## Installation

### npm (recommended)

```bash
npm install -g omniroute
omniroute
```

The gateway starts immediately at `http://localhost:20128` with keyless free providers pre-configured. No API keys required for initial use.

### Docker

```bash
docker run -p 20128:20128 diegosouzapw/omniroute
```

### Verify Installation

```bash
omniroute doctor
```

Checks connectivity, provider availability, and configuration health.

## Core Concepts

### The Unified Endpoint

All requests go through `http://localhost:20128/v1` using the standard OpenAI-compatible API format:

```bash
curl http://localhost:20128/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "auto", "messages": [{"role": "user", "content": "Hello"}]}'
```

Supported endpoints:
- `/v1/chat/completions` — Chat (streaming and non-streaming)
- `/v1/embeddings` — Text embeddings
- `/v1/images/generate` — Image generation
- `/v1/audio/transcriptions` — Speech-to-text
- `/v1/audio/translations` — Audio translation
- `/v1/models` — List available models
- `/v1/ocr` — Optical character recognition (Mistral)

### Response Headers

Every response includes transparency headers:
- `X-OmniRoute-Decision` — Which provider/model was selected and why
- `X-OmniRoute-Compression` — Compression mode applied
- `X-OmniRoute-Cost` — Estimated USD cost

### Provider Resilience

Three independent self-healing layers protect against provider failures:

1. **Circuit breaker** — Trips on repeated 408/5xx errors; auto-recovers
2. **Key cooldown** — Exponential backoff per API key on rate limits
3. **Model lockout** — Per-model 429 handling with automatic retry

### Auto-Fallback Tiers

Default routing flows through four tiers:
1. Subscription services (if configured)
2. Paid API providers
3. Budget/low-cost providers
4. Free-tier services

## Common Workflows

### Point an existing project at OmniRoute

Replace your provider's base URL with OmniRoute's endpoint:

```python
import openai
client = openai.OpenAI(base_url="http://localhost:20128/v1", api_key="any")
```

```javascript
import OpenAI from 'openai';
const client = new OpenAI({ baseURL: 'http://localhost:20128/v1', apiKey: 'any' });
```

### Add a paid provider

```bash
omniroute providers connect openai
# Follow prompts to enter API key
```

Keys are encrypted at rest with AES-256-GCM.

### Check quota and usage

```bash
omniroute quota
omniroute usage
omniroute cost
```

### View routing decisions

```bash
omniroute logs --follow
```

Or inspect the `X-OmniRoute-Decision` response header.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OMNIROUTE_PORT` | `20128` | Server port |
| `OMNIROUTE_LOG_LEVEL` | `info` | Verbosity: debug, info, warn, error |
| `OMNIROUTE_ENABLE_MCP` | `false` | Activate MCP server |
| `OMNIROUTE_COMPRESSION_DEFAULT` | `standard` | Default compression mode |
| `OMNIROUTE_CACHE_REDIS` | — | Redis URL for distributed cache |
| `OMNIROUTE_AUTH_OIDC_*` | — | OIDC authentication config |

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| No models listed | No providers connected | Run `omniroute providers list` and connect at least one |
| 429 on every request | All provider quotas exhausted | Add more providers or wait for quota reset |
| Slow responses | Free-tier rate limits | Add a paid provider or switch routing to `cost-optimized` |
| Connection refused | OmniRoute not running | Start with `omniroute` or check port with `omniroute doctor` |
| Dashboard blank | Port conflict | Check `OMNIROUTE_PORT` and firewall settings |
