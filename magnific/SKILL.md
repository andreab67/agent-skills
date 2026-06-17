---
name: magnific
description: Magnific generative-media API (api.magnific.com, part of Freepik) — image generation, upscaling, video, audio, and stock content through one async task API. Use when calling Magnific or working with any of its models — Mystic; Flux (2 Pro / 2 Turbo / 2 Klein / Dev / Kontext Pro / Pro v1.1 / HyperFlux); Seedream 4 / 4.5 / 4.5 Edit; Z-Image; the Creative & Precision Upscalers; Relight; Style Transfer; Remove Background; Image Expand; Kling 2.1/2.5/2.6/O1/Motion-Control; MiniMax Hailuo & Video-01-Live; WAN 2.5/2.6; Runway Gen4 Turbo & Act-Two; LTX 2.0 Pro; Seedance; PixVerse; OmniHuman; VFX; music generation; sound effects; audio isolation; or the team analytics + stock (icons / videos / templates) endpoints. Triggers — "Magnific API", "x-magnific-api-key", "upscale an image", "image to video", "generate an image/video/music", "poll a task_id", "Magnific webhook signature", "Magnific MCP". Covers the submit→poll-or-webhook task model, auth, webhook HMAC verification, rate limits, pricing, and the full per-endpoint catalog in references/. Do NOT use for non-Magnific image tools, the generic OpenAI/Anthropic SDKs, or unrelated Freepik stock APIs.
---

# magnific

Magnific is a generative-media API (image, video, audio, and stock content) served at **`https://api.magnific.com/v1`**. Almost every generation endpoint works the same way: you **submit** a job, get back a **`task_id`**, then either **poll** a GET endpoint or let a **webhook** deliver the result. Learn that one rhythm and the other ~60 endpoints are just different request bodies.

This skill is the operating manual. The exhaustive, per-endpoint parameter/request/response detail for *every* model lives in [`references/`](references/) — reach for it when you need an exact enum value or field name.

## When to use

- Building anything against `api.magnific.com` — generating, editing, upscaling images; making video/music/SFX; pulling stock assets.
- Choosing the right Magnific model for a task ("which model upscales while inventing detail?", "fastest text-to-image?", "image-to-video from a still?").
- Wiring up the async lifecycle: submitting jobs, polling `task_id`, or receiving + **verifying** webhooks.
- Debugging a 401/400, an empty `generated` array, a job stuck `IN_PROGRESS`, or a webhook signature mismatch.

## Do NOT use for

- Non-Magnific image/video tools (Replicate, fal, raw Stability/RunwayML APIs), or the generic OpenAI/Anthropic SDKs — those have their own skills.
- The separate Freepik stock-photo API. Magnific's stock endpoints (`/v1/resources`, `/v1/icons`, `/v1/videos`) are covered here; the standalone Freepik API is not.

## The one mental model: submit → poll **or** webhook

> **99% of Magnific endpoints are asynchronous.** A POST does not return your image/video — it returns a `task_id`. The result arrives later.

```
POST /v1/ai/<model>            →  202-ish: { "data": { "task_id": "…", "status": "CREATED", "generated": [] } }
        │
        ├── (a) POLL:  GET /v1/ai/<model>/{task_id}   every few seconds until status == COMPLETED
        │
        └── (b) WEBHOOK:  pass "webhook_url" in the POST  →  Magnific POSTs the same payload to you on each status change
```

