---
name: openai-sdk
description: OpenAI Python SDK — Chat completions, function calling, embeddings, token counting, cost estimation
---

# OpenAI SDK

Expert assistance with the OpenAI Python SDK (`openai` package). Covers chat completions, function calling, structured outputs, embeddings, token counting with tiktoken, cost estimation, and model selection.

## When to Use This Skill

- Calling GPT-4o, GPT-4o-mini, o1, or o3 models
- Implementing function calling / tools
- Generating embeddings for semantic search
- Counting tokens with tiktoken before making a call
- Estimating costs for a request
- Using structured outputs (JSON mode / `response_format`)
- Building streaming chat applications

## Quick Reference

### Installation
```bash
pip install openai tiktoken
export OPENAI_API_KEY='sk-...'
```

### Basic Chat Completion
```python
from openai import OpenAI

client = OpenAI()  # reads OPENAI_API_KEY

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": "You are a senior Python engineer."},
        {"role": "user", "content": "Write a binary search function."},
    ],
    max_tokens=1024,
    temperature=0.2,
)
print(response.choices[0].message.content)
print(f"Tokens: {response.usage.prompt_tokens} in / {response.usage.completion_tokens} out")
```

### Streaming
```python
with client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Explain async generators"}],
    stream=True,
) as stream:
    for chunk in stream:
        delta = chunk.choices[0].delta.content
        if delta:
            print(delta, end="", flush=True)
```

### Function Calling / Tools
```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "query_database",
            "description": "Run a read-only SQL query and return results as JSON",
            "parameters": {
                "type": "object",
                "properties": {
                    "sql": {"type": "string"},
                    "limit": {"type": "integer", "default": 100}
                },
                "required": ["sql"]
            }
        }
    }
]

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "List the top 5 customers by revenue"}],
    tools=tools,
    tool_choice="auto",
)

# Handle tool call
if response.choices[0].finish_reason == "tool_calls":
    tool_call = response.choices[0].message.tool_calls[0]
    import json
    args = json.loads(tool_call.function.arguments)
    result = run_query(args["sql"])  # your impl

    messages = [
        {"role": "user", "content": "List top 5 customers by revenue"},
        response.choices[0].message,  # assistant's tool_call message
        {"role": "tool", "tool_call_id": tool_call.id, "content": json.dumps(result)}
    ]
    final = client.chat.completions.create(model="gpt-4o", messages=messages)
    print(final.choices[0].message.content)
```

### Structured Output (JSON Mode)
```python
import json

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{
        "role": "user",
        "content": "Extract: name, version, language from 'FastAPI 0.115.5 Python framework'"
    }],
    response_format={"type": "json_object"},
)
data = json.loads(response.choices[0].message.content)
```

### Embeddings
```python
response = client.embeddings.create(
    model="text-embedding-3-small",  # 1536 dims, cheapest
    input="FastAPI async endpoint with PostgreSQL",
)
vector = response.data[0].embedding  # list of 1536 floats
```

### Token Counting with tiktoken
```python
import tiktoken

enc = tiktoken.encoding_for_model("gpt-4o")
tokens = enc.encode("Your prompt text here")
print(f"Token count: {len(tokens)}")

# Estimate for a message list
def count_message_tokens(messages: list[dict], model: str = "gpt-4o") -> int:
    enc = tiktoken.encoding_for_model(model)
    total = 3  # reply priming
    for m in messages:
        total += 4  # per-message overhead
        total += len(enc.encode(m.get("content", "")))
        total += len(enc.encode(m.get("role", "")))
    return total
```

## Model Selection

| Model | Input $/Mtok | Output $/Mtok | Context | Best For |
|-------|-------------|--------------|---------|----------|
| **gpt-4o** | $5 | $15 | 128K | General coding, vision, tool use |
| **gpt-4o-mini** | $0.15 | $0.60 | 128K | High-volume, simple tasks (32× cheaper) |
| **o1** | $15 | $60 | 200K | Complex reasoning, hard algorithms |
| **o3** | $10 | $40 | 200K | Best reasoning, cost-efficient vs o1 |
| **text-embedding-3-small** | $0.02 | — | 8K | Semantic search, similarity |

**Coding recommendation:** GPT-4o for general tasks; o3/o1 for hard algorithmic problems; gpt-4o-mini for autocomplete/linting/classification at scale.

## Cost Estimation

```python
def estimate_cost(prompt_tokens: int, completion_tokens: int, model: str = "gpt-4o") -> float:
    prices = {
        "gpt-4o":        (5.00,  15.00),
        "gpt-4o-mini":   (0.15,  0.60),
        "o1":            (15.00, 60.00),
        "o3":            (10.00, 40.00),
    }
    in_p, out_p = prices[model]
    return (prompt_tokens * in_p + completion_tokens * out_p) / 1_000_000
```

## Key Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `max_tokens` | unlimited | Always set to control cost |
| `temperature` | 1.0 | 0.0–0.3 for code/analysis; not supported on o1/o3 |
| `top_p` | 1.0 | Alternative to temperature; don't use both |
| `seed` | None | Integer → deterministic output (for testing) |
| `response_format` | text | `{"type": "json_object"}` for guaranteed JSON |
| `tool_choice` | `"auto"` | `"required"` forces a tool call |

## Error Handling

```python
from openai import OpenAI, RateLimitError, BadRequestError, AuthenticationError

try:
    response = client.chat.completions.create(...)
except RateLimitError:
    time.sleep(60)  # retry after back-off
except BadRequestError as e:
    print(f"Bad request: {e}")  # malformed input, context too long
except AuthenticationError:
    print("Invalid API key")
```

## Best Practices

1. **Always set `max_tokens`** — default is unlimited and expensive
2. **Use gpt-4o-mini** for anything that doesn't need GPT-4o quality; it's 32× cheaper
3. **Count tokens before the call** using tiktoken for batch cost prediction
4. **Use `seed`** for reproducible outputs in tests
5. **Temperature 0.0** for code generation; skip temperature for o1/o3 (they ignore it)
6. **JSON mode** requires the word "JSON" somewhere in the messages
7. **Embeddings**: use `text-embedding-3-small` unless you need max accuracy

## Official Docs

- Python library: https://github.com/openai/openai-python
- Chat completions: https://platform.openai.com/docs/api-reference/chat
- Models: https://platform.openai.com/docs/models
- Embeddings: https://platform.openai.com/docs/guides/embeddings
- tiktoken: https://github.com/openai/tiktoken
