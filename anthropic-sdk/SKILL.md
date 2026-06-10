---
name: anthropic-sdk
description: Anthropic Claude SDK — Messages API, tool use, streaming, cost estimation, model selection
---

# Anthropic Claude SDK

Expert assistance with the Anthropic Python SDK (`anthropic` package) and Claude API. Covers the Messages API, tool use, streaming, prompt caching, cost estimation, and model selection for coding workloads.

## When to Use This Skill

- Calling Claude models directly via the Anthropic API
- Implementing tool use / function calling with Claude
- Streaming responses for real-time UX
- Estimating token costs before making a call
- Choosing between Fable 5, Opus 4.8, Sonnet 4.6, and Haiku 4.5
- Setting up prompt caching for long repeated contexts
- Debugging stop_reason, usage, and content block responses

## Pre-flight Checklist

Before writing any API code, verify these in order:

1. **Key present**: `echo $ANTHROPIC_API_KEY` returns a value starting with `sk-ant-`
2. **SDK installed**: `python -c "import anthropic; print(anthropic.__version__)"` succeeds
3. **Model ID correct**: copy from the table below — do not guess; model IDs include version suffixes
4. **max_tokens set**: there is no default; every call needs an explicit value or it will error
5. **Tool schema valid**: `input_schema` must use `"type": "object"` at the top level — bare arrays fail

## Quick Reference

### Installation
```bash
pip install anthropic
export ANTHROPIC_API_KEY='sk-ant-...'
```

### Basic Messages Call (Python)
```python
import anthropic

client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY

message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    system="You are a Python expert.",
    messages=[{"role": "user", "content": "Write a quicksort."}],
)
print(message.content[0].text)
print(f"Tokens used: {message.usage.input_tokens} in / {message.usage.output_tokens} out")
```

### Streaming
```python
with client.messages.stream(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Explain async/await"}],
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

### Tool Use (Function Calling)
```python
tools = [
    {
        "name": "run_sql",
        "description": "Execute a SQL query and return results",
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "SQL query to execute"},
                "database": {"type": "string", "enum": ["prod", "staging"]}
            },
            "required": ["query"]
        }
    }
]

messages = [{"role": "user", "content": "Show me all users created this week"}]
response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    tools=tools,
    messages=messages,
)

while response.stop_reason == "tool_use":
    tool_block = next(b for b in response.content if b.type == "tool_use")
    result = execute_tool(tool_block.name, tool_block.input)  # your impl

    messages.append({"role": "assistant", "content": response.content})
    messages.append({
        "role": "user",
        "content": [{"type": "tool_result", "tool_use_id": tool_block.id, "content": str(result)}]
    })
    response = client.messages.create(model="claude-sonnet-4-6", max_tokens=1024, tools=tools, messages=messages)

print(response.content[0].text)
```

### Count Tokens (No API Call)
```python
count = client.messages.count_tokens(
    model="claude-sonnet-4-6",
    messages=[{"role": "user", "content": "Your prompt here"}],
)
print(f"Input tokens: {count.input_tokens}")
```

### Prompt Caching (Long Repeated Context)
```python
response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    system=[{
        "type": "text",
        "text": "<large system prompt or document>",
        "cache_control": {"type": "ephemeral"}  # cache for 5 min
    }],
    messages=[{"role": "user", "content": "Summarize the key points"}],
)
# usage.cache_creation_input_tokens — first call writes cache
# usage.cache_read_input_tokens — subsequent calls read at 90% discount
```

### Vision (Image Input)
```python
import base64
with open("screenshot.png", "rb") as f:
    img_b64 = base64.standard_b64encode(f.read()).decode()

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": [
            {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": img_b64}},
            {"type": "text", "text": "What bug do you see in this screenshot?"}
        ]
    }]
)
```

## Model Selection

| Model | ID | Input $/Mtok | Output $/Mtok | Best For |
|-------|----|-------------|--------------|----------|
| **claude-fable-5** | `claude-fable-5` | $— | $— | Autonomous long-horizon tasks, agentic workflows |
| **claude-opus-4-8** | `claude-opus-4-8` | $15 | $75 | Complex reasoning, architecture decisions, hard bugs |
| **claude-sonnet-4-6** | `claude-sonnet-4-6` | $3 | $15 | General coding, PRs, code review — best value |
| **claude-haiku-4-5** | `claude-haiku-4-5-20251001` | $0.80 | $4 | Fast completions, autocomplete, simple edits |

**Coding recommendation:** Start with Sonnet 4.6. Escalate to Opus 4.8 when Sonnet fails. Use Fable 5 for multi-step agentic tasks where the agent runs autonomously.

## Cost Estimation

```python
def estimate_cost(input_tokens: int, output_tokens: int, model: str = "claude-sonnet-4-6") -> float:
    prices = {
        "claude-opus-4-8":   (15.00, 75.00),
        "claude-sonnet-4-6": (3.00,  15.00),
        "claude-haiku-4-5":  (0.80,  4.00),
    }
    in_price, out_price = prices[model]
    return (input_tokens * in_price + output_tokens * out_price) / 1_000_000
