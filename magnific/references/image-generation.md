# Magnific API — Image Generation Reference

> Every text-to-image and image-editing-via-generation model. All are async submit→poll/webhook tasks under the shared base URL `https://api.magnific.com/v1` with the `x-magnific-api-key` header. See `foundations.md` for the async model, auth, webhooks, rate limits, and pricing.

### Foundations — Mystic Image Generation

The Mystic family is Magnific's flagship text-to-image generation model, exposed as async tasks under `/v1/ai/mystic`. Use the POST endpoint to submit a generation (optionally steered by structure/style reference images, `@character` mentions, styles, characters, and color palettes), then either poll the per-task GET endpoint or supply a `webhook_url` for the result. Pick a `model`/`engine` pair by intent: `realism`/`super_real` for photoreal output, `zen`/`fluid` for smoother illustration-friendly results, and `editorial_portraits` for hyperrealistic portraits.

### Submit Mystic Generation — `POST /v1/ai/mystic`
- **Purpose:** Generate AI image(s) from a prompt with optional structure/style references, characters, styles, and color steering.
- **Submit/Status:** Submit — returns a `task_id` (async task model). Poll `GET /v1/ai/mystic/{task-id}` or receive results via `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | No | — | Short text describing the image. Supports `@character_name` and `@character_name::strength` syntax (e.g. `@john::200`). |
| `webhook_url` | uri | No | — | Optional callback URL that receives asynchronous notifications whenever the task changes status. |
| `structure_reference` | byte | No | — | Base64 image to use as structure reference (controls shape/structure). |
| `structure_strength` | integer | No | 50 | 0–100. Maintains structure of original image; only effective when `structure_reference` is provided. |
| `style_reference` | byte | No | — | Base64 image to use as style reference (aesthetic influence). |
| `adherence` | integer | No | 50 | 0–100. Higher = generation more faithful to the prompt. |
| `hdr` | integer | No | 50 | 0–100. Higher = more detailed image, at the cost of a more "AI look". |
| `resolution` | string | No | `2k` | `1k`, `2k`, `4k`. |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `classic_4_3`, `traditional_3_4`, `widescreen_16_9`, `social_story_9_16`, `smartphone_horizontal_20_9`, `smartphone_vertical_9_20`, `standard_3_2`, `portrait_2_3`, `horizontal_2_1`, `vertical_1_2`, `social_5_4`, `social_post_4_5`. |
| `model` | string | No | `realism` | `zen` (smoother), `flexible` (HDR/saturated), `fluid` (best adherence), `realism` (realistic palette), `super_real` (priority realism), `editorial_portraits` (hyperrealistic portraits). |
| `creative_detailing` | integer | No | 33 | 0–100. Detail per pixel; higher = more detail but more HDR/artificial look. |
| `engine` | string | No | `automatic` | `automatic`, `magnific_illusio` (smoother illustrations), `magnific_sharpy` (sharpest/realistic), `magnific_sparkle` (middle ground). |
| `fixed_generation` | boolean | No | `false` | When true, the same settings consistently produce the same image. |
| `filter_nsfw` | boolean | No | `true` | NSFW filtering; cannot be disabled for standard API usage (only authorized clients with special permissions can disable it). |
| `styling` | object | No | — | Container for `styles`, `characters`, and `colors`. |
| `styling.styles` | array | No | — | Max 1 item. Each: `name` (style name) + `strength` (0–200, default 100). |
| `styling.characters` | array | No | — | Max 1 item. Each: `id` (character id) + `strength` (0–200, default 100). |
| `styling.colors` | array | No | — | 1–5 items. Each: `color` (hex `#[0-9A-F]{6}`) + `weight` (0.05–1). |

