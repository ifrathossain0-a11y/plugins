# Compression Engine Details

## Session-Dedup
Identifies and removes repeated content across conversation turns. Effective in multi-turn conversations where system prompts or context blocks are duplicated.

## CCR (Context-Compression-Retrieval)
Archives large content blocks (documents, code files) behind retrieval markers. The full content is stored separately and retrieved on demand, keeping the active context small.

## Lite
Minimal cleanup: strips unnecessary whitespace, normalizes formatting, and shortens image/URL references. Near-zero quality impact.

## RTK (Response Tool Kit)
Filters and truncates tool-call results. Removes verbose output, stack traces, and redundant structured data from tool responses. Designed for agentic/code workflows.

## Responses Tool Output
Specialized JSON compression for shell output, patch diffs, and structured tool responses. Preserves semantic content while reducing token count.

## Headroom
Compacts tabular and structured JSON data (~30% savings). Flattens nested structures and removes redundant keys.

## Relevance
Scores each sentence against the latest user query and drops low-relevance content. Good for long conversations where early context has become irrelevant.

## Caveman
Rule-based prose compression achieving 65–75% reduction. Applies deterministic transformations: removes filler words, shortens phrases, condenses explanations. Fast, no ML overhead.

## Aggressive
Combines summarization with turn aging — older conversation turns are progressively summarized to free context space. Higher compression but may lose nuance from earlier turns.

## LLMLingua-2
ML-based semantic pruning using MobileBERT. Identifies and removes tokens that contribute least to meaning. Better quality preservation than rule-based methods, but adds processing latency.

## Ultra
Heuristic token pruning with optional small language model assistance. Pushes compression ratios to 60–85% using a combination of statistical and ML techniques.

## OmniGlyph (Experimental)
Encodes text context as images, leveraging vision model capabilities to read compressed representations. Experimental — quality and compatibility vary by model.
