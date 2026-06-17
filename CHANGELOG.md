# Changelog

## v1.5 — 2026-06-17

New `magnific` skill — full coverage of the Magnific generative-media API, crawled from every page of docs.magnific.com.

### New skill — `magnific`

- **`magnific`** — the Magnific API (`https://api.magnific.com/v1`, part of Freepik):
  image generation, AI upscaling, video, audio, and stock content through one
  **async task API**. `SKILL.md` front-loads the submit→`task_id`→poll-or-webhook
  model, `x-magnific-api-key` auth, a robust poll helper, a working Svix-style
  HMAC-SHA256 webhook verifier (Python + Node), the full model catalog, a
  pre-flight checklist, and a 9-item anti-patterns gallery (empty `generated`
  array, sync Remove-Background, `task_status` on Style Transfer, NSFW defaults,
  25.3 MP upscaler cap, Runway pixel-ratio strings). Five `references/` files
  document all ~60 endpoints verbatim (parameters, enums, defaults,
  request/response examples): `foundations`, `image-generation`, `image-editing`,
  `video-generation`, `audio`, `analytics-and-stock`. Covers Mystic, Flux ×7,
  Seedream, Z-Image, the Creative/Precision upscalers, Relight, Style Transfer,
  Remove Background, Image Expand, Kling, MiniMax, WAN, Runway, LTX, Seedance,
  PixVerse, OmniHuman, VFX, music/SFX/isolation, team analytics, and stock
  icons/videos/templates — plus rate limits, the credit pricing model, and the
  hosted MCP server.

## v1.4 — 2026-06-12

New `openrouter` skill plus account/billing endpoint coverage for dashboard work.

### New skill

- **`openrouter`** — unified API over 300+ models (OpenAI-compatible chat,
  streaming, JSON mode, fallback arrays, `openrouter/auto`, sampling guide) with a
  dedicated `references/account-analytics-endpoints.md` covering the management
  endpoints needed for cost dashboards: `/credits`, `/keys`, `/activity`,
  beta `/analytics/meta` + `/analytics/query`, and the `/models` catalog. Documents
  the two dashboard gotchas: activity/analytics are **management-key-only** (regular
  keys 403), and `/activity` only returns the **last 30 _completed_ UTC days** (today
  excluded — empty ≠ broken).

### `kilo-gateway` updates

- Expanded **Cost & Billing**: microdollar billing flow (balance check → execute →
  extract → atomic update), free-model **200 req/hr/IP** limit, org daily spend caps.
- Documented that Kilo exposes **no usage/balance REST endpoint** — usage is
  dashboard-only; the only programmatic signal is **HTTP 402 + `buyCreditsUrl`** on
  depletion. Validate keys / count models via `GET /api/gateway/models`.
- Added the usage-and-billing doc link.

## v1.3 — 2026-06-09

Quality pass across all 12 skills — every skill now meets the full quality bar.

### New sections in all skills

- **Anti-patterns gallery** (5–7 items per skill): things that look in-scope but silently fail, break production, or waste money — with explicit refusal phrasing. Added to all skills that were missing it: `postgres-ops`, `confluence-to-nextjs`, `ubuntu24-stig`, `arcgis-enterprise-k8s`.
- **Pre-flight checklist** (SDK skills): ordered verification steps to run before writing any API code — added to `anthropic-sdk`, `openai-sdk`, `kilo-gateway`.
- **Worked end-to-end examples** (SDK skills): complete runnable code with a triage decision table showing keep/continue/done paths — added to `anthropic-sdk`, `openai-sdk`, `kilo-gateway`.

### Model updates in `anthropic-sdk`

- Updated `claude-opus-4-7` → **`claude-opus-4-8`** (current Opus model)
- Added **`claude-fable-5`** to the model selection table (best for autonomous agentic workflows)
- Updated cost estimation helper to reflect current pricing

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