- **Request:**
```json
{
  "prompt": "My friend @john::200 is a great artist with wings",
  "webhook_url": "https://www.example.com/webhook",
  "structure_reference": "base64-encoded-image-bytes",
  "structure_strength": 50,
  "style_reference": "base64-encoded-image-bytes",
  "adherence": 50,
  "hdr": 50,
  "resolution": "2k",
  "aspect_ratio": "square_1_1",
  "model": "realism",
  "creative_detailing": 33,
  "engine": "automatic",
  "fixed_generation": false,
  "filter_nsfw": true,
  "styling": {
    "styles": [
      {
        "name": "style_name",
        "strength": 100
      }
    ],
    "characters": [
      {
        "id": "character_id",
        "strength": 100
      }
    ],
    "colors": [
      {
        "color": "#FF0000",
        "weight": 0.5
      }
    ]
  }
}
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS",
    "generated": []
  }
}
```
- **Credits:** Not documented on the pricing page (generic credit model: every generation call deducts credits from the org balance; "Unlimited" plan allowances cover only the web app, not the API). No per-model or per-resolution number published for Mystic.
- **Gotchas:**
  - **LoRAs are silently ignored (no error)** when: using `fluid`, `flexible`, `super_real`, or `editorial_portraits` models; OR when `structure_reference` and/or `style_reference` is provided (either or both).
  - **NSFW filter cannot be disabled** for standard API usage; only authorized clients with special permissions can set `filter_nsfw: false`.
  - Array limits: `styling.styles` max 1, `styling.characters` max 1, `styling.colors` 1–5.
  - Color weight must be 0.05–1.0; hex format `#[0-9A-F]{6}` required.
  - Character/style strength range is 0–200 (default 100).
  - `fluid` model only supports aspect ratios: `square_1_1`, `social_story_9_16`, `widescreen_16_9`, `traditional_3_4`, `classic_4_3`.
  - `structure_strength` (and structure/style steering) only takes effect when the matching reference image is supplied.
  - Set up a `webhook_url` on every request to reliably retrieve generations (otherwise you must poll).
  - Auth header `x-magnific-api-key` is required (server-to-server only). Errors: 400 invalid params, 401 missing/invalid key, 500 internal error, 503 service unavailable.

### Get Mystic Task — `GET /v1/ai/mystic/{task-id}`
- **Purpose:** Retrieve the status and results of a single Mystic generation task.
- **Submit/Status:** Status/GET (polling endpoint for the task returned by the POST).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `task-id` | string | Yes | — | Path parameter. ID (UUID) of the task. |

- **Request:** No request body. Auth via `x-magnific-api-key` header.
- **Response:**
```json
{
  "data": {
    "generated": [
      "https://ai-statics.freepik.com/completed_task_image.jpg"
    ],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "COMPLETED",
    "has_nsfw": [false]
  }
}
```
In-progress example:
```json
{
  "data": {
    "generated": [],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** Not documented (status reads are not described as consuming credits).
- **Gotchas:**
  - Response fields: `task_id` (string/UUID), `status` (enum `CREATED` | `IN_PROGRESS` | `COMPLETED` | `FAILED`), `generated` (array of image URLs), `has_nsfw` (optional array of per-image NSFW flags, one boolean per generated image).
  - `generated` is an empty array until the task reaches `COMPLETED`.
  - Auth header `x-magnific-api-key` required. Errors: 400 invalid params, 401 missing/invalid key, 500 internal error, 503 service unavailable.

### List Mystic Tasks — `GET /v1/ai/mystic`
- **Purpose:** List Mystic generation tasks and their current statuses.
- **Submit/Status:** Status/GET (collection listing).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| _(none documented)_ | — | — | — | No query parameters documented. Auth via `x-magnific-api-key` header. |

- **Request:** No request body. Auth via `x-magnific-api-key` header.
- **Response:**
```json
{
  "data": [
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
      "status": "IN_PROGRESS"
    },
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee92",
      "status": "COMPLETED"
    },
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee93",
      "status": "COMPLETED"
    },
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee93",
      "status": "CREATED"
    }
  ]
}
```
- **Credits:** Not documented.
- **Gotchas:**
  - `data` is a flat array of `{task_id, status}` objects; status enum is `CREATED` | `IN_PROGRESS` | `COMPLETED` | `FAILED`.
  - No pagination/filter parameters are documented.
  - Auth header `x-magnific-api-key` required. Possible 500 (Internal Server Error) / 503 (Service Unavailable) responses.

> **Note on a related endpoint:** the Mystic API reference index also lists `GET /v1/ai/loras` (LoRA listing) alongside the three Mystic endpoints above. Its full parameter/response spec was not retrievable from the crawled pages, but its existence is relevant because LoRAs interact with Mystic's `model`/`structure_reference`/`style_reference` LoRA-ignore rules noted above.

> **Family-wide gotchas / shared facts confirmed by the crawl:** Base URL `https://api.magnific.com/v1`; auth header `x-magnific-api-key: YOUR_API_KEY` (server-to-server only). Async task model and `CREATED|IN_PROGRESS|COMPLETED|FAILED` status enum are confirmed verbatim. Rate limits seen elsewhere in the docs (not Mystic-specific): 50 RPM; 50 hits/sec over a 5-second period; 10 hits/sec averaged over a 2-minute period; 1,000 RPD on `ai-image-to-prompt`, `ai-improve-prompt`, `ai-powered-search`; 100 RPD on Analytics endpoints (Business/Enterprise only, no credit consumption). No rate-limit header names or 429-equivalent status code are documented. MCP server (`https://mcp.magnific.com`, OAuth 2.0, no API key) can drive Mystic image generation from an AI assistant. The webhook signature scheme (Svix-style: `webhook-id`/`webhook-timestamp`/`webhook-signature`, HMAC-SHA256 over `id.timestamp.body`, base64) is a shared fact — the Mystic pages themselves only mention `webhook_url` as the callback target.

