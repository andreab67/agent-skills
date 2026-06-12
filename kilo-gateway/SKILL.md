---
name: kilo-gateway
description: Kilo.ai gateway — OpenAI-compatible API over 500+ models, BYOK routing, cost tracking
---

# Kilo.ai Gateway

Expert assistance with the Kilo.ai API gateway. Uses OpenAI-compatible SDK syntax, routes to 500+ models across 14+ providers (Anthropic, OpenAI, Google, AWS Bedrock, Mistral, xAI, etc.), supports BYOK (Bring Your Own Key) for zero-markup direct billing.

## When to Use This Skill

- Calling any model through the Kilo.ai unified gateway endpoint
- Setting up BYOK so requests route direct to a provider under your own API key
- Using Kilo Code VS Code extension's gateway for workspace AI calls
- Accessing models not available in a single provider's SDK
- Tracking per-request costs across providers from a single dashboard
- Integrating Kilo gateway with LangChain, LlamaIndex, or other frameworks

## Pre-flight Checklist

Before writing any API code, verify in order:

1. **Key present**: `echo $KILO_API_KEY` returns your JWT token — get it from kilo.ai dashboard → **API Keys**
2. **SDK installed**: `pip show openai` — Kilo uses the OpenAI-compatible API; no separate package needed
3. **base_url exact**: must be `https://api.kilo.ai/api/gateway` (note the `/api/gateway` path — missing it gives a 404 on every call)
4. **Model ID format**: always `provider/model-name` — `anthropic/claude-sonnet-4.5` not `claude-sonnet-4.5`; bare model IDs are rejected
5. **BYOK configured**: if you added a BYOK key, confirm the provider in dashboard → **Keys** shows "Active" before assuming zero-markup routing is live

## Quick Reference

### Installation
```bash
pip install openai   # Kilo uses the OpenAI-compatible API
export KILO_API_KEY='your-jwt-token'
```

### Basic Call (Python)
```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.getenv("KILO_API_KEY"),
    base_url="https://api.kilo.ai/api/gateway",
)

response = client.chat.completions.create(
    model="anthropic/claude-sonnet-4.5",
    messages=[{"role": "user", "content": "Write a Python context manager."}],
    max_tokens=1024,
)
print(response.choices[0].message.content)
```

### Streaming (Python)
```python
with client.chat.completions.create(
    model="openai/gpt-4o",
    messages=[{"role": "user", "content": "Explain monads"}],
    stream=True,
) as stream:
    for chunk in stream:
        content = chunk.choices[0].delta.content
        if content:
            print(content, end="", flush=True)
```

### TypeScript / JavaScript
```typescript
import OpenAI from "openai";

const client = new OpenAI({
  apiKey: process.env.KILO_API_KEY,
  baseURL: "https://api.kilo.ai/api/gateway",
});

const response = await client.chat.completions.create({
  model: "anthropic/claude-sonnet-4.5",
  messages: [{ role: "user", content: "Write a React hook for debouncing." }],
  max_tokens: 1024,
});
console.log(response.choices[0].message.content);
```

### cURL
```bash
curl -X POST https://api.kilo.ai/api/gateway/chat/completions \
  -H "Authorization: Bearer $KILO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "anthropic/claude-sonnet-4.5",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 512
  }'
```

### LangChain Integration
```python
from langchain_openai import ChatOpenAI
import os

llm = ChatOpenAI(
    model="anthropic/claude-sonnet-4.5",
    api_key=os.getenv("KILO_API_KEY"),
    base_url="https://api.kilo.ai/api/gateway",
)
response = llm.invoke("Write a Python decorator for retry logic.")
```

## Model Naming Convention

Format: `provider/model-name`

| Model | Kilo ID |
|-------|---------|
| Claude Sonnet 4.5 | `anthropic/claude-sonnet-4.5` |
| Claude Haiku 4.5 | `anthropic/claude-haiku-4-5-20251001` |
| GPT-4o | `openai/gpt-4o` |
| GPT-4o-mini | `openai/gpt-4o-mini` |
| Gemini 2.0 Flash | `google/gemini-2.0-flash-exp` |
| Mistral Large | `mistral/mistral-large` |

Free models append `:free` — billed at $0, usage tracked.

## BYOK (Bring Your Own Key)

BYOK routes requests through Kilo's gateway using YOUR provider API keys — zero Kilo markup:

1. Add your provider key in Kilo dashboard → **Keys** → Add BYOK key
2. Keys are encrypted at rest (AES-256) and never logged
3. Requests are forwarded directly to the provider under your credential
4. You are billed by the provider at their standard rate; Kilo adds nothing

**When to use BYOK:** You have existing provider accounts (Anthropic, OpenAI, etc.) and want unified access without paying a reseller margin. Use managed Kilo billing only for providers you don't have direct accounts with.

## Authentication

```python
# Standard JWT bearer token — get from kilo.ai dashboard
headers = {"Authorization": f"Bearer {os.getenv('KILO_API_KEY')}"}

# Optional headers for advanced use:
# X-KiloCode-OrganizationId — org context for team accounts
# X-KiloCode-TaskId — cache key for prompt caching across requests
```

## Cost & Billing

- **Managed billing**: Kilo tracks usage with **microdollar precision** (1 USD =
  1,000,000 microdollars). Cost is computed from input tokens, output tokens, and
  cache write/hit tokens. Billing flow per request: balance check → execute →
  extract usage from response → atomic balance update.
