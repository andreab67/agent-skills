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

## Pre-flight Checklist

Before writing any API code, verify in order:

1. **Key present**: `echo $OPENAI_API_KEY` returns a value starting with `sk-`
2. **SDK installed**: `python -c "import openai; print(openai.__version__)"` succeeds (need ≥ 1.0.0 for the new client)
3. **tiktoken available**: `pip show tiktoken` — needed for token counting; not auto-installed with `openai`
4. **Model ID exact**: `gpt-4o` not `gpt4o`; `gpt-4o-mini` not `gpt-4-mini` — wrong IDs return 404, not a fallback
5. **JSON mode**: if using `response_format={"type": "json_object"}`, the word `"JSON"` must appear in your messages or the API errors

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
        "content": "Extract: name, version, language from 'FastAPI 0.115.5 Python framework'. Return JSON."
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

## Anti-patterns

These all look reasonable but will silently fail or waste money:

1. **Setting `temperature` on o1 or o3** — reasoning models ignore `temperature`; the parameter is accepted but has no effect, so any "deterministic reasoning" code you write around it is a no-op.
2. **Using `response_format={"type": "json_object"}` without the word "JSON" in the messages** — the API raises a 400; you must include "JSON" (case-insensitive) somewhere in your system or user message.
3. **Omitting the assistant tool-call message before the tool result** — when appending the conversation after a tool call, you must include `response.choices[0].message` (the assistant turn) before the `{"role": "tool", ...}` entry; skipping it causes a 400.
4. **Embedding batch size too large** — the embeddings API accepts up to 2048 inputs per call; passing a larger list errors silently in some SDK versions and hard-errors in others. Chunk at ≤2048.
5. **Using `tiktoken` on o1/o3** — there is no public tiktoken encoder for reasoning models; `tiktoken.encoding_for_model("o3")` throws `KeyError`. Use `gpt-4o` encoding as an approximation and add ~10% buffer.
6. **Not checking `finish_reason` before accessing `tool_calls`** — if `finish_reason` is `"length"` instead of `"tool_calls"`, `message.tool_calls` is `None` and your code crashes.
7. **Streaming with structured JSON mode** — `stream=True` and `response_format={"type":"json_object"}` together give you fragmented JSON chunks; you must buffer the full stream before `json.loads()`.

## Worked Example — Function Calling with Triage Decisions

**Scenario**: a support agent that can look up order status or escalate to a human.

```python
from openai import OpenAI
import json

client = OpenAI()

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_order_status",
            "description": "Return the current status and estimated delivery date for an order ID",
            "parameters": {
                "type": "object",
                "properties": {"order_id": {"type": "string"}},
                "required": ["order_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "escalate_to_human",
            "description": "Open a support ticket and notify a human agent",
            "parameters": {
                "type": "object",
                "properties": {
                    "reason": {"type": "string"},
                    "customer_id": {"type": "string"},
                },
                "required": ["reason", "customer_id"],
            },
        },
    },
]

messages = [
    {"role": "system", "content": "You are a helpful support agent."},
    {"role": "user", "content": "Order #ORD-8821 hasn't arrived. It's been 3 weeks."},
]

response = client.chat.completions.create(
    model="gpt-4o", max_tokens=512, tools=tools, tool_choice="auto", messages=messages
)

# Check finish_reason BEFORE accessing tool_calls
if response.choices[0].finish_reason == "tool_calls":
    tool_call = response.choices[0].message.tool_calls[0]
    args = json.loads(tool_call.function.arguments)

    if tool_call.function.name == "get_order_status":
        result = lookup_order(args["order_id"])
    elif tool_call.function.name == "escalate_to_human":
        result = create_ticket(args["reason"], args["customer_id"])

    # Append BOTH: assistant turn, then tool result
    messages.append(response.choices[0].message)
    messages.append({"role": "tool", "tool_call_id": tool_call.id, "content": json.dumps(result)})

    final = client.chat.completions.create(model="gpt-4o", max_tokens=512, messages=messages)
    print(final.choices[0].message.content)
```

**Loop triage table for this agent:**

| `finish_reason` | `tool_call.name` | Action |
|-----------------|-----------------|--------|
| `"tool_calls"` | `get_order_status` | Look up order, append result, continue |
| `"tool_calls"` | `escalate_to_human` | Create ticket, append result, continue |
| `"stop"` | — | Final answer — print and done |
| `"length"` | — | Response cut — raise `max_tokens` |

## Best Practices

1. **Always set `max_tokens`** — default is unlimited and expensive
2. **Use gpt-4o-mini** for anything that doesn't need GPT-4o quality; it's 32× cheaper
3. **Count tokens before the call** using tiktoken for batch cost prediction
4. **Use `seed`** for reproducible outputs in tests
5. **Temperature 0.0** for code generation; skip temperature for o1/o3 (they ignore it)
6. **JSON mode** requires the word "JSON" somewhere in the messages
7. **Embeddings**: use `text-embedding-3-small` unless you need max accuracy
8. **Check `finish_reason`** before accessing `tool_calls` or `content`

## Official Docs

- Python library: https://github.com/openai/openai-python
- Chat completions: https://platform.openai.com/docs/api-reference/chat
- Models: https://platform.openai.com/docs/models
- Embeddings: https://platform.openai.com/docs/guides/embeddings
- tiktoken: https://github.com/openai/tiktoken
