# Routing Strategy Selection Reference

## Full Strategy Catalog

### priority
Ordered target list. Drain each target's capacity before moving to the next. Best for setups with a clear preferred provider and fallback chain.

### fill-first
Maximize each target's quota utilization before switching. Ideal for squeezing every free token before falling back to paid tiers.

### weighted
Random selection weighted by configurable per-target metrics (latency, cost, success rate). Use for custom traffic shaping.

### round-robin
Cycle through targets sequentially. Simple, predictable distribution.

### p2c (Power of Two Choices)
Pick two random targets, route to the one with lower load. Low overhead, good latency properties.

### least-used
Select the target with the lowest current active connections. Best for balanced utilization across providers.

### random
Uniform random selection with deduplication (won't pick the same target twice in a row on failure).

### strict-random
Uniform random without deduplication. Stateless randomization.

### cost-optimized
Minimize dollars per request using live catalog pricing data. Automatically picks the cheapest capable provider.

### headroom
Choose the target with the most remaining quota capacity. Preserves quotas across providers evenly.

### reset-window
Prefer targets whose quota resets soonest. Good for time-sensitive quota management.

### reset-aware
Rank targets by quota reset timing. Similar to reset-window with more granular control.

### context-relay
Hand off conversational context across targets when switching providers mid-conversation.

### context-optimized
Select the provider best suited for the current context window size. Routes large contexts to providers with higher token limits.

### cache-optimized
Pin reusable prompt prefixes to the same provider account. Maximizes prompt caching benefits (Anthropic, OpenAI).

### lkgp (Last Known Good Provider)
Sticky routing to the last provider that successfully handled a request. Prioritizes stability.

### auto
14-factor live scoring system combining cost, latency, success rate, quota, and other signals. Recommended default for most workloads.

### fusion
Fan out the same request to a panel of models, then a judge model synthesizes the best answer. Higher cost but highest quality.

### pipeline
Chain processing steps sequentially — the output of one model feeds into the next. Use for multi-stage processing (e.g., draft → refine → validate).
