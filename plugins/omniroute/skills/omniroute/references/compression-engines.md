# OmniRoute Compression Engines

OmniRoute provides 12 composable compression engines that can be stacked for 15–95% token savings (89% average with RTK → Caveman).

## Engine Reference

| Engine | Savings | Method | Best for |
|--------|---------|--------|----------|
| Session-Dedup | Varies | Removes repeated content across turns | Multi-turn conversations |
| CCR | Varies | Archives large blocks behind retrieval markers | Long documents in context |
| Lite | 5–15% | Whitespace and image-URL trimming | Minimal-impact cleanup |
| RTK | 30–60% | Tool-result filtering and truncation | Tool-heavy sessions |
| Responses Tool Output | 20–40% | JSON compression for shell/patch output | Code agent workflows |
| Headroom | ~30% | Tabular JSON compaction | Structured data responses |
| Relevance | 20–50% | Sentence scoring against latest query | Long conversations |
| Caveman | 65–75% | Rule-based prose compression | General text reduction |
| Aggressive | 50–80% | Summarization and turn aging | Context window pressure |
| LLMLingua-2 | 40–70% | ML semantic pruning via MobileBERT | Quality-preserving compression |
| Ultra | 60–85% | Heuristic token pruning with optional SLM | Maximum compression |
| OmniGlyph | Experimental | Context-as-image encoding | Research/experimental use |

## Compression Modes

OmniRoute bundles engines into named modes:

| Mode | Pipeline | Typical savings |
|------|----------|-----------------|
| `lite` | Lite only | 5–15% |
| `standard` | Auto-selected by OmniRoute | 30–60% |
| `aggressive` | Aggressive + Caveman | 60–80% |
| `ultra` | Ultra + LLMLingua-2 | 70–90% |
| `rtk` | RTK + Responses Tool Output | 30–60% |
| `stacked` | RTK → Caveman (recommended) | 78–95% |

## Configuration

### Environment Variable

```bash
export OMNIROUTE_COMPRESSION_DEFAULT=stacked
```

### Per-Request

Include compression preference in the request:

```bash
curl http://localhost:20128/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-OmniRoute-Compression: stacked" \
  -d '{"model": "auto", "messages": [...]}'
```

### Via Dashboard

Navigate to `http://localhost:20128` → Compression → Mode selector.

## Inspecting Compression

The `X-OmniRoute-Compression` response header reports which engines were applied and the compression ratio achieved.

```bash
# View compression stats in logs
omniroute logs --filter compression
```
