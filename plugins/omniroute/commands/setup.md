---
description: Set up OmniRoute as your local AI gateway with providers and routing
argument-hint: [setup-preferences]
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit, WebFetch]
---

# Set Up OmniRoute

This command guides you through installing and configuring OmniRoute as a local AI gateway.

## Arguments

The user invoked this command with: $ARGUMENTS

## Instructions

When this command is invoked:

1. Read the skill file at `skills/omniroute/SKILL.md` for core guidance
2. Reference `skills/omniroute/references/providers.md` for provider setup
3. Reference `skills/omniroute/references/routing-strategies.md` for routing configuration
4. Reference `skills/omniroute/references/api-reference.md` for endpoint details

## Workflow

1. **Check if OmniRoute is installed**: Run `which omniroute` or `omniroute --version`
2. **Install if needed**: `npm install -g omniroute`
3. **Start the gateway**: `omniroute`
4. **Run health check**: `omniroute doctor`
5. **Connect providers** (if user has API keys): `omniroute providers connect <name>`
6. **Configure routing strategy** based on user's priorities (cost, reliability, quality)
7. **Set compression mode** if token savings are desired
8. **Verify with a test request** to `http://localhost:20128/v1/chat/completions`

## Example Usage

```
/omniroute:setup
/omniroute:setup with OpenAI and Anthropic as primary providers
/omniroute:setup optimized for cost with maximum compression
```
