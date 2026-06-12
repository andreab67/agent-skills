# OpenRouter Account, Analytics & Models Endpoints

Reference for the management/analytics endpoints used to build usage dashboards
and check account spend. **Key-type matters**: the activity and analytics
endpoints require a **management (provisioning) key**, NOT a regular inference key.
A regular key returns `403 {"error":{"message":"Only management keys can fetch
activity for an account","code":403}}`.

---

## GET /api/v1/activity — daily per-model activity

```
GET https://openrouter.ai/api/v1/activity
Authorization: Bearer <MANAGEMENT_KEY>
```

**Auth:** Management key only (regular keys → 403).

**Coverage / lag (critical):** Returns data for the **last 30 _completed_ UTC
days**. It **excludes the current UTC day** — same-day spend does NOT appear until
that calendar day closes. An empty `{"data":[]}` with recent spend almost always
means all the usage is from *today* (UTC). If ingesting on a schedule, wait ~30 min
after the UTC midnight boundary before requesting the previous day (events are
aggregated by request start time; long reasoning calls finalize late).

**Query parameters (all optional):**
| Param | Type | Notes |
|-------|------|-------|
| `date` | `YYYY-MM-DD` | Single UTC date |
| `api_key_hash` | SHA-256 hex | Filter to one API key |
| `user_id` | string | Org member id (organizations only) |

**Response item fields:** `date`, `model`, `model_permaslug`, `endpoint_id`,
`provider_name`, `requests`, `prompt_tokens`, `completion_tokens`,
`reasoning_tokens`, `usage` (total USD cost), `byok_usage_inference`.

```json
{ "data": [ { "date": "2026-06-11", "model": "anthropic/claude-sonnet-4.5",
  "provider_name": "Anthropic", "requests": 42, "prompt_tokens": 12000,
  "completion_tokens": 3400, "reasoning_tokens": 0, "usage": 0.18 } ] }
```

> Note: there is **no separate "activity key"** concept. Use the management key.
> In sr-models, `get_activity()` falls back to `/api/v1/keys` (per-key monthly
> spend) precisely because `/activity` is empty for the current UTC day.

---

## GET /api/v1/keys — per-key monthly spend (fallback)

```
GET https://openrouter.ai/api/v1/keys
Authorization: Bearer <MANAGEMENT_KEY>
```

Returns provisioned keys; each item includes `name` and `usage_monthly` (USD).
Used as the dashboard fallback when `/activity` returns empty — shows spend split
by key rather than by model.

---

## Beta Analytics — flexible query API

### GET /api/v1/analytics/meta — available dimensions/metrics

```
GET https://openrouter.ai/api/v1/analytics/meta
Authorization: Bearer <MANAGEMENT_KEY>
```
No params. Returns the catalog you can build queries from:
```json
{ "data": {
  "dimensions":   [ { "name": "model", "display_label": "Model" } ],
  "granularities":[ { "name": "day",   "display_label": "Day" } ],   // minute|hour|day|week|month
  "metrics":      [ { "name": "request_count", "display_label": "Requests",
                      "display_format": "number", "is_rate": false } ], // number|currency|percent|latency|throughput
  "operators":    [ { "name": "eq", "value_type": "scalar" } ]          // eq|neq|in|not_in|gt|gte|lt|lte
} }
```

### POST /api/v1/analytics/query — run an analytics query

```
POST https://openrouter.ai/api/v1/analytics/query
Authorization: Bearer <MANAGEMENT_KEY>
Content-Type: application/json
```

**Body** (only `metrics` required):
| Field | Type | Notes |
|-------|------|-------|
| `metrics` | `string[]` | **Required**. e.g. `["request_count"]` |
| `dimensions` | `string[]` | Group by, e.g. `["model"]` |
| `filters` | `object[]` | `{field, operator, value}` (value scalar or array) |
| `granularity` | `string` | `minute\|hour\|day\|week\|month` |
| `time_range` | `object` | `{start, end}` ISO-8601 |
| `limit` | `int` | Max total rows (default 1000) |
| `group_limit` | `int` | Max rows per dimension combo |
| `order_by` | `object` | `{field, direction}` (`asc\|desc`) |

**Response:**
```json
{ "data": {
  "data": [ { /* metric + dimension values per row */ } ],
  "metadata": { "query_time_ms": 12, "row_count": 30, "truncated": false },
  "cachedAt": 1730000000
} }
```

Errors: 400/401/403/408/500, each with `error.{code,message}`. Beta — no
documented lag/availability guarantees; expect the same completed-day semantics
as `/activity`.

---

## GET /api/v1/models — model catalog & pricing

```
GET https://openrouter.ai/api/v1/models
Authorization: Bearer <KEY>   # any valid key
```

**Query params (optional):** `category` (programming, roleplay, marketing,
science, legal, finance, health…), `supported_parameters` (comma list),
`output_modalities` (text|image|audio|embeddings, default text), `sort`
(most-popular | newest | top-weekly | pricing-low-to-high | pricing-high-to-low |
context-high-to-low | throughput-high-to-low | latency-low-to-high),
`use_rss`, `use_rss_chat_links`.

**Per-model fields:** `id`, `name`, `canonical_slug`, `description`, `created`
(unix), `context_length`, `expiration_date`, `knowledge_cutoff`,
`hugging_face_id`, plus nested objects:

- `architecture`: `input_modalities[]`, `output_modalities[]`, `instruct_type`,
  `modality`, `tokenizer`
- `pricing` (all **strings**, USD; prompt/completion are per-token): `prompt`,
  `completion`, `image`, `audio`, `image_output`, `audio_output`, `image_token`,
  `input_cache_read`, `input_cache_write`, `input_audio_cache`, `request`,
  `web_search`, `internal_reasoning`, `discount`
- `top_provider`: `is_moderated`, `context_length`, `max_completion_tokens`
- `per_request_limits`: `{prompt_tokens, completion_tokens}` | null
- `default_parameters`: temperature/top_p/top_k/frequency_penalty/presence_penalty/repetition_penalty
- `supported_parameters[]`, `supported_voices[]`
- `benchmarks` (omitted when unavailable): `artificial_analysis.{intelligence_index,
  coding_index, agentic_index}`, `design_arena[]`
- `links.details` (URL to the model's endpoints API)

> Pricing values are **strings** to preserve precision for very large/small
> numbers — parse with care. `prompt`/`completion` are per-token (multiply by 1e6
> for per-million-token figures).

---

## Source docs
- Activity: https://openrouter.ai/docs/api/api-reference/analytics/get-user-activity
- Analytics meta (beta): https://openrouter.ai/docs/api/api-reference/beta-analytics/get-analytics-meta
- Query analytics (beta): https://openrouter.ai/docs/api/api-reference/beta-analytics/query-analytics
- Models: https://openrouter.ai/docs/api/api-reference/models/get-models