```

## Key Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `max_tokens` | Required | Always set; use 0 to pre-warm cache only |
| `temperature` | 1.0 | 0.0–0.3 for coding/analysis; 0.7+ for creative |
| `top_p` | 1.0 | Nucleus sampling; lower = more focused |
| `stop_sequences` | [] | Stop generation at these strings |
| `tool_choice` | `"auto"` | `"any"` forces tool use; `"none"` disables |

## Error Handling

```python
import anthropic

try:
    response = client.messages.create(...)
except anthropic.RateLimitError:
    time.sleep(60)  # back off and retry
except anthropic.APIStatusError as e:
    print(f"Status {e.status_code}: {e.message}")
except anthropic.APIConnectionError:
    print("Network error — check connectivity")
```

## Anti-patterns

These all look reasonable but will silently fail or produce wrong results:

1. **Omitting `max_tokens`** — the parameter is required; the API errors immediately, not gracefully.
2. **Building the tool loop with a `for` instead of `while`** — a tool can chain into another tool call, so a fixed-iteration loop truncates the agent mid-task. Always loop on `stop_reason == "tool_use"`.
3. **Placing `cache_control` on a short or frequently-changing block** — caching costs 25% more per token on creation; blocks under ~1000 tokens or that change per-call will never recoup the premium.
4. **Using `client.messages.create()` without appending the assistant's content block before the `tool_result`** — the API requires the assistant turn with the `tool_use` block before the `tool_result` user turn; skipping it returns a 400.
5. **Passing `temperature` on a reasoning-optimised model** — some extended-thinking Claude variants ignore temperature; check the model docs before relying on low-temp determinism.
6. **Guessing model IDs** — `claude-opus-4` (no suffix) is not a valid ID; always use the versioned string from the table above. Wrong IDs return a 404, not a fallback.
7. **Calling `count_tokens()` with the full tools list omitted** — token counts for tool-augmented prompts exclude the tool-schema overhead unless you pass `tools=` to `count_tokens()` as well.

## Worked Example — Tool Use Loop with Triage Decisions

**Scenario**: build a two-tool SQL assistant that can query a DB and format results.

```python
import anthropic
import json

client = anthropic.Anthropic()

tools = [
    {
        "name": "run_sql",
        "description": "Execute a read-only SQL query and return rows as JSON",
        "input_schema": {
            "type": "object",
            "properties": {"query": {"type": "string"}},
            "required": ["query"],
        },
    },
    {
        "name": "format_table",
        "description": "Format a list of dicts as a markdown table",
        "input_schema": {
            "type": "object",
            "properties": {"rows": {"type": "array", "items": {"type": "object"}}},
            "required": ["rows"],
        },
    },
]

messages = [{"role": "user", "content": "Show me the top 5 users by signup date as a table."}]

# Pre-flight: count tokens before sending
token_count = client.messages.count_tokens(
    model="claude-sonnet-4-6", tools=tools, messages=messages
)
print(f"Pre-flight: {token_count.input_tokens} input tokens")  # guard against runaway prompts

response = client.messages.create(
    model="claude-sonnet-4-6", max_tokens=1024, tools=tools, messages=messages
)

# Tool loop — WHILE, not for
while response.stop_reason == "tool_use":
    tool_block = next(b for b in response.content if b.type == "tool_use")

    if tool_block.name == "run_sql":
        result = run_query(tool_block.input["query"])  # your DB call
    elif tool_block.name == "format_table":
        result = build_markdown_table(tool_block.input["rows"])  # your formatter
    else:
        result = f"Unknown tool: {tool_block.name}"

    # Append BOTH turns — assistant's tool_use block, then tool_result
    messages.append({"role": "assistant", "content": response.content})
    messages.append({
        "role": "user",
        "content": [{"type": "tool_result", "tool_use_id": tool_block.id, "content": str(result)}],
    })
    response = client.messages.create(
        model="claude-sonnet-4-6", max_tokens=1024, tools=tools, messages=messages
    )

print(response.content[0].text)
```

**What the loop triage table looks like in practice:**

| Turn | stop_reason | Action |
|------|-------------|--------|
| 1 | `tool_use` → `run_sql` | Execute DB query, append result, loop |
| 2 | `tool_use` → `format_table` | Format rows, append result, loop |
| 3 | `end_turn` | Print `content[0].text` — done |

If `stop_reason` is `max_tokens` at any turn: the response was cut — increase `max_tokens` or split the task.

## Best Practices

1. **Always set `max_tokens`** — no default, unbounded responses are expensive
2. **Use Sonnet 4.6** as the default; escalate to Opus 4.8 only when needed
3. **Cache system prompts** when the same large context is reused across calls
4. **Count tokens first** (`count_tokens`) before expensive batch jobs — pass `tools=` too
5. **Temperature 0.0–0.2** for deterministic code generation and analysis
6. **Check `stop_reason`** — `"tool_use"` means continue the loop; `"max_tokens"` means response was cut
7. **Log `usage`** on every call in production to track spend

## Official Docs

- API Reference: https://docs.anthropic.com/en/api/
- SDK GitHub: https://github.com/anthropics/anthropic-sdk-python
- Models: https://docs.anthropic.com/en/docs/about-claude/models
- Tool use: https://docs.anthropic.com/en/docs/build-with-claude/tool-use