---

## Flux / HyperFlux / Runway Text-to-Image Family

These endpoints submit asynchronous text-to-image (and image-to-image / image-editing) generation tasks on the Magnific platform. All return `{"data": {"task_id": ..., "status": ...}}` and resolve either by polling the matching `GET .../{task-id}` endpoint or via a supplied `webhook_url` (Svix-style HMAC-SHA256). Pick **Flux 2 Pro** for high-fidelity, multi-image-conditioned generation up to 1440px; **Flux 2 Turbo** for fast generation with explicit safety toggling and square output up to 2048px; **Flux 2 Klein** for aspect-ratio + 1k/2k resolution control with up to 4 reference images; **Flux Pro v1.1** for the prior-gen production model with fine safety tolerance (0–6); **Flux Dev** / **HyperFlux** when you want rich `styling` (effects + dominant-color palette) and HyperFlux specifically for the fastest/cheapest path; **Flux Kontext Pro** for guidance/steps-tunable reference-image-guided edits; and **Runway** when you need Runway's fixed pixel-dimension `ratio` set.

### Flux Kontext Pro — `POST /v1/ai/text-to-image/flux-kontext-pro`
- **Purpose:** Reference-image-guided generation/editing with explicit guidance + step control.
- **Submit/Status:** Submit (returns `task_id`). Status via `GET /v1/ai/text-to-image/flux-kontext-pro/{task-id}`; list via `GET /v1/ai/text-to-image/flux-kontext-pro`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image to generate |
| `input_image` | string | No | — | URL to a reference image for guided generation |
| `prompt_upsampling` | boolean | No | `false` | Enable automatic prompt modification for creative results |
| `seed` | integer | No | random | Seed for reproducible generation |
| `guidance` | number | No | `3.0` | Guidance scale (1–10); higher follows prompt more closely |
| `steps` | integer | No | `50` | Inference steps (1–100); more steps = higher quality |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `classic_4_3`, `traditional_3_4`, `widescreen_16_9`, `social_story_9_16`, `standard_3_2` |

