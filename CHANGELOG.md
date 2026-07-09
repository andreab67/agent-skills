# Changelog

## v1.6 — 2026-07-08

Quality-bar sync from the ai-optimization skill dashboard's automated rubric pass — Error Handling sections across 5 skills, plus a real script extraction for `confluence-to-nextjs`.

### Error Handling sections added

- **`arcgis-enterprise-k8s`** — 6-row troubleshooting table: PVC stuck `Pending`, invalid license, LoadBalancer stuck `<pending>`, TLS/FQDN mismatch after deploy, upgrade rollout hang, `webgisdr` export failure.
- **`confluence-to-nextjs`** — 7 failure modes: 401/403, wrong page ID (404), 429 rate limiting on bulk exports, unmapped `<ac:structured-macro>` types, broken image/attachment links, malformed storage HTML breaking JSX, unmigrated internal `<ac:link>` targets.
- **`k8s-nextjs-deploy`** — new "Deploying a new Next.js app — step by step" (6 steps, namespace → pull secret → Deployment → Service → Ingress → verify), each with an explicit success check.
- **`kilo-gateway`** — 7-row signal/cause/recovery table: 404 misrouting, 401 key issues, 402 balance depletion, 429 free-tier limiting, BYOK silent failure, missing `usage` fields, hung streams.
- **`nextjs-monorepo-ci`** — new "Adding a new app to the pipeline — step by step" (7 steps: scaffold → validate → build → obfuscate → package → notify → IndexNow key), matching the pipeline's own stage order.
- **`postgres-ops`** — 7 failure modes tied to the diagnostic workflows already documented: connection exhaustion blocking diagnosis itself, `EXPLAIN ANALYZE` executing writes for real, missing `pg_stat_statements`, `CREATE INDEX CONCURRENTLY` left `INVALID`, `pg_upgrade --check` extension mismatches, pgBouncer transaction-pooling prepared-statement errors, empty replication-lag reads.

### `confluence-to-nextjs` script extraction

- Added `scripts/fetch-page.sh` — parameterized Confluence REST API v2 fetch (pins `body-format=storage`, fails loudly with the response body on 401/403/404 instead of writing an error payload silently to disk).
- Added `scripts/slugify.mjs` — the heading-to-anchor-ID slug generator from Step 2, plus `dedupeSlugs()` for the numeric-suffix collision handling described in Anti-pattern 6.
- Step 1 and Step 2 in `SKILL.md` now reference these scripts instead of inline snippets.

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
