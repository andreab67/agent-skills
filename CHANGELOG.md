# Changelog

## v1.2 — 2026-05-25

Three new provider SDK skills covering the major AI API surfaces.

- **`anthropic-sdk`** — Anthropic Python SDK: Messages API, streaming, tool use loop, `count_tokens()`, prompt caching (`cache_control: ephemeral`), vision, Opus 4.7 / Sonnet 4.6 / Haiku 4.5 pricing table, cost estimation helper.
- **`openai-sdk`** — OpenAI Python SDK: chat completions, streaming, function calling with tool_call loop, JSON structured output, embeddings, tiktoken `count_message_tokens()`, GPT-4o/mini/o1/o3 pricing table, cost estimation helper.
- **`kilo-gateway`** — Kilo.ai unified gateway: OpenAI-compatible API at `https://api.kilo.ai/api/gateway`, BYOK zero-markup routing, `provider/model-name` format, Python/TypeScript/cURL/LangChain patterns, prompt-cache `X-KiloCode-TaskId` header, `:free` model suffix.

## v1.1.1 — 2026-05-23

Discoverability pass. No skill content changes.

- **README:** added skills.sh catalog badge and explicit `https://skills.sh/andreab67/agent-skills` cross-link at the top.
- **README install list:** added missing one-liners for `ubuntu24-stig`, `login-gov`, and `arcgis-enterprise-k8s` (the loop snippet already covered them; the per-skill snippet did not).
- **Per-skill docs (`docs/*.md`):** added a `View on skills.sh` shield linking each skill to its catalog page so GitHub viewers can install in one click.

Background: the skills.sh directory is populated by install telemetry. The repo is installable directly with `npx skills add andreab67/agent-skills`, but per-skill search hits only appear once the index crawls them. These README changes lower the friction for the first wave of installs.

## v1.1 — add session-handoff skill

See git log for details.

## v1.0 — initial release

Initial 8-skill release: arcgis-enterprise-k8s, confluence-to-nextjs, k8s-nextjs-deploy, login-gov, nextjs-monorepo-ci, postgres-ops, ubuntu24-stig, plus the bootstrap docs.
