# kilo-gateway

[![View on skills.sh](https://img.shields.io/badge/skills.sh-kilo--gateway-blue)](https://skills.sh/andreab67/agent-skills/kilo-gateway)

Expert assistance with the Kilo.ai API gateway — OpenAI-compatible API over 500+ models, BYOK routing, and cost tracking across 14+ providers.

## Install

```bash
npx skills add andreab67/agent-skills@kilo-gateway -g -y
```

## What it does

Activates when routing AI calls through Kilo's unified gateway. Uses standard OpenAI SDK syntax — swap `base_url` to `https://api.kilo.ai/api/gateway` and your Kilo JWT for `api_key`. Covers Python, TypeScript, cURL, and LangChain integration patterns.

## Capabilities

| Area | What you get |
| --- | --- |
| **Unified routing** | 500+ models across 14+ providers with one SDK and one API key |
| **Model naming** | `provider/model-name` format (e.g. `anthropic/claude-sonnet-4.5`, `openai/gpt-4o`) |
| **BYOK** | Bring Your Own Key — zero Kilo markup, requests forward to provider under your credential |
| **Python quickstart** | `OpenAI(api_key=KILO_API_KEY, base_url="https://api.kilo.ai/api/gateway")` |
| **Streaming** | Same `stream=True` pattern as standard OpenAI SDK |
| **TypeScript** | Complete TS/JS example with same `baseURL` override |
| **LangChain** | `ChatOpenAI(api_key=..., base_url=...)` integration |
| **Authentication** | JWT bearer, `X-KiloCode-OrganizationId`, `X-KiloCode-TaskId` (prompt cache key) |
| **Free models** | `:free` suffix — $0 billed, usage tracked (good for prototyping) |
| **Cost tracking** | Per-request breakdown in Kilo dashboard; BYOK bills directly to provider |

## When to use BYOK

If you already have Anthropic or OpenAI accounts, BYOK eliminates any Kilo margin. Add your provider key in Kilo dashboard → **Keys** → Add BYOK key. Keys are encrypted at rest (AES-256) and never logged.

## Official Docs

- Quickstart: https://kilo.ai/docs/gateway/quickstart
- Model catalog: https://kilo.ai/docs/gateway/models
- BYOK setup: https://kilo.ai/docs/gateway/byok