- **Status enum** (every task, every model): `CREATED` → `IN_PROGRESS` → `COMPLETED` | `FAILED`.
- **`generated`** is an empty array `[]` until `status == "COMPLETED"`, then it holds the output URL(s).
- **Production rule:** always pass a `webhook_url`. Polling is fine for scripts/notebooks; webhooks are how you avoid hammering the API (and the rate limits) in a real app. Video/music jobs can take minutes — do **not** tight-poll them.
- **Two documented exceptions to the async model** (don't poll these):
  - **Remove Background** (`POST /v1/ai/beta/remove-background`) is **synchronous** — it returns image URLs directly, no `task_id`.
  - **Style Transfer** returns `task_status` (not `status`) and is **not wrapped in `data`** in the docs — parse both shapes defensively.

## Quick start

**Auth.** Every request carries your key in the **`x-magnific-api-key`** header (note: not `Authorization: Bearer`). Keys are **server-to-server only** — never ship one to a browser/mobile client. Generate keys at *magnific.com → Settings → Organization → API Keys* (admin role required).

```bash
# Submit a Mystic image generation
curl -X POST https://api.magnific.com/v1/ai/mystic \
  -H "x-magnific-api-key: $MAGNIFIC_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a cat with wings playing a guitar, cinematic lighting",
    "resolution": "2k",
    "aspect_ratio": "widescreen_16_9",
    "model": "realism",
    "webhook_url": "https://your-app.com/webhooks/magnific"
  }'
# → { "data": { "task_id": "046b6c7f-…", "status": "CREATED", "generated": [] } }

# Poll for the result
curl https://api.magnific.com/v1/ai/mystic/046b6c7f-… \
  -H "x-magnific-api-key: $MAGNIFIC_API_KEY"
# → { "data": { "task_id": "046b6c7f-…", "status": "COMPLETED",
#               "generated": ["https://ai-statics.freepik.com/…jpg"], "has_nsfw": [false] } }
```

### Python — submit + poll, the right way

```python
import os, time, requests

BASE = "https://api.magnific.com/v1"
HEADERS = {"x-magnific-api-key": os.environ["MAGNIFIC_API_KEY"]}

def submit(model_path: str, body: dict) -> str:
    r = requests.post(f"{BASE}/ai/{model_path}", headers=HEADERS, json=body, timeout=30)
    r.raise_for_status()
    return r.json()["data"]["task_id"]

def wait(model_path: str, task_id: str, *, interval=3, timeout=600) -> list[str]:
    """Poll until COMPLETED. Returns the `generated` URLs. Raises on FAILED/timeout."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        r = requests.get(f"{BASE}/ai/{model_path}/{task_id}", headers=HEADERS, timeout=30)
        r.raise_for_status()
        data = r.json()["data"]
        status = data.get("status") or data.get("task_status")   # Style Transfer uses task_status
        if status == "COMPLETED":
            return data["generated"]
        if status == "FAILED":
            raise RuntimeError(f"task {task_id} FAILED")
        time.sleep(interval)
    raise TimeoutError(f"task {task_id} not done after {timeout}s")

task = submit("mystic", {"prompt": "a serene alpine lake at dawn", "resolution": "2k"})
print(wait("mystic", task))
```

### TypeScript — submit

```typescript
const BASE = "https://api.magnific.com/v1";
const res = await fetch(`${BASE}/ai/image-upscaler`, {
  method: "POST",
  headers: {
    "x-magnific-api-key": process.env.MAGNIFIC_API_KEY!,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ image: base64Image, scale_factor: "4x", engine: "magnific_sparkle" }),
});
const { data } = await res.json();   // { task_id, status, generated: [] }
```

## Model catalog

Pick by intent. Full param tables for each are in `references/`. Paths below are relative to `https://api.magnific.com/v1`.

### Image generation — text-to-image (`references/image-generation.md`)

| Model | `POST` path | Reach for it when… |
| --- | --- | --- |
| **Mystic** ⭐ | `/ai/mystic` | The flagship. Photoreal *and* illustration; structure/style reference images, `@character` mentions, style/color steering. `model`: `realism`/`super_real`/`zen`/`flexible`/`fluid`/`editorial_portraits`. `resolution` `1k`/`2k`/`4k`. |
| **Flux 2 Pro** | `/ai/text-to-image/flux-2-pro` | High fidelity + up to **4 base64 input images** for multi-image conditioning. ≤1440px (`width`/`height`). |
| **Flux 2 Turbo** | `/ai/text-to-image/flux-2-turbo` | Fast. Square/rect up to **2048px** via `image_size:{width,height}`. `guidance_scale` 1–20, `enable_safety_checker`. |
| **Flux 2 Klein** | `/ai/text-to-image/flux-2-klein` | Aspect-ratio + `1k`/`2k`, up to 4 reference images, `safety_tolerance` **0–5**. |
| **Flux Kontext Pro** | `/ai/text-to-image/flux-kontext-pro` | Reference-guided edits with `guidance`/`steps` dials. `input_image` is a **URL** (not base64). |
| **Flux Pro v1.1** | `/ai/text-to-image/flux-pro-v1-1` | Prior-gen production model, `safety_tolerance` **0–6**. |
| **Flux Dev** | `/ai/text-to-image/flux-dev` | Rich `styling` — `effects` (color/framing/`lightning`) + dominant-color palette. Prompt optional. |
| **HyperFlux** | `/ai/text-to-image/hyperflux` | Fastest/cheapest Flux; same `styling` palette as Flux Dev. |
| **Runway** | `/ai/text-to-image/runway` | Runway t2i. `ratio` is **required** and uses literal pixel strings (`1920:1080`, …) — not aspect names. |
| **Seedream 4 / 4.5** | `/ai/text-to-image/seedream-v4` · `seedream-v4-5` | ByteDance Seedream. |
| **Seedream 4.5 Edit** | `/ai/text-to-image/seedream-v4-5-edit` | Edit an existing image with Seedream 4.5. |
| **Z-Image Turbo** | `/ai/text-to-image/z-image` | Fast lightweight text-to-image. |

### Image editing (`references/image-editing.md`)

| Model | `POST` path | Reach for it when… |
| --- | --- | --- |
| **Upscaler — Creative** ⭐ | `/ai/image-upscaler` | Enlarge **and invent detail** (prompt-guided). `scale_factor` `2x`/`4x`/`8x`/`16x`; `creativity`/`hdr`/`resemblance`/`fractality` each `-10..10`; `optimized_for` presets. Output ≤ **25.3 MP**. |
| **Upscaler — Precision** | `/ai/image-upscaler-precision` | Enlarge **faithfully** (no reinterpretation). `sharpen`/`smart_grain`/`ultra_detail` `0..100`. |
| **Relight** | `/ai/image-relight` | Change lighting via prompt, reference image, **or** lightmap (the latter two are mutually exclusive). ~€0.10/op. |
| **Style Transfer** | `/ai/image-style-transfer` | Repaint an image in a reference's style. ⚠ returns `task_status`, not wrapped in `data`. ~€0.10/op. |
| **Remove Background** | `/ai/beta/remove-background` | Cutout. **Synchronous**, form-encoded body, result URLs **expire in 5 min**. |
| **Image Expand** | `/ai/image-expand/flux-pro` | Outpaint/extend canvas. `left`/`right`/`top`/`bottom` px, each `0..2048`. |

### Video generation (`references/video-generation.md`)

| Family | Models (`POST` paths under `/ai/`) |
| --- | --- |
| **Kling** | `image-to-video/kling-v2-1-pro` · `kling-v2-5-pro` · `kling-v2-6-pro` (text or image) · `kling-o1-pro` (first/last frame) · `video/kling-v2-6-motion-control-pro` |
| **MiniMax** | `image-to-video/minimax-hailuo-02-1080p` · `minimax-hailuo-2-3-1080p` · `minimax-live` (Video-01-Live) |
| **WAN** | `text-to-video/wan-2-5-t2v-1080p` · `image-to-video/wan-2-5-i2v-1080p` · `wan-v2-6-1080p` |
| **Runway** | `image-to-video/runway-gen4-turbo` · `video/runway-act-two` |
| **Others** | `text-to-video/ltx-2-pro` · `image-to-video/seedance-pro-1080p` · `image-to-video/pixverse-v5` · `video/omni-human-1-5` · `video/vfx` |

### Audio (`references/audio.md`)

| Capability | Endpoints (under `/ai/`) |
| --- | --- |
| **Music generation** | `POST music-generation` · `GET music-generation` (list) · `GET music-generation/{task-id}` |
| **Sound effects** | `POST sound-effects` · `GET sound-effects` · `GET sound-effects/{task-id}` |
| **Audio isolation** | `POST audio-isolation` · `GET audio-isolation` · `GET audio-isolation/{task-id}` |

### Analytics & stock content (`references/analytics-and-stock.md`)

| Capability | Endpoints (under `/v1/`) |
| --- | --- |
| **Team analytics** | `POST analytics/team-credit-usage` · `GET analytics/team-members` · `team-api-keys` · `team-groups` · `team-projects`. **Business/Enterprise only; consume no credits; 100 req/day.** |
| **Stock — images & templates** | `GET resources` · `resources/{id}` · `resources/{id}/download` · `resources/{id}/download/{format}` |
| **Stock — icons** | `GET icons` · `icons/{id}` · `icons/{id}/download` |
| **Stock — videos** | `GET videos` · `videos/{id}` · `videos/{id}/download` |

## Copy-paste recipes

### Upscale an image (the flagship), end-to-end

```python
import base64, requests, os
HEADERS = {"x-magnific-api-key": os.environ["MAGNIFIC_API_KEY"]}

with open("input.jpg", "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode()

body = {
    "image": img_b64,
    "scale_factor": "4x",            # 2x | 4x | 8x | 16x  — output must stay ≤ 25.3 MP
    "optimized_for": "films_n_photography",
    "prompt": "ultra-detailed, sharp, photorealistic",
    "creativity": 2,                 # -10..10  (how much new detail AI may invent)
    "hdr": 1,                        # -10..10
    "resemblance": 0,                # -10..10  (fidelity to the original)
    "fractality": -1,                # -10..10  (prompt strength / detail-per-pixel)
    "engine": "magnific_sparkle",    # automatic | magnific_illusio | magnific_sharpy | magnific_sparkle
}
task_id = requests.post("https://api.magnific.com/v1/ai/image-upscaler",
                        headers=HEADERS, json=body, timeout=60).json()["data"]["task_id"]
# then poll GET /v1/ai/image-upscaler/{task_id}  (see wait() helper above)
```

> **Creative vs Precision:** use `image-upscaler` (Creative) when you *want* the AI to add detail/texture; use `image-upscaler-precision` when the output must stay faithful to the source (no hallucinated detail) — it exposes only `sharpen`/`smart_grain`/`ultra_detail`.

### Image-to-video (Kling)

```python
# Most i2v models take a base64/URL `image` + `prompt`; see references/video-generation.md
# for each model's exact params (duration, aspect, cfg, etc.). Always use a webhook for video.
body = {"image": img_b64, "prompt": "slow cinematic push-in, gentle camera motion",
        "webhook_url": "https://your-app.com/webhooks/magnific"}
task_id = requests.post("https://api.magnific.com/v1/ai/image-to-video/kling-v2-6-pro",
                        headers=HEADERS, json=body, timeout=60).json()["data"]["task_id"]
```

### Receive + verify a webhook (Svix-style HMAC-SHA256)

Magnific signs webhooks the way Svix does. Each delivery carries three headers — `webhook-id`, `webhook-timestamp`, `webhook-signature` — and you verify by HMAC-ing `"{id}.{timestamp}.{raw_body}"`. **Get the signing secret from the dashboard** (*magnific.com/user/organization/api-keys*). Always verify against the **raw** request body, before any JSON parsing.

```python
import hmac, hashlib, base64

def verify_magnific_webhook(secret: str, headers: dict, raw_body: bytes) -> bool:
    wid   = headers["webhook-id"]
    wts   = headers["webhook-timestamp"]
    signed = f"{wid}.{wts}.{raw_body.decode()}".encode()

    # Svix secrets are usually base64 (sometimes prefixed "whsec_"); decode if so.
    key = secret.split("_", 1)[1] if secret.startswith("whsec_") else secret
    try:
        key_bytes = base64.b64decode(key)
    except Exception:
        key_bytes = key.encode()

    expected = base64.b64encode(hmac.new(key_bytes, signed, hashlib.sha256).digest()).decode()

    # webhook-signature is space-delimited, each entry "v1,<base64sig>"
    for part in headers["webhook-signature"].split(" "):
        sig = part.split(",", 1)[1] if "," in part else part
        if hmac.compare_digest(sig, expected):
            return True
    return False
```

```javascript
// Node — same scheme
import crypto from "node:crypto";
export function verify(secret, headers, rawBody) {
  const signed = `${headers["webhook-id"]}.${headers["webhook-timestamp"]}.${rawBody}`;
  const key = secret.startsWith("whsec_") ? secret.slice(6) : secret;
  const keyBuf = Buffer.from(key, "base64");
  const expected = crypto.createHmac("sha256", keyBuf).update(signed).digest("base64");
  return headers["webhook-signature"].split(" ").some((p) => {
    const sig = p.includes(",") ? p.split(",")[1] : p;
    return sig.length === expected.length &&
      crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
  });
}
```

The webhook payload mirrors the GET-status response **without** the outer `data` wrapper — i.e. `{ "task_id", "status", "generated", ... }`. Use the `task_id` to match it to the job you submitted.

## Pre-flight checklist

Before you call any generation endpoint:

1. **Key in the right header** — `x-magnific-api-key`, server-side only. (Not `Authorization`.)
2. **Right base URL** — `https://api.magnific.com/v1`, and the `/ai/` segment for generation paths.
3. **Expect a `task_id`, not a result** — wire up polling *or* a `webhook_url` before you ship. Decide which per call (webhook for prod, poll for scripts).
4. **Image inputs:** check base64-vs-URL per model (e.g. Flux 2 Pro/Klein = base64; Flux Kontext Pro = URL; Relight/Style Transfer accept either). Send the **original file**, not a `canvas.toDataURL()` re-encode (loses ~8–20% quality).
5. **Upscaler:** confirm `input_pixels × scale_factor²` stays under **25.3 MP** or the job rejects.
6. **NSFW defaults differ:** Mystic's `filter_nsfw` defaults **`true`** and *cannot* be disabled on standard accounts; the upscalers default **`false`**. Don't assume.
7. **Vocabulary per model:** aspect ratios are named enums (`widescreen_16_9`) on most models — but Runway uses literal pixel `ratio` strings, and Flux 2 Turbo uses an `image_size` object. The effect key in Flux Dev/HyperFlux is spelled **`lightning`**, not "lighting".

## Anti-patterns — looks right, isn't

1. **Reading the image URL off the POST response.** The POST returns `{task_id, status:"CREATED", generated:[]}` — `generated` is **empty**. The URL only exists after the task reaches `COMPLETED`. Poll or webhook for it.
2. **`Authorization: Bearer <key>`.** Wrong header. Magnific uses `x-magnific-api-key`. A `Bearer` token yields `401`.
3. **Tight-polling a video/music job every 200ms.** Those run for minutes and you'll trip the rate limits (50 req/min). Use a webhook, or poll every few seconds.
4. **Assuming every response is `{ "data": { "status": … } }`.** Style Transfer returns `task_status` and is *not* wrapped in `data`; Remove Background returns image URLs synchronously with no task at all. Parse defensively (the `wait()` helper above does).
5. **Polling Remove Background for a `task_id`.** It's synchronous — there is no task. The returned URLs also **expire in 5 minutes**; download immediately.
6. **Putting the API key in a browser/mobile app.** Keys are server-to-server only. Proxy generation calls through your backend.
7. **Expecting LoRAs to apply to any Mystic config.** Mystic silently ignores LoRAs (no error) when using `fluid`/`flexible`/`super_real`/`editorial_portraits`, or whenever a `structure_reference`/`style_reference` is supplied.
8. **Trying to disable Mystic's NSFW filter.** `filter_nsfw:false` is rejected on standard accounts — only specially-authorized clients can turn it off.
9. **Skipping webhook signature verification** (or verifying against the parsed/re-serialized JSON). Verify the HMAC over the **raw** body, or you'll accept spoofed callbacks and reject legitimate ones.

## Rate limits

Documented limits (no `429`/limit-header names are published — back off on errors regardless):

- **50 requests/minute** overall.
- Burst: **50 hits/sec over a 5-second window**, and **10 hits/sec averaged over 2 minutes**.
- **1,000 requests/day** on `ai-image-to-prompt`, `ai-improve-prompt`, `ai-powered-search`.
- **100 requests/day** on Analytics endpoints (Business/Enterprise only; no credit cost).

## Pricing (credit model)

Usage is **credit-based**, deducted from the org balance per call. The web-app "Unlimited" plan **does not** cover API usage. Few per-call numbers are published; the ones the docs state: **Relight and Style Transfer ≈ €0.10/operation**; **upscales ≈ €0.10–€0.50** depending on output pixel area (input dims × scale factor). For image/video generation, cost scales with **resolution/megapixels** ("higher resolution = higher cost"). Treat any figure beyond those as "not documented — verify on the pricing page."

## MCP server

Magnific ships a hosted **Model Context Protocol** server at **`https://mcp.magnific.com`**, authenticated via **OAuth 2.0 (no API key)**. It lets an AI assistant (Claude, etc.) drive Magnific generation as tools. Use it for assistant-driven workflows; use the REST API above for programmatic/backend integration.

## Reference files

Exhaustive, verbatim per-endpoint detail (every parameter, enum, default, request/response example, and gotcha) for all ~60 endpoints:

- [`references/image-generation.md`](references/image-generation.md) — Mystic, Flux family, Seedream, Z-Image, Runway t2i
- [`references/image-editing.md`](references/image-editing.md) — Upscalers, Relight, Style Transfer, Remove BG, Expand
- [`references/video-generation.md`](references/video-generation.md) — Kling, MiniMax, WAN, Runway, LTX, Seedance, PixVerse, OmniHuman, VFX
- [`references/audio.md`](references/audio.md) — music, sound effects, audio isolation
- [`references/analytics-and-stock.md`](references/analytics-and-stock.md) — team analytics, stock resources/icons/videos

## Official docs

- Introduction & quickstart: https://docs.magnific.com/introduction · https://docs.magnific.com/quickstart
- Authentication: https://docs.magnific.com/authentication
- Webhooks: https://docs.magnific.com/webhooks
- Rate limits / Pricing: https://docs.magnific.com/ratelimits · https://docs.magnific.com/pricing
- MCP: https://docs.magnific.com/modelcontextprotocol
- Full markdown export (for LLMs): https://docs.magnific.com/llms-full.txt
