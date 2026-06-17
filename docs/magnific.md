# magnific

[![View on skills.sh](https://img.shields.io/badge/skills.sh-magnific-blue)](https://skills.sh/andreab67/agent-skills/magnific)

Expert assistance with the **Magnific** generative-media API (`https://api.magnific.com/v1`, part of Freepik) — image generation, AI upscaling, video, audio, and stock content through one async task API.

## Install

```bash
npx skills add andreab67/agent-skills@magnific -g -y
```

## What it does

Activates whenever you call `api.magnific.com` or work with any Magnific model. It front-loads the one thing that trips everyone up — **almost every endpoint is asynchronous**: you POST a job, get a `task_id`, then poll a GET endpoint or receive a signed webhook. Get that rhythm right and the other ~60 endpoints are just different request bodies. Includes copy-paste Python/TypeScript/cURL, a robust poll helper, a working Svix-style webhook verifier, and a complete per-endpoint catalog in `references/`.

## Capabilities

| Area | What you get |
| --- | --- |
| **Async task model** | submit → `task_id` → poll `GET /{task_id}` **or** webhook; `CREATED/IN_PROGRESS/COMPLETED/FAILED` |
| **Auth** | `x-magnific-api-key` header (server-to-server only) — not `Authorization: Bearer` |
| **Image generation** | Mystic (flagship), Flux 2 Pro/Turbo/Klein/Dev/Kontext/Pro-v1.1, HyperFlux, Seedream 4/4.5/Edit, Z-Image, Runway |
| **Image editing** | Creative + Precision **Upscalers**, Relight, Style Transfer, Remove Background, Image Expand |
| **Video** | Kling 2.1/2.5/2.6/O1/Motion-Control, MiniMax Hailuo & Live, WAN 2.5/2.6, Runway Gen4/Act-Two, LTX, Seedance, PixVerse, OmniHuman, VFX |
| **Audio** | music generation, sound effects, audio isolation |
| **Analytics & stock** | team credit usage/members/keys/groups/projects; stock resources, icons, videos |
| **Webhooks** | Svix-style HMAC-SHA256 verification (`webhook-id`/`webhook-timestamp`/`webhook-signature`) — working verifier included |
| **Ops** | rate limits (50 rpm), credit-based pricing notes, and the hosted MCP server (`mcp.magnific.com`, OAuth 2.0) |

## The gotchas it saves you from

- The POST response's `generated` array is **empty** — the output URL only appears once the task is `COMPLETED`.
- **Remove Background** is synchronous (no `task_id`) and its URLs **expire in 5 minutes**; **Style Transfer** returns `task_status`, not `data.status`.
- Mystic's `filter_nsfw` defaults **on** and can't be disabled on standard accounts; the upscalers default **off**.
- Upscaler output must stay under **25.3 megapixels**; Runway uses literal pixel `ratio` strings, not aspect-name enums.

## Official Docs

- Introduction: https://docs.magnific.com/introduction
- Quickstart / Authentication: https://docs.magnific.com/quickstart · https://docs.magnific.com/authentication
- Webhooks / Rate limits / Pricing: https://docs.magnific.com/webhooks · https://docs.magnific.com/ratelimits · https://docs.magnific.com/pricing
- MCP: https://docs.magnific.com/modelcontextprotocol