- **Request:**
```json
(no request example published on page)
```
- **Response:**
```json
(no response example published on page; family-standard shape:)
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - `guidance` constrained to 1–10; `steps` constrained to 1–100.
  - `input_image` is a **URL** here (unlike Flux 2 Pro / Klein, which take base64).
  - Fewer aspect-ratio options than the other Flux endpoints (no `portrait_2_3`, `horizontal_2_1`, `vertical_1_2`, `social_post_4_5`).

### Flux 2 Pro — `POST /v1/ai/text-to-image/flux-2-pro`
- **Purpose:** High-fidelity generation, image-to-image, and multi-image (up to 4) conditioned generation/editing.
- **Submit/Status:** Submit (returns `task_id`). Resolve by polling or `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image you want to generate. |
| `width` | integer | No | `1024` | Width in pixels. Valid range: 256 to 1440 pixels |
| `height` | integer | No | `768` | Height in pixels. Valid range: 256 to 1440 pixels |
| `seed` | integer | No | Random | Reproducible results. Valid range: 0 to 4,294,967,295 |
| `prompt_upsampling` | boolean | No | `false` | Automatically enhance and expand your prompt for better generation results. |
| `input_image` | string | No | `null` | Base64-encoded input image for image-to-image or editing. Formats: JPEG, PNG, WebP |
| `input_image_2` | string | No | `null` | Second base64-encoded input image for multi-image generation. |
| `input_image_3` | string | No | `null` | Third base64-encoded input image for multi-image generation. |
| `input_image_4` | string | No | `null` | Fourth base64-encoded input image for multi-image generation. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications on status change. |

- **Request:**
```json
{
  "prompt": "a futuristic cityscape at night with neon lights reflecting on wet streets, cyberpunk aesthetic, dramatic lighting, highly detailed",
  "width": 1440,
  "height": 768,
  "seed": 42,
  "prompt_upsampling": false,
  "webhook_url": "https://your-app.com/webhooks/flux-2-pro"
}
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** "Total megapixels affect generation cost. Higher resolution = higher cost." (no fixed per-call number)
- **Gotchas:**
  - Up to **4 input images** via `input_image` … `input_image_4`; all are **base64** (not URLs).
  - `input_image` formats: JPEG, PNG, WebP.
  - HTTP error codes: 400, 401, 500, 503.

### Flux 2 Turbo — `POST /v1/ai/text-to-image/flux-2-turbo`
- **Purpose:** Fast generation with explicit safety filtering toggle and custom square/rect dimensions up to 2048px.
- **Submit/Status:** Submit (returns `task_id`). Resolve by polling or `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image you want to generate. |
| `guidance_scale` | number | No | `2.5` | Range 1.0–20.0. Low (1–3) = creative freedom; Medium (3–7) = balanced; High (7–20) = strict adherence. |
| `seed` | integer | No | Random | Range 0–4,294,967,295. Reproducible results. |
| `image_size` | object | No | `1024×1024` | Object with `width` and `height` (512–2048 pixels each). |
| `enable_safety_checker` | boolean | No | `true` | Enable content safety filtering (NSFW, violence, etc.). |
| `output_format` | string | No | `png` | `jpeg`, `png`. PNG = lossless; JPEG = lossy. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications. |

