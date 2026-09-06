# OmniRoute Routing Strategies

OmniRoute provides 19 routing strategies for intelligent request distribution.

## Strategy Reference

### Basic Strategies

| Strategy | Description | Best for |
|----------|-------------|----------|
| `priority` | Ordered list — drain each target before the next | Preferred-provider setups |
| `fill-first` | Maximize each target's quota before switching | Free-tier maximization |
| `round-robin` | Cycle through targets sequentially | Even distribution |
| `random` | Uniform random (deduplicated) | Simple load spreading |
| `strict-random` | Random without deduplication | Stateless randomization |

### Load-Aware Strategies

| Strategy | Description | Best for |
|----------|-------------|----------|
| `weighted` | Random selection weighted by per-target metrics | Custom traffic shaping |
| `p2c` | Power-of-two-choices load balancing | Low-latency selection |
| `least-used` | Select target with lowest current load | Balanced utilization |

### Cost and Quota Strategies

| Strategy | Description | Best for |
|----------|-------------|----------|
| `cost-optimized` | Minimize $/request from live catalog pricing | Budget-sensitive workloads |
| `headroom` | Choose target with most remaining quota | Quota preservation |
| `reset-window` | Prefer targets resetting quota soonest | Time-sensitive quota use |
| `reset-aware` | Rank by quota reset timing | Quota planning |

### Context-Aware Strategies

| Strategy | Description | Best for |
|----------|-------------|----------|
| `context-relay` | Hand off context across targets | Multi-turn conversations |
| `context-optimized` | Best fit for current context size | Large-context requests |
| `cache-optimized` | Pin reusable prompt prefixes to same account | Prompt caching (Anthropic, OpenAI) |

### Sticky and Adaptive Strategies

| Strategy | Description | Best for |
|----------|-------------|----------|
| `lkgp` | Sticky to last known good provider | Stability-first workloads |
| `auto` | 14-factor live scoring system | General-purpose (recommended default) |

### Advanced Multi-Model Strategies

| Strategy | Description | Best for |
|----------|-------------|----------|
| `fusion` | Fan out to model panel; judge synthesizes answer | Quality-critical tasks |
| `pipeline` | Chain steps; output feeds next step | Multi-stage processing |

## Configuring Routing

### Via CLI

```bash
# Set default strategy
omniroute combo create --strategy cost-optimized

# List active combos
omniroute combo list
```

### Via API

Include routing preference in request headers or use the dashboard.

### Via Dashboard

Navigate to `http://localhost:20128` → Routing → Strategy selector.

## Auto-Fallback Tiers

The default `auto` strategy scores providers across 14 factors and falls back through four tiers:

1. **Subscription** — Services with active subscriptions
2. **Paid API** — Providers with configured API keys
3. **Budget** — Low-cost or high-quota providers
4. **Free** — Keyless or free-tier providers
