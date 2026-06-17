# Magnific API — Image Editing Reference

> Magnific's flagship upscalers (Creative & Precision) plus relight, style transfer, background removal, and image expand. All async submit→poll/webhook. See `foundations.md` for shared mechanics.

### Image Editing — Upscaler, Relight, Style Transfer, Remove Background, Expand

This family covers Magnific's pixel-level image-editing models. Use **Upscaler (Creative)** when you want to enlarge an image and let AI invent/infer new detail (prompt-guided, fidelity-vs-creativity controls); use **Upscaler (Precision)** when you want enlargement that stays faithful to the source (sharpen / grain / detail dials only, no creative reinterpretation). Reach for **Relight** to change scene lighting (via prompt, a reference image, or a lightmap), **Style Transfer** to repaint an image in the look of a reference, **Remove Background** for a fast synchronous cutout, and **Expand (Flux Pro)** to outpaint/extend an image's canvas in any direction. All except Remove Background are async (POST returns a `task_id`; poll the matching GET or supply `webhook_url`); Remove Background is synchronous and returns image URLs directly.

### Image Upscaler (Creative) — `POST /v1/ai/image-upscaler`
- **Purpose:** AI upscale with prompt-guided detail enhancement; can introduce/infer new detail (creative).
- **Submit/Status:** Submit — returns `task_id` (async; poll matching GET or use `webhook_url`).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string (base64) | Yes | — | Base64 image to upscale. The resulting image can't exceed the maximum allowed size of 25.3 million pixels. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that will receive asynchronous notifications whenever the task changes status. |
| `scale_factor` | string | No | `2x` | `2x`, `4x`, `8x`, `16x`. Higher scales take longer to process. |
| `optimized_for` | string | No | `standard` | `standard`, `soft_portraits`, `hard_portraits`, `art_n_illustration`, `videogame_assets`, `nature_n_landscapes`, `films_n_photography`, `3d_renders`, `science_fiction_n_horror`. Styles to optimize the upscale process. |
| `prompt` | string | No | — | Prompt to guide the upscale. Reusing the same prompt for AI-generated images improves results. |
| `creativity` | integer | No | `0` | Increase/decrease AI's creativity. Valid range `[-10, 10]`. |
| `hdr` | integer | No | `0` | Increase/decrease level of definition and detail. Valid range `[-10, 10]`. |
| `resemblance` | integer | No | `0` | Adjust resemblance to the original image. Valid range `[-10, 10]`. |
| `fractality` | integer | No | `0` | Control strength of the prompt and intricacy per square pixel. Valid range `[-10, 10]`. |
| `engine` | string | No | `automatic` | `automatic`, `magnific_illusio`, `magnific_sharpy`, `magnific_sparkle`. Magnific model engines. |
| `filter_nsfw` | boolean | No | `false` | Controls NSFW content filtering on the upscaled image. When `true`, output is scanned and filtered. |

