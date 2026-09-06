# OmniRoute Provider Reference

## Provider Catalog Overview

OmniRoute supports 339+ providers with 1,200+ models, including 90+ free tiers.

## Top Free Providers (No Cost)

| Provider | Models | Limits |
|----------|--------|--------|
| OpenCode Zen | DeepSeek V4 | No token cap |
| Kilo Code | Various | Unlimited free |
| SiliconFlow | DeepSeek V3.2, R1 | Generous free tier |
| Z.AI GLM | GLM-4.7, GLM-4.5-Flash | Free forever |
| Qoder AI | Qwen3-Max | Unlimited |
| Baidu ERNIE | ERNIE models | Free forever |
| Pollinations | Various | No key required |

## Provider Management CLI

```bash
# List all available providers
omniroute providers list

# Connect a provider (interactive key entry)
omniroute providers connect <provider-name>

# OAuth-based login
omniroute oauth login <provider-name>

# Check provider health
omniroute doctor

# View per-provider quota
omniroute quota
```

## Adding Custom/Self-Hosted Providers

Use the dashboard at `http://localhost:20128` → Providers → Add Custom, or configure via the config file:

```json
{
  "providers": {
    "my-provider": {
      "type": "openai-compatible",
      "baseUrl": "https://my-inference-server/v1",
      "apiKey": "env:MY_PROVIDER_KEY",
      "models": ["my-model-7b"]
    }
  }
}
```

## Provider Resilience

Each provider connection includes:
- **Circuit breaker**: Trips after repeated 408/5xx errors, auto-recovers after cooldown
- **Key cooldown**: Exponential backoff per API key on 429 rate limits
- **Model lockout**: Per-model rate limit tracking with automatic retry scheduling

## Credential Storage

All API keys are encrypted at rest using AES-256-GCM. Keys can be supplied via:
- Interactive CLI prompt (`omniroute providers connect`)
- Environment variables
- Dashboard UI
- Config file (referencing env vars with `env:VAR_NAME`)
