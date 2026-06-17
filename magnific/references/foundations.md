# Magnific API — Foundations Reference

> The shared mechanics every endpoint depends on: base URL, authentication, the async task model, webhooks, rate limits, pricing, and the MCP server. Per-model parameters live in the sibling reference files.

## Base URL & authentication

- **Base URL:** `https://api.magnific.com/v1`
- **Auth header:** `x-magnific-api-key: YOUR_API_KEY` (an API-key header — **not** `Authorization: Bearer`).
- **Server-to-server only.** Private API keys must never be exposed to a browser or mobile client; proxy calls through your backend.
- **Getting a key:** sign in to magnific.com as an Administrator → **Settings → Organization → API Keys**. The same dashboard (`magnific.com/user/organization/api-keys`) holds the **webhook signing secret**.

```bash
curl -H "x-magnific-api-key: YOUR_API_KEY" https://api.magnific.com/v1/resources
```

```python
import requests
requests.get("https://api.magnific.com/v1/resources",
             headers={"x-magnific-api-key": "YOUR_API_KEY"})
```

```javascript
await fetch("https://api.magnific.com/v1/resources",
  { headers: { "x-magnific-api-key": "YOUR_API_KEY" } });
```

**Common HTTP errors** (across endpoints): `400` invalid parameters · `401` missing/invalid key · `500` internal error · `503` service unavailable.

## The async task model

Almost every generation endpoint is asynchronous:

1. **Submit** — `POST /v1/ai/<model>` with a JSON body. The response is **not** the result; it's a task handle:
   ```json
   { "data": { "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91", "status": "CREATED", "generated": [] } }
   ```
2. **Resolve** the task one of two ways:
   - **Poll** `GET /v1/ai/<model>/{task_id}` until `status == "COMPLETED"`.
   - **Webhook** — include `webhook_url` in the POST body; Magnific POSTs the payload to you on each status change.
3. **Read the output** from the `generated` array (image/video/audio URLs), populated only once `COMPLETED`.

**Status enum:** `CREATED` → `IN_PROGRESS` → `COMPLETED` | `FAILED`.

Most models also expose a **list** endpoint — `GET /v1/ai/<model>` — returning an array of `{task_id, status}` for recent tasks.

**Exceptions to the pattern:**
- **Remove Background** (`POST /v1/ai/beta/remove-background`) is **synchronous** — returns image URLs directly, no `task_id`.
- **Style Transfer** (`POST /v1/ai/image-style-transfer`) returns `task_status` (not `status`) and is **not** wrapped in a `data` object in the docs example. Parse both shapes defensively.

## Webhooks

Configure by passing `webhook_url` on the submit request. When the task changes status, Magnific sends an HTTP `POST` to that URL. The payload mirrors the GET-status response **without** the outer `data` wrapper — `{ "task_id", "status", "generated", ... }`. Match it to your job via `task_id`.

### Signature verification (Svix-style)

Each delivery includes three headers:

| Header | Meaning |
| --- | --- |
| `webhook-id` | Unique id for this delivery (use it to dedupe / detect replays). |
| `webhook-timestamp` | Send time (reject deliveries too far from now to prevent replay). |
| `webhook-signature` | Space-delimited list of versioned signatures, each `v1,<base64sig>`. |

**Algorithm — HMAC-SHA256:**

1. Take the **raw** request body (verify *before* JSON parsing).
2. Build the signed content string: `"{webhook-id}.{webhook-timestamp}.{raw_body}"`.
3. Compute `HMAC-SHA256(secret, signed_content)` and **base64-encode** it.
4. Compare (constant-time) against each signature in the `webhook-signature` header, stripping the `v1,` version prefix.

The signing **secret** comes from the dashboard (`magnific.com/user/organization/api-keys`). Svix secrets are typically base64, sometimes prefixed `whsec_` — strip the prefix and base64-decode the key before HMAC-ing. The docs provide verification snippets in **Python, JavaScript, PHP, and Java**. (Working Python + Node verifiers are in the skill's `SKILL.md` → *Receive + verify a webhook*.)

Webhooks beat polling for production: instant delivery, no constant requests, no rate-limit pressure.

## Rate limits

No `429`-equivalent status code or limit-header names are published — implement backoff on errors regardless.

- **50 requests/minute** overall.
- **50 hits/sec** over a 5-second window (burst), and **10 hits/sec** averaged over a 2-minute window.
- **1,000 requests/day** on `ai-image-to-prompt`, `ai-improve-prompt`, `ai-powered-search`.
- **100 requests/day** on Analytics endpoints (Business/Enterprise plans only; these consume no credits).

## Pricing (credit model)

- Usage is **credit-based**, deducted from the organization balance on each generation call.
- The web-app **"Unlimited" plan covers the web app only — not API usage.** API calls always draw credits.
- Documented per-call costs: **Relight ≈ €0.10/op**, **Style Transfer ≈ €0.10/op**, **upscales ≈ €0.10–€0.50** (scales with output pixel area = input dimensions × scale factor²).
- Generation cost generally scales with **resolution / megapixels** ("higher resolution = higher cost"). Most per-model numbers are **not published** — verify on the pricing page rather than guessing.

## MCP server

- **Endpoint:** `https://mcp.magnific.com`
- **Auth:** OAuth 2.0 — **no API key required**.
- **Use:** lets an AI assistant (Claude, etc.) drive Magnific generation (e.g. Mystic) as MCP tools, for assistant-driven workflows. For backend/programmatic integration, use the REST API instead.