- **Request:**
```json
{
  "image": "iVBORw0KGgoAAAANSUhEUgAAASwAAAEsAQAAAABRBrPYAAABrElEQVR4nO3BMQEAAADCoPVPbQ0Po...",
  "webhook_url": "https://httpbin.org/post",
  "scale_factor": "2x",
  "optimized_for": "standard",
  "prompt": "Crazy dog in the space",
  "creativity": 2,
  "hdr": 1,
  "resemblance": 0,
  "fractality": -1,
  "engine": "magnific_sparkle",
  "filter_nsfw": false
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
- **Credits:** Not documented on the spec page. (Pricing guidance elsewhere: cost is based on output image area in pixels — input dimensions × upscale factor — roughly €0.10–€0.50 per upscale.)
- **Gotchas:**
  - Output image must not exceed **25.3 million pixels** — pick `scale_factor` accordingly relative to input dimensions.
  - `creativity`, `hdr`, `resemblance`, `fractality` are all clamped to `[-10, 10]`.
  - Send the original via URL/base64 of the original file for max quality; canvas-derived data (`canvas.toDataURL()`) loses ~8–20% quality.
  - Status values: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### Image Upscaler (Precision) — `POST /v1/ai/image-upscaler-precision`
- **Purpose:** Faithful (non-creative) upscale; enhances sharpness/grain/detail without reinterpreting content.
- **Submit/Status:** Submit — returns `task_id` (async; poll matching GET or use `webhook_url`).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string (byte/base64) | Yes | — | Base64 image to upscale. |
| `webhook_url` | string (URI) | No | — | Webhook URL. |
| `sharpen` | integer | No | `50` | Sharpen the image. Min 0, Max 100. |
| `smart_grain` | integer | No | `7` | Smart grain. Min 0, Max 100. |
| `ultra_detail` | integer | No | `30` | Ultra detail. Min 0, Max 100. |
| `filter_nsfw` | boolean | No | `false` | Enable NSFW content filtering on the output image. |

- **Request:**
```json
{
  "image": "[base64-encoded-image]",
  "webhook_url": "https://example.com/webhook",
  "sharpen": 50,
  "smart_grain": 7,
  "ultra_detail": 30,
  "filter_nsfw": false
}
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED",
    "generated": [
      "https://openapi-generator.tech",
      "https://openapi-generator.tech"
    ]
  }
}
```
- **Credits:** Not documented on the spec page. (Same pixel-area pricing model as Creative upscaler; ~€0.10–€0.50 per upscale.)
- **Gotchas:**
  - `sharpen`, `smart_grain`, `ultra_detail` all clamped to `[0, 100]`.
  - Endpoint may modify original image content based on prompt and inferred context.
  - Status values: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### Image Relight — `POST /v1/ai/image-relight`
- **Purpose:** Re-light an image via a prompt, a reference image, or a lightmap.
- **Submit/Status:** Submit — returns `task_id` (async; poll matching GET or use `webhook_url`). GET status endpoints: `GET /v1/ai/image-relight/{task-id}` (single) and `GET /v1/ai/image-relight` (all tasks).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string | Yes | — | Base64 or URL of the image to relight. |
| `prompt` | string | No | — | Guides generation; use numbers 1–1.4 in parentheses to emphasize aspects, e.g. `(dark scene:1.3)`. |
| `transfer_light_from_reference_image` | string | No | — | Base64 or URL of the reference image for light transfer. Incompatible with `transfer_light_from_lightmap`. |
| `transfer_light_from_lightmap` | string | No | — | Base64 or URL of the lightmap for light transfer. Incompatible with `transfer_light_from_reference_image`. |
| `light_transfer_strength` | integer | No | `100` | Range `[0, 100]`; intensity of light transfer. |
| `interpolate_from_original` | boolean | No | `false` | Interpolates the final image from the original using the strength slider. |
| `change_background` | boolean | No | `true` | Alters background per prompt/reference; disable for landscapes/interiors. |
| `style` | string | No | `standard` | `standard`, `darker_but_realistic`, `clean`, `smooth`, `brighter`, `contrasted_n_hdr`, `just_composition`. Visual style preset. |
| `preserve_details` | boolean | No | `true` | Maintains texture and details; disable for smoother results. |
| `webhook_url` | string | No | — | Optional callback URL that will receive asynchronous notifications. |
| `advanced_settings` | object | No | — | Advanced controls (see nested table). |
| `advanced_settings.whites` | integer | No | `50` | Range `[0, 100]`. Adjust white color levels. |
| `advanced_settings.blacks` | integer | No | `50` | Range `[0, 100]`. Adjust black color levels. |
| `advanced_settings.brightness` | integer | No | `50` | Range `[0, 100]`. Brightness adjustment. |
| `advanced_settings.contrast` | integer | No | `50` | Range `[0, 100]`. Contrast adjustment. |
| `advanced_settings.saturation` | integer | No | `50` | Range `[0, 100]`. Saturation adjustment. |
| `advanced_settings.engine` | string | No | `automatic` | `automatic`, `balanced`, `cool`, `real`, `illusio`, `fairy`, `colorful_anime`, `hard_transform`, `softy`. |
| `advanced_settings.transfer_light_a` | string | No | `automatic` | `automatic`, `low`, `medium`, `normal`, `high`, `high_on_faces`. Adjusts light transfer intensity. |
| `advanced_settings.transfer_light_b` | string | No | `automatic` | `automatic`, `composition`, `straight`, `smooth_in`, `smooth_out`, `smooth_both`, `reverse_both`, `soft_in`, `soft_out`, `soft_mid`, `strong_mid`, `style_shift`, `strong_shift`. Modifies light transfer; can combine with `transfer_light_a`. |
| `advanced_settings.fixed_generation` | boolean | No | `false` | Using the same settings will consistently produce the same image. |

- **Request:**
```json
{
  "image": "iVBORw0KGgoAAAANSUhEUgAAASwAAAEsAQAAAABRBrPYAAABrElEQVR4nO3BMQEAAADCoPVPbQ0Po...",
  "prompt": "A sunlit forest clearing at golden hour",
  "transfer_light_from_reference_image": "iVBORw0KGgoAAAANSUhEUgAAASwAAAEsAQAAAABRBrPYAAABrElEQVR4nO3BMQEAAADCoPVPbQ0Po...",
  "light_transfer_strength": 100,
  "interpolate_from_original": false,
  "change_background": true,
  "style": "smooth",
  "preserve_details": true,
  "webhook_url": "https://www.example.com/webhook",
  "advanced_settings": {
    "whites": 60,
    "blacks": 60,
    "brightness": 30,
    "contrast": 40,
    "saturation": 50,
    "engine": "illusio",
    "transfer_light_a": "low",
    "transfer_light_b": "soft_in",
    "fixed_generation": true
  }
}
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED",
    "generated": [
      "https://openapi-generator.tech",
      "https://openapi-generator.tech"
    ]
  }
}
```
- **Credits:** Fixed cost of **€0.10 per operation**. (Spec page also notes some upscaler/premium endpoints require a premium API account.)
- **Gotchas:**
  - `transfer_light_from_reference_image` and `transfer_light_from_lightmap` are **mutually exclusive** — supply at most one.
  - Three light-transfer methods: prompt-based, reference image, or lightmap.
  - Disable `change_background` for landscapes/interiors to avoid unwanted alterations.
  - Prompt emphasis format `(descriptor:1.0–1.4)`.
  - `light_transfer_strength` and all `advanced_settings` numeric fields clamped to `[0, 100]`.
  - `fixed_generation: true` gives deterministic output for identical settings (useful for tuning).
  - Send original via URL for max quality; canvas-derived data loses ~8–20% quality.
  - Status values: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### Image Style Transfer — `POST /v1/ai/image-style-transfer`
- **Purpose:** Repaint an image in the artistic style of a reference image.
- **Submit/Status:** Submit — returns a task identifier (async; poll status or use `webhook_url`).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string | Yes | — | Base64 or URL of the image to do the style transfer. |
| `reference_image` | string | Yes | — | Base64 or URL of the reference image for style transfer. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that will receive asynchronous notifications. |
| `prompt` | string | No | — | Prompt for the AI model. |
| `style_strength` | integer | No | `100` | Range `0–100`. Percentage of style strength. |
| `structure_strength` | integer | No | `50` | Range `0–100`. Maintains the structure of the original image. |
| `is_portrait` | boolean | No | `false` | Indicates whether the image should be processed as a portrait. |
| `portrait_style` | string | No | `standard` | `standard`, `pop`, `super_pop`. Visual style applied to portrait images. |
| `portrait_beautifier` | string | No | — | `beautify_face`, `beautify_face_max`. Enables facial beautification on portrait images. |
| `flavor` | string | No | `faithful` | `faithful`, `gen_z`, `psychedelia`, `detaily`, `clear`, `donotstyle`, `donotstyle_sharp`. Flavor of the transferring style. |
| `engine` | string | No | `balanced` | `balanced`, `definio`, `illusio`, `3d_cartoon`, `colorful_anime`, `caricature`, `real`, `super_real`, `softy`. Magnific model engines. |
| `fixed_generation` | boolean | No | `false` | When enabled, using the same settings will consistently produce the same image. |

- **Request:**
```json
{
  "image": "iVBORw0KGgoAAAANSUhEUgAA...",
  "reference_image": "iVBORw0KGgoAAAANSUhEUgAA...",
  "webhook_url": "https://my-webhook-url.com/endpoint",
  "prompt": "Transform the image into a modern artistic style",
  "style_strength": 85,
  "structure_strength": 60,
  "is_portrait": true,
  "portrait_style": "pop",
  "portrait_beautifier": "beautify_face_max",
  "flavor": "gen_z",
  "engine": "colorful_anime",
  "fixed_generation": true
}
```
- **Response:**
```json
{
  "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
  "task_status": "IN_PROGRESS",
  "generated": [
    "https://openapi-generator.tech",
    "https://openapi-generator.tech"
  ]
}
```
- **Credits:** Fixed cost of **€0.10 per operation**.
- **Gotchas:**
  - Both `image` and `reference_image` are required.
  - `style_strength` and `structure_strength` clamped to `0–100`.
  - `portrait_style`/`portrait_beautifier` only meaningful when `is_portrait: true`.
  - `fixed_generation: true` for deterministic output.
  - Note: this endpoint's documented response uses `task_status` (not `status`) and is not wrapped in a `data` object in the example — differs from the other endpoints' `{"data": {..., "status": ...}}` shape; treat both shapes defensively.
  - Send original via URL for max quality; canvas-derived data loses ~8–20% quality.
  - Status values: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`. HTTP errors: 400, 401, 500, 503.