- **Request:**
```json
{
  "prompt": "portrait of a smiling person, natural lighting, soft focus background, professional photography",
  "guidance_scale": 3.5,
  "seed": 12345,
  "image_size": {
    "width": 1024,
    "height": 1024
  },
  "enable_safety_checker": true,
  "output_format": "png",
  "webhook_url": "https://your-app.com/webhooks/flux-2-turbo"
}
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** "Total resolution affects cost and generation time." (no fixed per-call number)
- **Gotchas:**
  - `image_size` is an **object** (`{width, height}`), each dimension 512–2048px — different shape from Flux 2 Pro's flat `width`/`height`.
  - **NSFW filter:** `enable_safety_checker` filters NSFW/violence when `true`; disabling requires compliance with terms.
  - No query parameters documented.

### Flux 2 Klein — `POST /v1/ai/text-to-image/flux-2-klein`
- **Purpose:** Aspect-ratio + 1k/2k resolution generation with up to 4 reference images for style transfer.
- **Submit/Status:** Submit (returns `task_id`). Status via `GET /v1/ai/text-to-image/flux-2-klein/{task-id}`; list via `GET /v1/ai/text-to-image/flux-2-klein`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image to generate |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `widescreen_16_9`, `social_story_9_16`, `portrait_2_3`, `traditional_3_4`, `vertical_1_2`, `horizontal_2_1`, `social_post_4_5`, `standard_3_2`, `classic_4_3` |
| `resolution` | string | No | `1k` | `1k` (standard), `2k` (high resolution) |
| `seed` | integer | No | random | Range 0–4,294,967,295 |
| `input_image` | string | No | — | Base64-encoded reference image for style transfer |
| `input_image_2` | string | No | — | Second reference image |
| `input_image_3` | string | No | — | Third reference image |
| `input_image_4` | string | No | — | Fourth reference image |
| `safety_tolerance` | integer | No | `2` | Range 0–5. Content moderation: 0 (strict) to 5 (lenient) |
| `output_format` | string | No | — | `png`, `jpeg` |
| `webhook_url` | string | No | — | URL for completion notification |

- **Request:**
```json
(no request example published on page)
```
- **Response:**
```json
(no response example published on page; family-standard shape:)
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented (rate-limit/pricing pages referenced separately)
- **Gotchas:**
  - Up to **4 reference images** (`input_image` … `input_image_4`), base64-encoded.
  - `resolution: 2k` is capped at 2048px.
  - `safety_tolerance` range here is **0–5** (note: Flux Pro v1.1 uses 0–6).

