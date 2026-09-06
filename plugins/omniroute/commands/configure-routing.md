---
description: Configure OmniRoute routing strategy and provider fallback order
argument-hint: [routing-goal]
allowed-tools: [Read, Glob, Grep, Bash, Write, Edit, WebFetch]
---

# Configure OmniRoute Routing

This command helps you select and configure the optimal routing strategy for your workload.

## Arguments

The user invoked this command with: $ARGUMENTS

## Instructions

When this command is invoked:

1. Read the skill file at `skills/omniroute-routing/SKILL.md` for routing guidance
2. Reference `skills/omniroute-routing/references/strategy-selection.md` for strategy details
3. Reference `skills/omniroute/references/providers.md` for provider context

## Workflow

1. **Understand the goal**: Ask what the user optimizes for (cost, quality, reliability, latency)
2. **Recommend a strategy** from the 19 available options
3. **Create or edit a combo**: `omniroute combo create --name <name> --strategy <strategy>`
4. **Configure providers** for the combo if specific providers are desired
5. **Test the configuration** with a sample request
6. **Verify routing decisions** via `X-OmniRoute-Decision` header

## Example Usage

```
/omniroute:configure-routing minimize costs
/omniroute:configure-routing maximum reliability with OpenAI fallback
/omniroute:configure-routing fusion mode for quality-critical tasks
```
