# openai-sdk

[![View on skills.sh](https://img.shields.io/badge/skills.sh-openai--sdk-blue)](https://skills.sh/andreab67/agent-skills/openai-sdk)

Expert assistance with the OpenAI Python SDK (`openai` package) — chat completions, function calling, structured outputs, embeddings, tiktoken token counting, and cost estimation.

## Install

```bash
npx skills add andreab67/agent-skills@openai-sdk -g -y
```

## What it does

Activates when you're calling GPT-4o, GPT-4o-mini, o1, or o3 models. Covers the complete OpenAI Python SDK workflow: basic completions, streaming, function calling with tool_call loops, JSON structured outputs, embeddings for semantic search, tiktoken pre-flight token counting, and cost estimation across all current models.

## Capabilities

| Area | What you get |
| --- | --- |
| **Chat completions** | `client.chat.completions.create()` with system/user messages, temperature, seed |
| **Streaming** | `stream=True` with `chunk.choices[0].delta.content` iterator |
| **Function calling** | `tools` array definition, `finish_reason == "tool_calls"` loop, `tool` role response |
| **Structured output** | `response_format={"type": "json_object"}` — guaranteed JSON response |
| **Embeddings** | `client.embeddings.create(model="text-embedding-3-small")` |
| **Token counting** | `tiktoken.encoding_for_model()` + `count_message_tokens()` helper |
| **Model selection** | GPT-4o / mini / o1 / o3 pricing table with coding recommendations |
| **Cost estimation** | `estimate_cost(prompt_tokens, completion_tokens, model)` helper |
| **Error handling** | `RateLimitError`, `BadRequestError`, `AuthenticationError` patterns |

## Model Pricing

| Model | Input $/Mtok | Output $/Mtok | Best For |
|-------|-------------|--------------|----------|
| gpt-4o | $5 | $15 | General coding, vision, tool use |
| gpt-4o-mini | $0.15 | $0.60 | High-volume, simple tasks (32× cheaper) |
| o1 | $15 | $60 | Complex reasoning, hard algorithms |
| o3 | $10 | $40 | Best reasoning, cost-efficient vs o1 |

## Official Docs

- Python SDK: https://github.com/openai/openai-python
- Chat completions: https://platform.openai.com/docs/api-reference/chat
