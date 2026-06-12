# openrouter

[![View on skills.sh](https://img.shields.io/badge/skills.sh-openrouter-blue)](https://skills.sh/andreab67/agent-skills/openrouter)

Expert assistance with the OpenRouter API — unified access to 300+ models through one OpenAI-compatible endpoint, with intelligent routing, automatic fallbacks, and the management/analytics endpoints needed to build cost dashboards.

## Install

```bash
npx skills add andreab67/agent-skills@openrouter -g -y
```

## What it does

Activates when calling models through OpenRouter (`https://openrouter.ai/api/v1`) or building usage/cost reporting on top of it. Covers chat completions, streaming, JSON mode, fallback model arrays, `openrouter/auto` routing, sampling parameters, and the account endpoints that power spend dashboards.

## Capabilities

| Area | What you get |
| --- | --- |
| **Unified inference** | 300+ models via one OpenAI-compatible API; `provider/model-name` IDs |
| **Routing & fallbacks** | `models: [...]` fallback arrays, `openrouter/auto` dynamic selection |
| **Sampling guide** | temperature / top_p / penalties / seed / max_tokens with task-based guidance |
| **Structured output** | JSON mode and schema-validated responses |
| **Account balance** | `GET /credits` — total credits, usage, remaining (management key) |
| **Per-key spend** | `GET /keys` — monthly spend per provisioned key (management key) |
| **Per-model activity** | `GET /activity` — daily model breakdown (**management-key-only**) |
| **Beta analytics** | `GET /analytics/meta` + `POST /analytics/query` — flexible dimension/metric queries |
| **Model catalog** | `GET /models` — full pricing/architecture/limits field reference |

## Building a cost dashboard — read this first

Two gotchas trip up every dashboard built on OpenRouter analytics:

1. **`/activity` and the beta analytics endpoints require a management
   (provisioning) key.** A regular inference key returns
   `403 "Only management keys can fetch activity for an account"`.
2. **`/activity` covers only the last 30 _completed_ UTC days** — it excludes
   today. An empty `{"data":[]}` while spend is happening usually means all the
   usage is from the current UTC day; it appears once the day closes. For
   real-time-ish display, fall back to `/keys` (per-key monthly spend).

Full request/response shapes, query parameters, and field references live in
[`openrouter/references/account-analytics-endpoints.md`](../openrouter/references/account-analytics-endpoints.md).

## Official Docs

- API Reference: https://openrouter.ai/docs/api-reference/overview
- Activity: https://openrouter.ai/docs/api/api-reference/analytics/get-user-activity
- Query analytics (beta): https://openrouter.ai/docs/api/api-reference/beta-analytics/query-analytics
- Models: https://openrouter.ai/docs/api/api-reference/models/get-models
