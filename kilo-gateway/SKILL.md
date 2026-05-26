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

- **Managed billing**: Kilo tracks usage with microdollar precision; view per-request breakdown in dashboard
- **BYOK**: $0 via Kilo; provider bills you directly
- **Free models**: zero cost, usage tracked
- Cost formula: same as underlying provider (input tokens × $/Mtok + output tokens × $/Mtok)

## Best Practices

1. **Use BYOK** if you already have Anthropic/OpenAI accounts — eliminates any Kilo margin
2. **model ID format is `provider/model-name`** — always prefix with provider
3. **Same SDK, different base_url** — swap between direct provider and Kilo by changing one env var
4. **Free models** are useful for prototyping; check `:free` suffix in model catalog
5. **Prompt caching** works via the `X-KiloCode-TaskId` header to share cache across calls
6. **Framework compat**: any library that accepts a custom `base_url`/`openai_api_base` works with Kilo

## Official Docs

- Quickstart: https://kilo.ai/docs/gateway/quickstart
- SDKs & Frameworks: https://kilo.ai/docs/gateway/sdks-and-frameworks
- Model catalog: https://kilo.ai/docs/gateway/models
- BYOK setup: https://kilo.ai/docs/gateway/byok
