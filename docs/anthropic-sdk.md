# anthropic-sdk

[![View on skills.sh](https://img.shields.io/badge/skills.sh-anthropic--sdk-blue)](https://skills.sh/andreab67/agent-skills/anthropic-sdk)

Expert assistance with the Anthropic Python SDK (`anthropic` package) — Messages API, tool use, streaming, prompt caching, cost estimation, and Claude model selection.

## Install

```bash
npx skills add andreab67/agent-skills@anthropic-sdk -g -y
```

## What it does

Activates when you're calling Claude models directly via the Anthropic API. Covers the full Messages API lifecycle: basic completions, streaming, multi-turn tool use loops, `count_tokens()` pre-flight checks, prompt caching with `cache_control: {type: ephemeral}`, and vision (base64 image input).

## Capabilities

| Area | What you get |
| --- | --- |
| **Messages API** | Complete Python quickstart: `client.messages.create()` with system, messages, max_tokens |
| **Streaming** | `client.messages.stream()` context manager with `text_stream` iterator |
| **Tool use** | Multi-turn `while stop_reason == "tool_use"` loop with `tool_result` response construction |
| **Token counting** | `client.messages.count_tokens()` — no API call, just the count |
| **Prompt caching** | `cache_control: {type: ephemeral}` on system blocks; `cache_read_input_tokens` discount tracking |
| **Vision** | Base64 image input in messages content blocks |
| **Model selection** | Opus 4.7 / Sonnet 4.6 / Haiku 4.5 pricing table with coding recommendations |
| **Cost estimation** | `estimate_cost(input_tokens, output_tokens, model)` helper |
| **Error handling** | `RateLimitError`, `APIStatusError`, `APIConnectionError` patterns |

## Model Pricing

| Model | Input $/Mtok | Output $/Mtok | Best For |
|-------|-------------|--------------|----------|
| claude-opus-4-7 | $15 | $45 | Complex reasoning, hard bugs |
| claude-sonnet-4-6 | $3 | $15 | General coding, PRs — best value |
| claude-haiku-4-5 | $0.80 | $4 | Fast completions, simple edits |

## Official Docs

- API Reference: https://docs.anthropic.com/en/api/
- SDK GitHub: https://github.com/anthropics/anthropic-sdk-python
