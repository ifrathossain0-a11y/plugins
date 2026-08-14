---
name: omniroute-compression
description: Configure OmniRoute token compression pipelines to reduce API costs. Use when the user wants to optimize token usage, set up compression modes, or troubleshoot compression behavior.
references:
  - engine-details
---

# OmniRoute Compression Skill

Configure and optimize OmniRoute's 12-engine token compression pipeline to save 15–95% on token costs.

## When to Use This Skill

- User wants to reduce API costs
- Configuring compression for a specific workload
- Debugging compression behavior
- Choosing between compression modes

## Compression Mode Quick Reference

| Mode | Engines | Savings | Quality Impact |
|------|---------|---------|----------------|
| `lite` | Whitespace/URL cleanup | 5–15% | Negligible |
| `standard` | Auto-selected | 30–60% | Low |
| `rtk` | Tool result filtering | 30–60% | Low (tool output only) |
| `stacked` | RTK → Caveman | 78–95% | Moderate |
| `aggressive` | Summarize + age turns | 60–80% | Moderate–High |
| `ultra` | Heuristic + ML pruning | 70–90% | Higher |

## Configuration

### Set Default Mode

```bash
export OMNIROUTE_COMPRESSION_DEFAULT=stacked
```

### Per-Request Override

```bash
curl http://localhost:20128/v1/chat/completions \
  -H "X-OmniRoute-Compression: stacked" \
  -H "Content-Type: application/json" \
  -d '{"model": "auto", "messages": [...]}'
```

### Disable Compression

```bash
curl http://localhost:20128/v1/chat/completions \
  -H "X-OmniRoute-Compression: none" \
  ...
```

## Choosing the Right Mode

### For code agents / tool-heavy sessions
Use `rtk` — filters and truncates tool results without touching the conversation.

### For general chat / cost savings
Use `stacked` (RTK → Caveman) — 89% average savings with acceptable quality.

### For quality-sensitive tasks
Use `lite` or `standard` — minimal impact on response quality.

### For context window pressure
Use `aggressive` or `ultra` — when you're hitting context limits.

## Inspecting Compression

Check the `X-OmniRoute-Compression` response header for:
- Which engines were applied
- Compression ratio achieved
- Source token count vs. compressed count

```bash
omniroute logs --filter compression
```

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Responses losing context | Compression too aggressive | Switch to `lite` or `standard` |
| No cost savings visible | Compression disabled or `none` | Set `OMNIROUTE_COMPRESSION_DEFAULT` |
| Tool results garbled | RTK truncation too aggressive | Adjust RTK settings in dashboard |
| Slow responses | LLMLingua-2 ML processing overhead | Use `caveman` instead for rule-based speed |
