---
name: omniroute-routing
description: Configure OmniRoute routing strategies and combos. Use when the user needs to select, tune, or troubleshoot request routing across AI providers, set up failover tiers, or optimize for cost, latency, or quality.
references:
  - strategy-selection
---

# OmniRoute Routing Skill

Select and configure routing strategies for distributing AI requests across OmniRoute's provider catalog.

## When to Use This Skill

- User wants to change how requests are distributed
- Optimizing for cost, latency, reliability, or quality
- Setting up failover tiers
- Creating or editing routing combos
- Debugging why a specific provider was chosen

## Strategy Selection Guide

### By Priority

| Goal | Strategy | Notes |
|------|----------|-------|
| Lowest cost | `cost-optimized` | Uses live catalog pricing |
| Highest reliability | `priority` | Ordered fallback through tiers |
| Best quality | `fusion` | Fan-out to panel, judge picks best |
| Lowest latency | `p2c` or `least-used` | Load-aware selection |
| Maximum free usage | `fill-first` or `headroom` | Drain free tiers first |
| Prompt cache hits | `cache-optimized` | Pins prefixes to same provider |
| Stability | `lkgp` | Sticks to last working provider |
| General purpose | `auto` | 14-factor scoring (default) |

### Combo Workflows

A "combo" in OmniRoute defines a named routing configuration:

```bash
# Create a cost-focused combo
omniroute combo create --name budget --strategy cost-optimized

# Create a reliability combo with specific providers
omniroute combo create --name reliable --strategy priority \
  --providers openai,anthropic,google

# List existing combos
omniroute combo list

# Delete a combo
omniroute combo delete --name budget
```

### Inspecting Routing Decisions

Every response includes an `X-OmniRoute-Decision` header showing:
- Which strategy was applied
- Which provider and model were selected
- Selection latency

```bash
# Follow routing decisions in real time
omniroute logs --follow --filter routing
```

## Auto-Fallback Configuration

The default `auto` strategy uses four descending tiers:

1. **Subscription** — Providers with active paid plans
2. **Paid API** — Providers with configured API keys
3. **Budget** — Low-cost providers
4. **Free** — Keyless or free-tier providers

To customize tier membership, use the dashboard or edit the combo config.

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Always picks same provider | `lkgp` or `priority` strategy | Switch to `round-robin` or `auto` |
| Free providers skipped | Higher-tier providers available | Use `fill-first` to drain free tiers |
| High latency | Slow provider selected | Use `p2c` or add latency weight to `auto` |
| Wrong model chosen | Model not in combo | Check `omniroute combo list` and provider catalog |
