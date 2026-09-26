# openai-sdk

[![View on skills.sh](https://img.shields.io/badge/skills.sh-openai--sdk-blue)](https://skills.sh/andreab67/agent-skills/openai-sdk)

Expert assistance with the OpenAI Python SDK (`openai` package) — chat completions, function calling, structured outputs, embeddings, tiktoken token counting, and cost estimation.

## Install

```bash
npx skills add andreab67/agent-skills@openai-sdk -g -y
```

## What it does

Activates when you're calling GPT-6 Sol/Luna/Astra, or the legacy gpt-4o, gpt-4o-mini, or o3 models. Covers the complete OpenAI Python SDK workflow: basic completions, streaming, function calling with tool_call loops, JSON structured outputs, embeddings for semantic search, tiktoken pre-flight token counting, and cost estimation across all current models.

## Capabilities

| Area | What you get |
| --- | --- |
| **Chat completions** | `client.chat.completions.create()` with system/user messages, temperature, seed |
| **Streaming** | `stream=True` with `chunk.choices[0].delta.content` iterator |
| **Function calling** | `tools` array definition, `finish_reason == "tool_calls"` loop, `tool` role response |
| **Structured output** | `response_format={"type": "json_object"}` — guaranteed JSON response |
| **Embeddings** | `client.embeddings.create(model="text-embedding-3-small")` |
| **Token counting** | `tiktoken.encoding_for_model()` + `count_message_tokens()` helper |
| **Model selection** | GPT-6 Sol / Luna / Astra pricing table (plus legacy gpt-4o / mini / o3) with coding recommendations |
| **Cost estimation** | `estimate_cost(prompt_tokens, completion_tokens, model)` helper |
| **Error handling** | `RateLimitError`, `BadRequestError`, `AuthenticationError` patterns |

## Model Pricing

| Model | Input $/Mtok | Output $/Mtok | Best For |
|-------|-------------|--------------|----------|
| gpt-6-sol | $2 | $10 | General coding, tool use — best value |
| gpt-6-luna | $0.10 | $0.50 | High-volume, simple tasks |
| gpt-6-astra | $10 | $50 | Complex reasoning, hardest problems |

**Legacy, still-active:** gpt-4o ($2.50 / $10), gpt-4o-mini ($0.15 / $0.60), o3 ($2 / $8). `o1` ($15 / $60) is shutting down 2026-10-23 — avoid for new work.

## Official Docs

- Python SDK: https://github.com/openai/openai-python
- Chat completions: https://platform.openai.com/docs/api-reference/chat