### Remove Background (Beta) — `POST /v1/ai/beta/remove-background`
- **Purpose:** Remove the background from an image (cutout).
- **Submit/Status:** **Synchronous** — returns image URLs directly (no `task_id`, no polling/webhook).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image_url` | string (URI) | Yes | — | The URL of the image whose background needs to be removed. Content-Type: `application/x-www-form-urlencoded`. |

- **Request:**
```json
{
  "image_url": "https://img.freepik.com/free-vector/cute-cat-sitting-cartoon-vector-icon-illustration-animal-nature-icon-concept-isolated-premium-vector-flat-cartoon-style_138676-4148.jpg?w=2000&t=st=1725353998~exp=1725357598~hmac=a17f90afeeff454b36c0715f84eed2b388cd9c4a7ce59fcdff075fa41770e469"
}
```
- **Response:**
```json
{
  "original": "https://api.magnific.com/v1/ai/beta/images/original/037ea4ea-e8ad84a8c7/thumbnail.jpg",
  "high_resolution": "https://api.magnific.com/v1/ai/beta/images/download/037ead-44cd8ad84a8c7/high.png",
  "preview": "https://api.magnific.com/v1/ai/beta/images/download/037ea4eacad84a8c7/preview.png",
  "url": "https://api.magnific.com/v1/ai/beta/images/download/037ea4ea-720d-411e8ad84a8c7/high.png"
}
```
- **Credits:** Not documented.
- **Gotchas:**
  - Beta endpoint (`/beta/` in the path). Request body is form-encoded (`application/x-www-form-urlencoded`), not JSON, despite the JSON-style example.
  - Supported input formats: **JPG, PNG**; max file size **20 MB**.
  - Output resolutions: Preview up to **0.25 megapixels**, Full resolution up to **25 megapixels**.
  - Response URLs are **temporary — valid for 5 minutes only**; download immediately.
  - Synchronous, so it does not follow the family's task_id/webhook async model.

### Image Expand (Flux Pro) — `POST /v1/ai/image-expand/flux-pro`
- **Purpose:** Outpaint / extend an image's canvas in any direction (left/right/top/bottom).
- **Submit/Status:** Submit — returns `task_id` (async; poll matching GET or use `webhook_url`).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string (base64) | Yes | — | Base64 image to expand. |
| `prompt` | string | No | — | Description of the changes you want; guides the expansion process. |
| `left` | integer | No | — | Pixels to expand on the left. Min 0, Max 2048. |
| `right` | integer | No | — | Pixels to expand on the right. Min 0, Max 2048. |
| `top` | integer | No | — | Pixels to expand on the top. Min 0, Max 2048. |
| `bottom` | integer | No | — | Pixels to expand on the bottom. Min 0, Max 2048. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that will receive asynchronous notifications. Payload is the same as the GET endpoint response but without the `data` field. |

- **Request:**
```json
{
  "image": "iVBORw0KGgoAAAANSUhEUgAA...",
  "prompt": "A wide desert landscape at sunset",
  "left": 256,
  "right": 256,
  "top": 0,
  "bottom": 512,
  "webhook_url": "https://www.example.com/webhook"
}
```
*(Note: the docs page did not show an explicit request example; the above is assembled from the documented parameters — the parameter names/values are verbatim.)*
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
- **Credits:** Not documented.
- **Gotchas:**
  - `left`, `right`, `top`, `bottom` are nullable integers, each `0–2048` px; set only the sides you want to extend.
  - Webhook payload mirrors the GET-status response but **without** the outer `data` field.
  - Status values: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