### Flux Pro v1.1 — `POST /v1/ai/text-to-image/flux-pro-v1-1`
- **Purpose:** Prior-generation production text-to-image with fine-grained safety tolerance.
- **Submit/Status:** Submit (returns `task_id`). Resolve by polling or `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | The prompt to use for image generation. |
| `prompt_upsampling` | boolean | No | `false` | If active, automatically modifies the prompt for more creative generation. |
| `seed` | integer | No | `null` | Optional seed for reproducibility; random if omitted. |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `classic_4_3`, `traditional_3_4`, `widescreen_16_9`, `social_story_9_16`, `standard_3_2`, `portrait_2_3`, `horizontal_2_1`, `vertical_1_2`, `social_post_4_5` |
| `safety_tolerance` | integer | No | `2` | Range 0–6. 0 = most strict, 6 = least strict (input + output moderation). |
| `output_format` | string | No | `null` | `jpeg`, `png` |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications on status change. |

- **Request:**
```json
(no request example published on page)
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - `safety_tolerance` range is **0–6** (wider than Flux 2 Klein's 0–5).
  - Auth header `x-magnific-api-key` required; errors 400, 401, 500, 503.

### Flux Dev — `POST /v1/ai/text-to-image/flux-dev`
- **Purpose:** Development model supporting rich `styling` (effects + dominant-color palette); prompt is optional.
- **Submit/Status:** Submit (returns `task_id`). Resolve by polling or `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | No | — | Short text describing the image. If omitted, a random image is generated. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications on status change. |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `classic_4_3`, `traditional_3_4`, `widescreen_16_9`, `social_story_9_16`, `standard_3_2`, `portrait_2_3`, `horizontal_2_1`, `vertical_1_2`, `social_post_4_5` |
| `styling` | object | No | — | Styling options containing `effects` and `colors` |
| `styling.effects.color` | string | No | — | `softhue`, `b&w`, `goldglow`, `vibrant`, `coldneon` |
| `styling.effects.framing` | string | No | — | `portrait`, `lowangle`, `midshot`, `wideshot`, `tiltshot`, `aerial` |
| `styling.effects.lightning` | string | No | — | `iridescent`, `dramatic`, `goldenhour`, `longexposure`, `indorlight`, `flash`, `neon` |
| `styling.colors` | array | No | — | Dominant colors (1–5 items max) |
| `styling.colors[].color` | string | Yes (if in array) | — | Hex color code; pattern `^#[0-9A-F]{6}$` |
| `styling.colors[].weight` | number | Yes (if in array) | — | Range 0.05–1 |
| `seed` | integer | No | — | Range 1–4294967295 |

- **Request:**
```json
(no request example published on page)
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - `styling.colors` array: min 1, **max 5** items; each item requires both `color` (hex, uppercase `^#[0-9A-F]{6}$`) and `weight` (0.05–1).
  - `seed` range here starts at **1** (1–4294967295), not 0.
  - Effect key is spelled `lightning` (not "lighting") in the API — copy exactly.

### HyperFlux — `POST /v1/ai/text-to-image/hyperflux`
- **Purpose:** Fastest/cheapest Flux variant; same `styling` palette + effects model as Flux Dev; prompt optional.
- **Submit/Status:** Submit (returns `task_id`; response also carries a `generated` array). Resolve by polling or `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | No | — | Short text describing the image (e.g. `"a cat"`). |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications on status change. |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `classic_4_3`, `traditional_3_4`, `widescreen_16_9`, `social_story_9_16`, `standard_3_2`, `portrait_2_3`, `horizontal_2_1`, `vertical_1_2`, `social_post_4_5` |
| `styling` | object | No | — | Styling options for the image |
| `styling.effects.color` | string | No | — | `softhue`, `b&w`, `goldglow`, `vibrant`, `coldneon` |
| `styling.effects.framing` | string | No | — | `portrait`, `lowangle`, `midshot`, `wideshot`, `tiltshot`, `aerial` |
| `styling.effects.lightning` | string | No | — | `iridescent`, `dramatic`, `goldenhour`, `longexposure`, `indorlight`, `flash`, `neon` |
| `styling.colors` | array | No | — | Dominant colors (1–5 items); each requires `color` (hex) and `weight` (0.05–1) |
| `seed` | integer | No | — | Range 1–4294967295 |

- **Request:**
```json
(no request example published on page)
```
- **Response:**
```json
{
  "data": {
    "generated": [],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
  Completed:
```json
{
  "data": {
    "generated": ["https://ai-statics.freepik.com/completed_task_image.jpg"],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "COMPLETED"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - Response includes a `generated` array (empty at `CREATED`, populated with result URL(s) at `COMPLETED`) — distinct from the bare Flux 2 / Pro v1.1 response shape.
  - `styling.colors` array: min 1, **max 5**; effect key spelled `lightning`.
  - `seed` range 1–4294967295 (starts at 1).

### Runway (Text-to-Image) — `POST /v1/ai/text-to-image/runway`
- **Purpose:** Runway-backed text-to-image with a fixed set of pixel-dimension ratios.
- **Submit/Status:** Submit (returns `task_id`, with `generated` array). Resolve by polling or `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text prompt describing the desired image (1–1000 chars). |
| `ratio` | string | Yes | — | `1920:1080`, `1080:1920`, `1024:1024`, `1360:768`, `1080:1080`, `1168:880`, `1440:1080`, `1080:1440`, `1808:768`, `2112:912`, `1280:720`, `720:1280`, `720:720`, `960:720`, `720:960`, `1680:720` |
| `seed` | integer | No | — | Range 0–4294967295. Reproducibility. |
| `webhook_url` | string (URI) | No | — | Optional callback URL for async notifications. |

- **Request:**
```json
{
  "prompt": "A serene mountain landscape at sunset with golden light",
  "ratio": "1920:1080",
  "seed": 12345,
  "webhook_url": "https://www.example.com/webhook"
}
```
- **Response:**
```json
{
  "data": {
    "generated": [
      "https://openapi-generator.tech",
      "https://openapi-generator.tech"
    ],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - `ratio` is **required** and uses literal pixel `width:height` strings (not the `square_1_1`-style names used by every other Flux endpoint) — wrong vocabulary will be rejected.
  - `prompt` is **required** and bounded to 1–1000 characters.
  - Response `status` shown as `IN_PROGRESS` in the example (vs `CREATED` elsewhere); `generated` array carries result URLs.

---

### Image-Gen: Seedream + Z-Image (family)

This family covers Magnific's ByteDance Seedream text-to-image and image-editing models plus the fast Z-Image Turbo generator. Pick **Seedream 4** for baseline text-to-image with a simple aspect-ratio/guidance interface; pick **Seedream 4.5** when you need higher fidelity (up to 4MP), strong text/typography rendering, and an explicit safety toggle; pick **Seedream 4.5 Edit** when you have 1–5 reference images to edit while preserving subject detail, lighting, and color; pick **Z-Image Turbo** for the fastest prototyping/iteration (8-step turbo) with PNG/JPEG output control. All four are async: a POST returns a `task_id`, and you either poll the matching `GET .../{task-id}` endpoint or supply `webhook_url` to receive the Svix-style signed result. Auth is `x-magnific-api-key` (server-to-server only); usage is credit-based.

### Seedream 4 — Create image — `POST /v1/ai/text-to-image/seedream-v4`
- **Purpose:** Generate an image from a text prompt with the Seedream 4 model.
- **Submit/Status:** Submit — returns a `task_id`. Companion endpoints: `GET /v1/ai/text-to-image/seedream-v4/{task-id}` (task status + results) and `GET /v1/ai/text-to-image/seedream-v4` (list all tasks).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image to generate |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `widescreen_16_9`, `social_story_9_16`, `portrait_2_3`, `traditional_3_4`, `standard_3_2`, `classic_4_3` |
| `guidance_scale` | number | No | `2.5` | 0–20. Controls prompt adherence; higher values follow the prompt more closely |
| `seed` | integer | No | — | 0–2,147,483,647. Random seed for reproducible results |
| `webhook_url` | string | No | — | Callback URL for async task status notifications |

- **Request:**
```json
(no request example shown on the docs page)
```
- **Response:**
```json
(no response example shown on the docs page; per the shared async model, returns {"data": {"task_id": "<uuid>", "status": "CREATED|IN_PROGRESS|COMPLETED|FAILED", ...}})
```
- **Credits:** not documented
- **Gotchas:**
  - Async workflow: must poll the GET task-status endpoint or use a webhook.
  - `seed` max here is 2,147,483,647 (smaller than the 4294967295 range used by the v4.5 endpoints).
  - No safety-checker toggle exposed on this endpoint (unlike v4.5).
  - Production-ready outputs; extreme resolutions may benefit from upscaling.

### Seedream 4.5 — Create image from text — `POST /v1/ai/text-to-image/seedream-v4-5`
- **Purpose:** Generate a high-fidelity image (up to 4MP) from text, with strong text/typography rendering.
- **Submit/Status:** Submit — returns a `task_id` with `status`. Poll the matching GET status endpoint or use a webhook.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image you want to generate. Max length 4096 |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `widescreen_16_9`, `social_story_9_16`, `portrait_2_3`, `traditional_3_4`, `standard_3_2`, `classic_4_3`, `cinematic_21_9`. Seedream 4.5 supports up to 4MP resolution |
| `seed` | integer | No | — | 0–4294967295. Same seed + identical params produces similar results |
| `enable_safety_checker` | boolean | No | `true` | When enabled, the model filters potentially unsafe content |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications whenever the task changes status |

- **Request:**
```json
{
  "prompt": "Professional marketing poster for a tech startup, minimalist design, bold sans-serif typography, gradient blue background, high contrast",
  "aspect_ratio": "widescreen_16_9",
  "seed": 12345,
  "enable_safety_checker": true,
  "webhook_url": "https://your-app.com/webhooks/seedream-v4-5"
}
```
- **Response:**
```json
{
  "data": {
    "generated": [
      "https://openapi-generator.tech",
      "https://openapi-generator.tech"
    ],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - Max prompt length is 4096 characters.
  - Resolution up to 4MP (2048×2048 for square); `cinematic_21_9` ≈ 3062×1312.
  - `enable_safety_checker` defaults to `true` — disable explicitly if you need unfiltered output.
  - Adds `cinematic_21_9` over the Seedream 4 aspect-ratio set; has no `guidance_scale` param (unlike Seedream 4).
  - Webhook payload mirrors the GET response but without the `data` wrapper field.

### Seedream 4.5 Edit — Edit image — `POST /v1/ai/text-to-image/seedream-v4-5-edit`
- **Purpose:** Edit/transform 1–5 reference images with text guidance, preserving subject details, lighting, and color tone (up to 4MP output).
- **Submit/Status:** Submit — returns a `task_id` with `status`. Poll the matching GET status endpoint or use a webhook.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image you want to generate. Max 4096 characters |
| `reference_images` | array | Yes | — | Array of reference images for image editing. Min 1, max 5 items. Accepts Base64-encoded strings or publicly accessible URLs. Min resolution 256×256 px; max 10MB per image; supported formats JPG, JPEG, PNG |
| `aspect_ratio` | string | No | `square_1_1` | `square_1_1`, `widescreen_16_9`, `social_story_9_16`, `portrait_2_3`, `traditional_3_4`, `standard_3_2`, `classic_4_3`, `cinematic_21_9`. Seedream 4.5 supports up to 4MP resolution |
| `seed` | integer | No | — | 0–4294967295. Random seed for reproducibility |
| `webhook_url` | string | No | — | Optional callback URL that receives async notifications whenever the task changes status |
| `enable_safety_checker` | boolean | No | `true` | Whether to enable the content safety checker |

- **Request:**
```json
(no request example shown on the docs page; body requires "prompt" and a "reference_images" array of 1–5 Base64 strings or public URLs)
```
- **Response:**
```json
{
  "data": {
    "generated": [],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - `reference_images` is required: must contain at least 1 and at most 5 images.
  - Each reference image: min 256×256 px, max 10MB, formats JPG/JPEG/PNG only; supplied as Base64-encoded strings or publicly accessible URLs.
  - Preserves subject details, lighting, and color tone when editing.
  - Output up to 4MP resolution.
  - `enable_safety_checker` defaults to `true`.

### Z-Image Turbo — Create image from text — `POST /v1/ai/text-to-image/z-image`
- **Purpose:** Fast (turbo, 8-step) text-to-image generation; best for rapid prototyping and iteration.
- **Submit/Status:** Submit — returns a `task_id` with `status`. Poll the matching GET status endpoint or use a webhook.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text description of the image you want to generate. Be specific about visual details, composition, and style. Max 4096 characters |
| `image_size` | string | No | `square_hd` | `square` (512×512), `square_hd` (1024×1024), `portrait_3_4` (768×1024), `portrait_9_16` (576×1024), `landscape_4_3` (1024×768), `landscape_16_9` (1024×576). Defaults to `square_hd` (1024×1024) |
| `num_inference_steps` | integer | No | `8` | 1–50. For Z-Image turbo, 8 steps is recommended for optimal speed/quality balance |
| `seed` | integer | No | — | 0–4294967295. Same seed + identical params produces the same image |
| `output_format` | string | No | `png` | `jpeg`, `png`. PNG is lossless, best for images with text or sharp edges |
| `enable_safety_checker` | boolean | No | `true` | When enabled, the model filters potentially unsafe content |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications whenever the task changes status |

- **Request:**
```json
{
  "prompt": "A cyberpunk city street at night, neon signs reflecting on wet pavement, flying cars in the distance, highly detailed, cinematic lighting",
  "image_size": "square_hd",
  "num_inference_steps": 8,
  "seed": 42,
  "output_format": "png",
  "enable_safety_checker": true,
  "webhook_url": "https://your-app.com/webhooks/z-image"
}
```
- **Response:**
```json
{
  "data": {
    "generated": [],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - Uses `image_size` (its own enum) rather than the Seedream `aspect_ratio` enum — do not mix the two vocabularies.
  - Default 8 inference steps is the recommended turbo setting; raising toward 50 trades speed for quality.
  - `output_format` defaults to `png` (lossless, best for text/sharp edges); use `jpeg` for smaller files.
  - Docs note the model "supports LoRA and ControlNet variants," but the documented request body for this endpoint exposes no LoRA/ControlNet parameters.
  - `enable_safety_checker` defaults to `true`.
  - Max prompt length 4096 characters.