- **BYOK**: $0 via Kilo; provider bills you directly.
- **Free models**: zero cost, usage tracked. Rate-limited to **200 requests/hour
  per IP** (HTTP 429 when exceeded). Paid models have no gateway-level limit, but
  upstream provider limits still apply.
- Cost formula: same as underlying provider (input tokens × $/Mtok + output tokens × $/Mtok).

### Checking balance / usage — there is NO usage API endpoint

> **Important for dashboards:** the Kilo gateway exposes **no REST endpoint** for
> querying balance or spend. Per the docs, usage/balance is **dashboard-only**
> (`https://app.kilo.ai`). The only programmatic signal is the **402 on depletion**
> (see below). To validate a key / count models, hit
> `GET https://api.kilo.ai/api/gateway/models` — that is what sr-models'
> `_check_kilo()` does, since there is no balance endpoint to call.

- **Balance depleted** → paid-model requests return **HTTP 402** with a
  `buyCreditsUrl` in the error metadata pointing to `https://app.kilo.ai/credits`.
- **Organization accounts**: shared credit pool with per-member **daily spend
  caps**, plus auto top-up and minimum-balance alerts (configured in dashboard).
- Per-request usage fields tracked (visible in dashboard, returned in
  `response.usage`): model id, provider, token counts, cache metrics, cost in
  microdollars, latency, BYOK status.

## Anti-patterns

These all look right but will fail or produce unexpected billing:

1. **Using a bare model ID without the provider prefix** — `claude-sonnet-4.5` gives a 404; it must be `anthropic/claude-sonnet-4.5`. There is no model alias lookup.
2. **Swapping `base_url` and `api_key` when using two clients in the same script** — a common pattern is to have a direct-provider client and a Kilo client side-by-side; accidentally sending a Kilo request with your Anthropic key (or vice versa) gets a 401 with no useful error message.
3. **Assuming BYOK is active immediately after adding the key** — Kilo validates BYOK credentials on first use; a newly added key with a typo only fails at call time, not on dashboard save. Always test with a short call before trusting BYOK is wired.
4. **Using `:free` models in production** — free-tier models may have lower rate limits and no SLA; they're for prototyping. Treat `:free` as "subject to rate-limit at any time" rather than "zero cost with full reliability".
5. **Passing `X-KiloCode-TaskId` with a different value per request** — the header is a cache key; changing it per call defeats prompt caching. Use a stable ID for calls that share a common system prompt.
6. **Expecting OpenAI-specific response fields on non-OpenAI models** — Kilo normalises the schema but some providers return `null` for `usage.completion_tokens_details` or `logprobs`; guard with `if response.usage` before accessing sub-fields.
7. **Not setting `max_tokens`** — behaviour differs by underlying provider; some default to a very short limit, others to unlimited. Always set it explicitly to get predictable costs across model switches.

## Worked Example — Swapping Providers by Changing One Variable

**Scenario**: you want to run the same prompt against Claude, GPT-4o, and a free Gemini model to compare output quality, then pick a winner for production.

```python
from openai import OpenAI
import os

kilo = OpenAI(
    api_key=os.getenv("KILO_API_KEY"),
    base_url="https://api.kilo.ai/api/gateway",
)

CANDIDATES = [
    "anthropic/claude-sonnet-4.5",
    "openai/gpt-4o",
    "google/gemini-2.0-flash-exp:free",
]

PROMPT = "In three sentences, explain why monads are useful in functional programming."

results = {}
for model_id in CANDIDATES:
    response = kilo.chat.completions.create(
        model=model_id,
        messages=[{"role": "user", "content": PROMPT}],
        max_tokens=256,
        temperature=0.3,
    )
    results[model_id] = {
        "text": response.choices[0].message.content,
        "tokens_in":  response.usage.prompt_tokens if response.usage else "n/a",
        "tokens_out": response.usage.completion_tokens if response.usage else "n/a",
    }

for model_id, r in results.items():
    print(f"\n=== {model_id} ({r['tokens_in']} in / {r['tokens_out']} out) ===")
    print(r["text"])
```

**Decision table for picking the production model:**

| Model | Cost/call | Quality check | Choice |
|-------|-----------|--------------|--------|
| `anthropic/claude-sonnet-4.5` | ~$0.002 | Accurate, nuanced | ✅ Pick if budget allows |
| `openai/gpt-4o` | ~$0.003 | Accurate, verbose | Consider if GPT preferred |
| `google/gemini-2.0-flash-exp:free` | $0.00 | Good enough for drafts | ✅ Prototyping / low-stakes |

Promote the winner to `PRODUCTION_MODEL` env var — the only change needed in code.

## Best Practices

1. **Use BYOK** if you already have Anthropic/OpenAI accounts — eliminates any Kilo margin
2. **model ID format is `provider/model-name`** — always prefix with provider
3. **Same SDK, different base_url** — swap between direct provider and Kilo by changing one env var
4. **Free models** are useful for prototyping; check `:free` suffix in model catalog
5. **Prompt caching** works via the `X-KiloCode-TaskId` header to share cache across calls — keep it stable per use-case
6. **Framework compat**: any library that accepts a custom `base_url`/`openai_api_base` works with Kilo
7. **Guard `response.usage`** before accessing sub-fields — not all providers populate every field

## Official Docs

- Quickstart: https://kilo.ai/docs/gateway/quickstart
- SDKs & Frameworks: https://kilo.ai/docs/gateway/sdks-and-frameworks
- Model catalog: https://kilo.ai/docs/gateway/models
- BYOK setup: https://kilo.ai/docs/gateway/byok
- Usage & billing: https://kilo.ai/docs/gateway/usage-and-billing
