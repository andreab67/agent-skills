# Magnific API — Video Generation Reference

> Every text-to-video and image-to-video model. All are async submit→poll/webhook tasks. Video tasks take longer than image tasks — always use a `webhook_url` in production rather than tight polling. See `foundations.md` for shared mechanics.

## Video: Kling Family

Magnific's Kling family wraps Kuaishou's Kling video models behind the standard async task API: every POST returns a `task_id` you then poll (or receive via `webhook_url`). Pick **Kling 2.1 Pro** when you need motion-brush control (static/dynamic masks, trajectories) or first+last-frame (`image_tail`) interpolation; **Kling 2.5 Pro** for the simplest high-quality image-to-video with no audio; **Kling 2.6 Pro** when you want native audio generation (`generate_audio`) and a unified text-or-image request; **Kling O1 Pro** for first-frame→last-frame interpolation or multi-image reference-consistency (up to 7 reference images); and **Kling 2.6 Motion Control (Pro/Std)** to transfer motion from a reference video onto a character image. All are submit-and-poll; Pro variants support only `5s`/`10s` outputs.

### Kling 2.1 Pro — Create video from image — `POST /v1/ai/image-to-video/kling-v2-1-pro`
- **Purpose:** Generate a video from an image (or text) using Kling 2.1 Pro, with optional motion-brush masks and end-frame control.
- **Submit/Status:** Submit — returns `{ "data": { "task_id", "status" } }`. Poll `GET /v1/ai/image-to-video/kling-v2-1/{task-id}` (summary "Kling 2.1 - Get task status"); list via `GET /v1/ai/image-to-video/kling-v2-1-pro`.
- **Parameters:** (request schema `itvkv2-1-pro-request-content`, title "Image to Video")

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string | No* | — | Reference Image. Base64 or publicly-accessible URL. ≤10MB, ≥300x300px, aspect ratio 1:2.5 ~ 2.5:1. |
| `image_tail` | string | No | — | Reference Image – End frame control. Base64 or public URL, same format rules as `image`. **Not compatible with standard mode.** Formats .jpg/.jpeg/.png; ≤10MB; ≥300x300px. At least one of `image`/`image_tail` must be filled — cannot both be empty. |
| `prompt` | string | No* | — | `Required when image is not provided`. Text prompt describing the desired motion, ≤2500 characters. |
| `negative_prompt` | string | No | — | Text prompt describing what to avoid, ≤2500 characters. |
| `duration` | string | **Yes** | — | enum: `"5"`, `"10"` (seconds). |
| `cfg_scale` | number (float) | No | `0.5` | min 0, max 1. Higher value = lower flexibility, stronger relevance to prompt. |
| `static_mask` | string | No | — | Static mask image for motion-brush areas. Base64 or public URL (same format rules as `image`); .jpg/.jpeg/.png. Aspect ratio MUST match `image` or the task fails. Resolution must be identical to `dynamic_masks.mask` images or task fails. |
| `dynamic_masks` | array | No | — | Items of `{ mask (string, required), trajectories (array of {x:int (required), y:int (required)}, required) }`. `mask`: Base64 or URL, .jpg/.jpeg/.png, aspect ratio must match `image`, resolution must match `static_mask`. `trajectories` = Motion Trajectory Coordinate Sequence (x = horizontal/X, y = vertical/Y, 2D pixel system). |
| `webhook_url` | string (uri) | No | — | Optional callback URL; receives async notifications on status change. Payload = the GET endpoint response **without the `data` field**. e.g. `https://www.example.com/webhook`. |

\* Either `image` or `prompt` must be provided; only `duration` is formally `required`.

- **Request:**
```json
{
  "image": "https://example.com/source.jpg",
  "prompt": "Camera slowly pans across the scene",
  "duration": "5",
  "cfg_scale": 0.5,
  "webhook_url": "https://www.example.com/webhook"
}
```
- **Response:** (200, schema `create_image_from_text_flux_200_response` → `task`)
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented (no credit/cost field in the spec).
- **Gotchas:**
  - `duration` is the only formally-required field; values are **strings** `"5"`/`"10"`, not integers.
  - At least one of `image` / `image_tail` must be present; `prompt` becomes required only when `image` is omitted.
  - `image_tail` is **not compatible with standard mode**.
  - Motion-brush masks are strict: `static_mask`/`dynamic_masks.mask` aspect ratio must match `image`, and `static_mask` resolution must equal `dynamic_masks.mask` resolution, or the task fails.
  - `task.status` enum: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`. Completed task adds `generated` (array of result URLs).

### Kling 2.5 Pro — Create video from image — `POST /v1/ai/image-to-video/kling-v2-5-pro`
- **Purpose:** Generate a video from an image using Kling 2.5 Turbo Pro (production-grade cinematic quality; audio not yet supported).
- **Submit/Status:** Submit — returns `task_id`. Poll `GET /v1/ai/image-to-video/kling-v2-5-pro/{task-id}` ("Kling 2.5 Pro - Get task status"); list via `GET /v1/ai/image-to-video/kling-v2-5-pro`.
- **Parameters:** (request schema `itvkv2-5-pro-request-content`, title "Image to Video")

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string | No | — | Reference Image. Base64 or publicly-accessible URL. ≤10MB, ≥300x300px, aspect ratio 1:2.5 ~ 2.5:1. |
| `prompt` | string | No | — | Text prompt describing the desired motion, ≤2500 characters. |
| `negative_prompt` | string | No | — | Text prompt describing what to avoid, ≤2500 characters. |
| `duration` | string | **Yes** | — | enum: `"5"`, `"10"` (seconds). |
| `cfg_scale` | number (float) | No | `0.5` | min 0, max 1. Higher = lower flexibility, stronger relevance to prompt. |
| `webhook_url` | string (uri) | No | — | Optional callback URL; payload = GET response without `data`. e.g. `https://www.example.com/webhook`. |

- **Request:**
```json
{
  "image": "https://example.com/source.jpg",
  "prompt": "Gentle zoom into the subject with bokeh effect",
  "duration": "5",
  "cfg_scale": 0.5,
  "webhook_url": "https://www.example.com/webhook"
}
```
- **Response:** (200, schema `create_image_from_text_flux_200_response` → `task`)
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented.
- **Gotchas:**
  - No mask / `image_tail` / `aspect_ratio` parameters — simpler surface than 2.1 Pro.
  - **Audio is not supported** (planned for a future upgrade) — no `generate_audio` field.
  - Only `duration` is required; supports `"5"`/`"10"` only (strings).
  - Status enum: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`; completed adds `generated[]`.

### Kling 2.6 Pro — Create video (text or image) — `POST /v1/ai/image-to-video/kling-v2-6-pro`
- **Purpose:** Generate a video from text **or** an image using Kling 2.6 Pro, with optional native audio generation.
- **Submit/Status:** Submit — returns `task_id`. Poll `GET /v1/ai/image-to-video/kling-v2-6/{task-id}`; list via `GET /v1/ai/image-to-video/kling-v2-6-pro` ("Kling 2.6 Pro - List tasks").
- **Parameters:** request body is `anyOf` two schemas. `aspect_ratio` enum is shared (`kling-v26-aspect-ratio`, default `widescreen_16_9`).

  **Text-to-Video** (`kling-request-v26-text-to-video`):

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | **Yes** | — | Text prompt describing the desired video, ≤2500 chars (`maxLength: 2500`). |
| `negative_prompt` | string | No | — | What to avoid, ≤2500 chars. |
| `cfg_scale` | number (float) | No | `0.5` | min 0, max 1. Higher = lower flexibility. |
| `aspect_ratio` | string | No | `widescreen_16_9` | enum: `widescreen_16_9`, `social_story_9_16`, `square_1_1`. |
| `duration` | string | **Yes** | — | enum: `"5"`, `"10"`. |
| `generate_audio` | boolean | No | — | Whether to generate audio for the video. |
| `webhook_url` | string (uri) | No | — | Webhook URL to notify when the task is completed. |

  **Image-to-Video** (`kling-request-v26-image-to-video`):

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string (byte) | **Yes** | — | Reference Image. Base64 or public URL. ≤10MB, ≥300x300px, aspect ratio 1:2.5 ~ 2.5:1. |
| `prompt` | string | No | — | Desired motion in the video, ≤2500 chars. |
| `negative_prompt` | string | No | — | What to avoid, ≤2500 chars. |
| `cfg_scale` | number (float) | No | `0.5` | min 0, max 1. |
| `aspect_ratio` | string | No | `widescreen_16_9` | enum: `widescreen_16_9`, `social_story_9_16`, `square_1_1`. |
| `duration` | string | **Yes** | — | enum: `"5"`, `"10"`. |
| `generate_audio` | boolean | No | — | Whether to generate audio. |
| `webhook_url` | string (uri) | No | — | Webhook URL to notify when the task is completed. |

- **Request:** (image-to-video variant)
```json
{
  "image": "https://example.com/source.jpg",
  "prompt": "Person walks toward the camera with soft wind blowing",
  "duration": "5",
  "aspect_ratio": "widescreen_16_9",
  "cfg_scale": 0.5,
  "generate_audio": true,
  "webhook_url": "https://www.example.com/webhook"
}
```
- **Response:** (200, schema `get_style_transfer_task_status_200_response` → `task-detail`)
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
- **Credits:** not documented.
- **Gotchas:**
  - Body is `anyOf` text-to-video **or** image-to-video — required fields differ: text mode requires `prompt` + `duration`; image mode requires `image` + `duration`.
  - Unlike 2.1/2.5, `duration` is still string `"5"`/`"10"`, and `aspect_ratio` uses the named enum values `widescreen_16_9` / `social_story_9_16` / `square_1_1` (not `16:9` style).
  - `generate_audio` is unique to 2.6 (native audio).
  - In image mode the `aspect_ratio` is accepted in the schema but, per the family pattern, only meaningfully applies when no image constrains it.
  - Status enum: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### Kling O1 Pro — Image-to-video (first/last frame) — `POST /v1/ai/image-to-video/kling-o1-pro`
- **Purpose:** Generate video with Kling O1 using first-frame→last-frame interpolation (smooth transitions / controlled start-end animation). (`kling-o1-std` is the Standard-tier sibling at `POST /v1/ai/image-to-video/kling-o1-std`.)
- **Submit/Status:** Submit — returns `task_id`. Poll `GET /v1/ai/image-to-video/kling-o1/{task-id}` ("Kling O1 - Get task status"); list via `GET /v1/ai/image-to-video/kling-o1` ("Kling O1 - List tasks").
- **Parameters:** (request schema `itvko1-image-to-video-request`, title "Kling O1 Image to Video")

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | No | — | Text prompt describing desired motion. `maxLength: 2500`. Examples: "Camera slowly pans across the landscape"; "Person walks toward the camera with soft wind blowing"; "Gentle zoom into the subject with bokeh effect". |
| `first_frame` | string | No* | — | First frame (start). URL (publicly accessible) or Base64. ≥300x300px, ≤10MB. e.g. `https://example.com/start-image.jpg`. |
| `last_frame` | string | No* | — | Last frame (end). URL (publicly accessible) or Base64. e.g. `https://example.com/end-image.jpg`. |
| `aspect_ratio` | string | No | `16:9` | enum: `16:9` (Widescreen), `9:16` (Vertical), `1:1` (Square). |
| `duration` | integer | No | `5` | enum: `5`, `10` (seconds). |
| `webhook_url` | string (uri) | No | — | Optional callback URL; payload = GET response without `data`. e.g. `https://www.example.com/webhook`. |

\* No field is formally `required`, but per the schema description you should provide **at least one** of `first_frame` / `last_frame` (both, with similar compositions, for best results).

- **Request:**
```json
{
  "prompt": "Gentle zoom into the subject with bokeh effect",
  "first_frame": "https://example.com/start-image.jpg",
  "last_frame": "https://example.com/end-image.jpg",
  "aspect_ratio": "16:9",
  "duration": 5,
  "webhook_url": "https://www.example.com/webhook"
}
```
- **Response:** (200, schema `task-detail-200-default-response`: "OK - The task exists and the status is returned"; follows the standard `{ "data": { "task_id", "status", ... } }` task model)
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented.
- **Gotchas:**
  - **`duration` here is an integer** (`5`/`10`) and **`aspect_ratio` uses `16:9`/`9:16`/`1:1`** — different conventions from the v2.x Pro models (string duration, `widescreen_16_9` enum). Don't reuse the same payload shape across families.
  - Provide at least one of `first_frame`/`last_frame`; both with similar compositions gives best results.
  - Sibling endpoint `POST /v1/ai/image-to-video/kling-o1-pro-video-reference` (schema `itvko1-video-reference-request`, title "Kling O1 Video Reference") instead takes `reference_images` (array of URL/Base64, **maxItems 7**, `prompt` **required**, plus the same `aspect_ratio`/`duration`/`webhook_url`) for character/style consistency.
  - Status enum: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### Kling 2.6 Motion Control (Pro) — `POST /v1/ai/video/kling-v2-6-motion-control-pro`
- **Purpose:** Transfer motion from a reference video onto a character/reference image using Kling 2.6 Pro — preserves the character's appearance while applying the video's motion patterns. (Standard tier: `POST /v1/ai/video/kling-v2-6-motion-control-std`, schema identical, summary "Kling 2.6 Standard - Motion control video".)
- **Submit/Status:** Submit — returns the standard task response (`task-detail-200-default-response`). No dedicated motion task-by-id GET in the spec — use `webhook_url` for completion (the generic task/status model applies).
- **Parameters:** (request schema `motion-control-request`, shared by Pro and Std)

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image_url` | string (uri) | **Yes** | — | URL of the character/reference image; motion is transferred onto this character. Publicly accessible URL only. ≥300x300px, ≤10MB. Formats: JPG, JPEG, PNG, WEBP. |
| `video_url` | string (uri) | **Yes** | — | URL of the reference video containing the motion. Publicly accessible URL only. Duration **3–30 seconds**. Formats: MP4, MOV, WEBM, M4V. |
| `prompt` | string | No | — | Optional text prompt to guide motion transfer. ≤2500 chars (`maxLength: 2500`). |
| `character_orientation` | string | No | `video` | enum: `video`, `image`. `video` = orientation matches reference video, better for complex motions, **max output 30s**. `image` = orientation matches reference image, better for following camera movements, **max output 10s**. |
| `cfg_scale` | number (float) | No | `0.5` | min 0, max 1. CFG scale — higher = stronger prompt adherence, less flexibility. |
| `webhook_url` | string (uri) | No | — | Webhook URL to notify on completion; server POSTs the task result to this URL. |

- **Request:**
```json
{
  "image_url": "https://example.com/character.jpg",
  "video_url": "https://example.com/motion-reference.mp4",
  "prompt": "Apply the dancing motion to the character",
  "character_orientation": "video",
  "cfg_scale": 0.5,
  "webhook_url": "https://www.example.com/webhook"
}
```
- **Response:** (200, schema `task-detail-200-default-response`; standard task model)
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "CREATED"
  }
}
```
- **Credits:** not documented.
- **Gotchas:**
  - Lives under `/v1/ai/video/...` (NOT `/v1/ai/image-to-video/...`) — different path prefix from the rest of the family.
  - `image_url` and `video_url` are **both required and must be public URLs** (no Base64 noted for the video; image requirements list URL only).
  - Reference video duration must be **3–30s**; output duration cap depends on `character_orientation` (`video` → 30s, `image` → 10s).
  - Pro and Std share the exact same request schema; choose the tier via the endpoint path.
  - Status enum: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

---

## Video — MiniMax & WAN

These endpoints generate short 1080p video clips on Magnific's async task model: each `POST` returns a `task_id` you then poll (matching `GET`) or receive via `webhook_url`. The **MiniMax / Hailuo** models are tuned for image-to-video (animate a first/last keyframe) and accept a `prompt_optimizer`; pick **Hailuo 02** or **Hailuo 2.3** for photographic first/last-frame interpolation (both also support a text-to-video schema), and **MiniMax Video 01 Live** when animating illustrations/artwork with bracketed camera-move directives. The **WAN** models cover both text-to-video (`wan-2-5-t2v-1080p`) and image-to-video (`wan-2-5-i2v-1080p`, `wan-v2-6-1080p`); pick **WAN 2.6** when you need explicit `size`/aspect-ratio control, multi-shot composition, or longer 10–15s durations.

### MiniMax Hailuo 02 1080p — `POST /v1/ai/image-to-video/minimax-hailuo-02-1080p`
- **Purpose:** Generate a 1080p video from a first (and optional last) keyframe image, or from text only.
- **Submit/Status:** Submit — returns `task_id`. Poll `GET /v1/ai/image-to-video/minimax-hailuo-02-1080p` / `...-task`, or supply `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Description of the video. Max 2000 chars. |
| `first_frame_image` | string | Yes (image-to-video mode) | — | URL or base64 encoding. JPG/JPEG/PNG; aspect ratio 2:5 to 5:2; shorter side >300px; ≤20MB. Used as first frame. |
| `last_frame_image` | string | No | — | URL or base64 encoding, same specs as `first_frame_image`. Used as last frame. |
| `duration` | integer | No | `6` | enum: `[6]` — Video length in seconds (1080P only supports 6 seconds). |
| `prompt_optimizer` | boolean | No | `true` | Whether to use the prompt optimizer. If true, the model automatically optimizes the incoming prompt. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications whenever the task changes status. |

- **Request:**
```json
{
  "prompt": "A beautiful sunset over the mountains with birds flying in the sky",
  "first_frame_image": "https://img.freepik.com/free-photo/beautiful-sunset-over-mountains_123456-7890.jpg",
  "duration": 6,
  "prompt_optimizer": true
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
- **Credits:** not documented
- **Gotchas:**
  - `duration` is locked to `6` (the only enum value) for the 1080p tier.
  - Image constraints: JPG/JPEG/PNG only; aspect ratio between 2:5 and 5:2; shorter side >300px; file ≤20MB.
  - `prompt` ≤ 2000 characters.
  - Two schemas: image-to-video (requires `first_frame_image`) and text-to-video (prompt + duration only).

### MiniMax Hailuo 2.3 1080p — `POST /v1/ai/image-to-video/minimax-hailuo-2-3-1080p`
- **Purpose:** Newer Hailuo generation producing a 1080p video from a first/last keyframe, or from text only.
- **Submit/Status:** Submit — returns `task_id`. Poll `GET /v1/ai/image-to-video/minimax-hailuo-2-3-1080p` / `...-task`, or supply `webhook_url`.
- **Parameters:** (request is `oneOf` two schemas)

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Description of the video. Note: It should be less than 2000 characters. |
| `first_frame_image` | string | Yes (image-to-video schema) | — | URL of the image or base64 encoding; used as the first frame. JPG/JPEG/PNG; aspect ratio 2:5 to 5:2; shorter side ≥300px; ≤20MB. |
| `last_frame_image` | string | No | — | Image (URL or base64) used as the last frame. |
| `duration` | integer | No | `6` | enum: `[6]` — Video length in seconds (1080P only supports 6 seconds). |
| `prompt_optimizer` | boolean | No | `true` | Whether to use the prompt optimizer. |
| `webhook_url` | string | No | — | Optional callback URL that receives async notifications whenever the task changes status. |

- **Request:**
```json
{
  "prompt": "Description of the video",
  "first_frame_image": "https://example.com/first-frame.jpg",
  "last_frame_image": "https://example.com/last-frame.jpg",
  "duration": 6,
  "prompt_optimizer": true,
  "webhook_url": "https://www.example.com/webhook"
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
- **Credits:** not documented
- **Gotchas:**
  - `duration` enum is `[6]` only for the 1080p tier.
  - Image specs: JPG/JPEG/PNG; aspect ratio 2:5 to 5:2; min shorter side 300px; max 20MB.
  - `prompt` must be < 2000 characters.
  - Two request schemas: image-to-video (`itvminimax23-1080p-request-content`, requires `first_frame_image`) and text-to-video (`ttvminimax23-1080p-request-content`, prompt + duration only).
  - A `-fast` variant exists at `minimax-hailuo-2-3-1080p-fast` (separate endpoint, not documented here).

### MiniMax Video 01 Live — `POST /v1/ai/image-to-video/minimax-live`
- **Purpose:** Animate a still image (best with illustrations/artwork) into video, with bracketed camera-move directives in the prompt.
- **Submit/Status:** Submit — returns `task_id`. Status via the minimax-live task endpoints (`minimax-live-tasks`, `minimax-live/task-by-id`), or supply `webhook_url`. Note: doc's sample response shows a `COMPLETED` payload including a `generated` URL array.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image_url` | string (URI) | Yes | — | URL of the source image to animate. Works best with illustrations and artwork. |
| `prompt` | string | Yes | — | Text description of the video motion. Max 2000 characters. Supports camera movements in square brackets: `[Truck left]`, `[Truck right]`, `[Pan left]`, `[Pan right]`, `[Push in]`, `[Pull out]`, `[Pedestal up]`, `[Pedestal down]`, `[Tilt up]`, `[Tilt down]`, `[Zoom in]`, `[Zoom out]`, `[Shake]`, `[Tracking shot]`, `[Static shot]`. |
| `prompt_optimizer` | boolean | No | `true` | Enable automatic prompt enhancement for better video generation results. |
| `webhook_url` | string (URI) | No | — | Webhook URL to notify when the task is completed. |

- **Request:**
```json
{
  "image_url": "https://example.com/illustration.jpg",
  "prompt": "The illustration comes to life with gentle movements [Static shot]",
  "prompt_optimizer": true,
  "webhook_url": "https://example.com/webhook"
}
```
- **Response:**
```json
{
  "data": {
    "generated": [
      "https://ai-statics.freepik.com/completed_task_image.jpg"
    ],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "COMPLETED"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - Lives at slug `minimax-live` (NOT `minimax-video-01-live`); the `/overview` path 404s.
  - Uses `image_url` (not `first_frame_image`); no `last_frame_image` and no `duration` parameter.
  - "Works best with illustrations and artwork"; `prompt` max 2000 chars.
  - Camera moves are expressed inline in the prompt via bracketed tokens (exact set above).

### WAN 2.5 Text-to-Video 1080p — `POST /v1/ai/text-to-video/wan-2-5-t2v-1080p`
- **Purpose:** Generate a 1080p video from a text prompt only (no input image).
- **Submit/Status:** Submit — returns `task_id`. Poll the matching `GET` task-status endpoint, or supply `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Main description of the video — scene, characters, motion, camera moves, style. Max 800 chars. |
| `duration` | string | No | `'5'` | `'5'`, `'10'` — Video length in seconds. |
| `negative_prompt` | string | No | — | Elements to avoid in generation. Max 500 chars. |
| `enable_prompt_expansion` | boolean | No | `true` | Enable AI prompt optimizer to expand shorter prompts into detailed scripts. |
| `seed` | integer | No | — | Random seed for reproducibility. Range 0–2147483647. |
| `webhook_url` | string | No | — | Optional callback URL that receives async notifications whenever the task changes status. |

- **Request:**
```json
{
  "prompt": "A serene mountain landscape at golden hour with mist rising from the valley",
  "duration": "5",
  "negative_prompt": "blurry, low quality, watermark",
  "enable_prompt_expansion": true,
  "seed": 12345,
  "webhook_url": "https://www.example.com/webhook"
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
- **Credits:** not documented
- **Gotchas:**
  - `duration` is a **string** (`'5'` or `'10'`), not an integer.
  - `prompt` max 800 chars; `negative_prompt` max 500 chars (tighter than the MiniMax 2000-char limit).
  - `enable_prompt_expansion` defaults to `true` here (vs `false` on WAN 2.6).
  - `seed` range 0–2147483647 (no `-1`-for-random sentinel documented, unlike WAN 2.6).

### WAN 2.5 Image-to-Video 1080p — `POST /v1/ai/image-to-video/wan-2-5-i2v-1080p`
- **Purpose:** Animate a keyframe/base image into a 1080p video guided by a text prompt.
- **Submit/Status:** Submit — returns `task_id`. Poll the matching `GET` task-status endpoint, or supply `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string (URL) | Yes | — | URL of the keyframe or base image to animate. Must be publicly accessible. JPEG/PNG/WebP; 240–8000px per dimension; max 10MB. |
| `prompt` | string | Yes | — | Main description of the video — scene, characters, motion, camera moves, style. Max 800 chars. |
| `duration` | string | No | `'5'` | `'5'`, `'10'` — Video length in seconds. |
| `negative_prompt` | string | No | — | Things to avoid in the generated video. Max 500 chars. |
| `enable_prompt_expansion` | boolean | No | `true` | AI prompt optimizer for expanding shorter prompts. |
| `seed` | integer | No | — | Random seed for reproducibility. Range 0–2147483647. |
| `webhook_url` | string (URI) | No | — | Optional callback URL for async status notifications. |

- **Request:**
```json
{
  "image": "https://example.com/image.jpg",
  "prompt": "A serene mountain landscape at golden hour with mist rising from the valley",
  "duration": "5",
  "negative_prompt": "blurry, low quality, watermark",
  "enable_prompt_expansion": true,
  "seed": 12345,
  "webhook_url": "https://www.example.com/webhook"
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
- **Credits:** not documented
- **Gotchas:**
  - Input param is `image` (not `image_url` / `first_frame_image`).
  - Image: JPEG/PNG/WebP; 240–8000px per dimension; max 10MB; must be publicly accessible.
  - `duration` is a string (`'5'`/`'10'`); `prompt` ≤ 800, `negative_prompt` ≤ 500 chars.
  - `enable_prompt_expansion` defaults to `true`.

### WAN v2.6 Image-to-Video 1080p — `POST /v1/ai/image-to-video/wan-v2-6-1080p`
- **Purpose:** Animate a keyframe/base image into a 1080p video with explicit size/aspect-ratio, multi-shot, and longer duration control.
- **Submit/Status:** Submit — returns `task_id`. Poll the matching `GET` task-status endpoint, or supply `webhook_url`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string (URI) | Yes | — | URL of the keyframe or base image to animate. Must be publicly accessible. JPEG/PNG/WebP; 240–8000px per dimension; max 10MB. |
| `prompt` | string | Yes | — | Main description of the video — scene, characters, motion, camera moves, style. Max 2000 chars. |
| `size` | string | No | `1920*1080` | `1920*1080` (16:9), `1080*1920` (9:16), `1440*1440` (1:1), `1632*1248` (4:3), `1248*1632` (3:4) — Video size for the 1080p tier. |
| `duration` | string | No | `5` | `5`, `10`, `15` — Video duration in seconds. |
| `negative_prompt` | string | No | — | Things to avoid in the generated video. Max 1000 chars. |
| `enable_prompt_expansion` | boolean | No | `false` | Enable AI prompt optimizer to expand shorter prompts. |
| `shot_type` | string | No | `single` | `single`, `multi` — Shot composition type. `multi` requires prompt expansion enabled. |
| `seed` | integer | No | `-1` | Range -1 to 2147483647; `-1` for random. |
| `webhook_url` | string (URI) | No | — | Optional callback URL for asynchronous task notifications. |

- **Request:**
```json
{
  "image": "https://example.com/image.jpg",
  "prompt": "Main description of the video - scene, characters, motion, camera moves, style",
  "size": "1920*1080",
  "duration": "5",
  "negative_prompt": "blurry, low quality, watermark",
  "enable_prompt_expansion": false,
  "shot_type": "single",
  "seed": -1,
  "webhook_url": "https://www.example.com/webhook"
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
- **Credits:** not documented
- **Gotchas:**
  - Lives at slug `wan-v2-6-1080p` (note `v2-6`, not `2-6`); page has no `/overview` subpath.
  - `shot_type: multi` requires `enable_prompt_expansion: true` (mutually dependent).
  - `size` dimensions use a `WIDTH*HEIGHT` string with `*` (not `x`); five allowed values map to 16:9 / 9:16 / 1:1 / 4:3 / 3:4.
  - Longer durations than WAN 2.5: `5`, `10`, or `15` seconds (string-typed).
  - `prompt` ≤ 2000 chars, `negative_prompt` ≤ 1000 chars (looser than WAN 2.5's 800/500).
  - `enable_prompt_expansion` defaults to `false` here (opposite of WAN 2.5).
  - `seed` accepts `-1` (default) for random; image must be JPEG/PNG/WebP, 240–8000px per side, ≤10MB.

---

## Video: Runway + LTX + Seedance + PixVerse + OmniHuman + VFX

This family covers Magnific's video-generation and video-post-processing models. Use **Runway Gen4 Turbo** for fast image-to-video, **Runway Act Two** for character-consistent performance transfer (drive a still/clip with a reference performance video), **LTX 2.0 Pro** for pure text-to-video with optional synchronized audio, **Seedance Pro 1080p** for ByteDance image-to-video, **PixVerse V5** for stylized creative image-to-video (anime/3D/clay/etc.), **OmniHuman 1.5** for audio-driven talking-human animation, and **VFX** for applying classic film/lens effects to an existing video. All follow the shared async task model — a POST returns `{"data": {"task_id", "status", "generated": [...]}}`, and you either poll the matching GET or supply `webhook_url`. Auth is `x-magnific-api-key` (server-to-server). All POST paths live under `/v1/ai/...`.

### Runway Gen4 Turbo — `POST /v1/ai/image-to-video/runway-gen4-turbo`
- **Purpose:** Fast image-to-video generation from a reference image.
- **Submit/Status:** Submit — returns `task_id`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image` | string | Yes | — | Reference image. Supports Base64 encoding or HTTPS URL (must be publicly accessible). |
| `prompt` | string | No | — | Text prompt describing what should appear in the video (1-1000 characters). |
| `duration` | integer | No | `10` | Enum: `5`, `10`. Duration of the generated video in seconds. |
| `ratio` | string | No | `'1280:720'` | Enum: `'1280:720'`, `'720:1280'`, `'1104:832'`, `'832:1104'`, `'960:960'`, `'1584:672'`. Aspect ratio (width:height). |
| `seed` | integer | No | — | Random seed for reproducibility (min: 0, max: 4294967295). |
| `webhook_url` | string | No | — | Webhook URL to notify the user when the task is completed. |

- **Request:**
```json
{
  "image": "https://example.com/image.jpg",
  "prompt": "string",
  "duration": 10,
  "ratio": "1280:720",
  "seed": 0,
  "webhook_url": "https://example.com/webhook"
}
```
- **Response:**
```json
{
  "data": {
    "generated": [
      "https://ai-statics.freepik.com/completed_task_image.jpg"
    ],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "COMPLETED"
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - `prompt` limited to 1-1000 characters.
  - `duration` only accepts `5` or `10` seconds.
  - `image` must be publicly accessible if using an HTTPS URL (Base64 also accepted).
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### Runway Act Two — `POST /v1/ai/video/runway-act-two`
- **Purpose:** Character-consistent video — drive a character image/video with a reference performance video.
- **Submit/Status:** Submit — returns `task_id`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `character` | object | Yes | — | The character to control. A visually recognizable face must be visible. |
| `character.type` | string | Yes | — | Enum: `video`, `image`. Type of character input. |
| `character.uri` | string (URI) | Yes | — | URL to character video/image (publicly accessible). |
| `reference` | object | Yes | — | Reference video of a person performing the desired actions. |
| `reference.type` | string | Yes | — | Enum: `video`. Must be `'video'`. |
| `reference.uri` | string (URI) | Yes | — | URL to the reference performance video (3-30 seconds). |
| `ratio` | string | No | `1280:720` | Enum: `1280:720`, `720:1280`, `1104:832`, `832:1104`, `960:960`, `1584:672`. Aspect ratio (width:height). |
| `body_control` | boolean | No | `true` | Enable body control for non-facial movements and gestures. |
| `expression_intensity` | integer | No | `3` | Range `1`-`5`. Intensity of character's expressions. |
| `seed` | integer | No | — | Range `0`-`4294967295`. Random seed for reproducibility. |
| `webhook_url` | string (URI) | No | — | Webhook URL to notify the user when the task is completed. |

- **Request:**
```json
{
  "character": {
    "type": "image",
    "uri": "https://example.com/character.jpg"
  },
  "reference": {
    "type": "video",
    "uri": "https://example.com/reference.mp4"
  },
  "ratio": "1280:720",
  "body_control": true,
  "expression_intensity": 3
}
```
- **Response:**
```json
{
  "data": {
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "COMPLETED",
    "generated": [
      "https://ai-statics.freepik.com/completed_task_image.jpg"
    ]
  }
}
```
- **Credits:** not documented
- **Gotchas:**
  - `reference.uri` video must be 3-30 seconds; `reference.type` must be `video`.
  - A visually recognizable face must be visible in the character input.
  - All URIs must be publicly accessible.
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### LTX 2.0 Pro — `POST /v1/ai/text-to-video/ltx-2-pro`
- **Purpose:** Text-to-video generation with optional synchronized audio.
- **Submit/Status:** Submit — returns `task_id`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Text prompt describing the desired video content. Max 2000 chars. Tips: be specific about scenes/subjects/visual details; describe motion and camera movements; mention lighting and atmosphere. |
| `generate_audio` | boolean | No | `false` | Whether to generate synchronized audio for the video. |
| `seed` | integer | No | — | Range `0`-`4294967295`. Random seed for reproducibility. Same seed + identical params → similar results. |
| `resolution` | string | No | `1080p` | Enum: `1080p`, `1440p`, `2160p`. Video resolution. |
| `duration` | integer | No | `6` | Enum: `6`, `8`, `10`. Video duration in seconds (Pro model supports 6, 8, or 10). |
| `fps` | integer | No | `25` | Enum: `25`, `50`. Frames per second. 50 FPS only available for durations up to 10 seconds. |
| `webhook_url` | string (URI) | No | — | Webhook URL to notify when the task is completed. |

- **Request:**
```json
{
  "prompt": "A majestic eagle soaring through mountain valleys at sunset",
  "generate_audio": false,
  "seed": 12345,
  "resolution": "1080p",
  "duration": 6,
  "fps": 25,
  "webhook_url": "https://example.com/webhook"
}
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
- **Credits:** not documented
- **Gotchas:**
  - `fps` of `50` is only available for durations up to 10 seconds.
  - `prompt` max length 2000 characters.
  - `duration` strictly limited to `6`, `8`, or `10` seconds for the Pro model.
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### Seedance Pro 1080p — `POST /v1/ai/image-to-video/seedance-pro-1080p`
- **Purpose:** ByteDance image-to-video model at 1080p.
- **Submit/Status:** Submit — returns `task_id` (per family convention).
- **Parameters:** NOT RETRIEVABLE. The documentation page listed in the official `llms.txt` index (`/api-reference/image-to-video/seedance-pro-1080p/post-seedance-pro-1080p`) returns **HTTP 404** at every variant probed (indexed slug, bare directory, `/overview`, `/get-...`, and multiple model-name permutations), and Magnific exposes no OpenAPI spec at any standard path. The page is unpublished/broken upstream. The endpoint path above is inferred from the index entry plus the consistent `POST /v1/ai/image-to-video/<model-slug>` pattern used by every other image-to-video model in this API; **the parameter list, request/response examples, and credit cost could not be verified and must be confirmed once Magnific republishes the page.**
- **Request:** not retrievable (page 404)
- **Response:** not retrievable (page 404)
- **Credits:** not documented (page 404)
- **Gotchas:**
  - Doc page 404s — treat all of the above as unverified.
  - By family convention expect: response shape `{"data": {"task_id", "status", "generated": [...]}}` with statuses `CREATED`/`IN_PROGRESS`/`COMPLETED`/`FAILED`, optional `webhook_url`, and an image-URL-or-Base64 input.

### PixVerse V5 — `POST /v1/ai/image-to-video/pixverse-v5`
- **Purpose:** Stylized/creative image-to-video generation from a first-frame image.
- **Submit/Status:** Submit — returns `task_id`. (Companion: `GET /v1/ai/image-to-video/pixverse-v5` lists tasks — see below.)
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | Prompt describing the video to generate. |
| `image_url` | string (URI) | Yes | — | URL of the image to use as the first frame. |
| `resolution` | string | Yes | — | Enum: `360p`, `540p`, `720p`, `1080p`. The resolution of the generated video. |
| `duration` | integer | No | — | Enum: `5`, `8`. Duration in seconds. 8s videos cost double. 1080p videos are limited to 5 seconds. |
| `negative_prompt` | string | No | `''` | Negative prompt to be used for the generation. |
| `style` | string | No | — | Enum: `anime`, `3d_animation`, `clay`, `cyberpunk`, `comic`. The style of the generated video. |
| `seed` | integer | No | — | Same seed + same prompt + same model version → same video every time. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that receives async notifications whenever the task changes status. |

- **Request:**
```json
{
  "prompt": "string",
  "image_url": "https://example.com/image.jpg",
  "resolution": "720p",
  "duration": 5,
  "negative_prompt": "string",
  "style": "anime",
  "seed": 0,
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
- **Credits:** Relative only — "8s videos cost double" (vs 5s). No absolute credit figure documented.
- **Gotchas:**
  - 1080p resolution is limited to a 5-second `duration`.
  - 8-second videos cost double the 5-second cost.
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### PixVerse V5 — List Tasks — `GET /v1/ai/image-to-video/pixverse-v5`
- **Purpose:** List PixVerse image-to-video tasks (status check).
- **Submit/Status:** Status/GET — returns an array of tasks.
- **Parameters:** None documented (no query or path parameters defined). Note a single-task status endpoint (`GET /v1/ai/image-to-video/pixverse-v5/{task-id}`) also exists per the family/overview index but its page detail was not exposed.
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
- **Credits:** not documented
- **Gotchas:** This endpoint lists tasks rather than fetching a single task's status; `data` is an array, not an object.

### OmniHuman 1.5 — `POST /v1/ai/video/omni-human-1-5`
- **Purpose:** Audio-driven human animation — animate a human-figure image so it performs/lip-syncs to a driving audio track.
- **Submit/Status:** Submit — returns `task_id`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `image_url` | string (URI) | Yes | — | URL of the human figure image to animate. Must be publicly accessible, contain a visible human figure, and be in jpg, jpeg, png, or webp format. |
| `audio_url` | string (URI) | Yes | — | URL of the audio file that drives the animation. Must be publicly accessible. Supported formats: MP3, OGG, WAV, M4A, AAC. Duration limits: 720p max 60 seconds, 1080p max 30 seconds. |
| `prompt` | string | No | — | Optional text guidance for the generation. Can describe desired motion, expression, or style (max 2000 chars). |
| `resolution` | string | No | `1080p` | Enum: `720p`, `1080p`. 1080p allows max 30 seconds audio; 720p allows max 60 seconds audio. |
| `turbo_mode` | boolean | No | `false` | Enable faster generation with potentially reduced quality. |
| `webhook_url` | string (URI) | No | — | Webhook URL to notify the user when the task is completed. |

- **Request:** No request example was provided on the documentation page.
- **Response:**
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
  - Audio duration tied to resolution: 720p max 60s, 1080p max 30s.
  - `image_url` formats: jpg, jpeg, png, webp only; must contain a visible human figure and be publicly accessible.
  - `audio_url` formats: MP3, OGG, WAV, M4A, AAC.
  - `prompt` max 2000 characters.
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.

### VFX Video Effects — `POST /v1/ai/video/vfx`
- **Purpose:** Apply AI-powered visual/film/lens effects to an existing video.
- **Submit/Status:** Submit — returns `task_id`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `video` | string | Yes | — | URL of the video to process (must be publicly accessible). |
| `filter_type` | integer | No | `1` | Effect type: `1` (film grain), `2` (motion blur), `3` (fish eye), `4` (VHS), `5` (shake), `6` (VGA), `7` (bloom), `8` (anamorphic lens). |
| `fps` | integer | No | `24` | Output frames per second (1-60). |
| `bloom_filter_contrast` | number | No | — | Contrast for bloom filter (only for `filter_type` `7`). |
| `motion_filter_kernel_size` | integer | No | — | Kernel size for motion blur (only for `filter_type` `2`). |
| `motion_filter_decay_factor` | number | No | — | Decay factor for motion blur (only for `filter_type` `2`). |
| `webhook_url` | string | No | — | URL for task completion notification. |

- **Request:** No complete request example was provided on the documentation page. Minimal valid body: `{ "video": "https://example.com/clip.mp4", "filter_type": 7, "bloom_filter_contrast": 1.5 }` (shape inferred from the parameter table; not verbatim from docs).
- **Response:** No response example was provided on the documentation page. Per family convention, expect `{"data": {"task_id", "status", "generated": [...]}}`.
- **Credits:** "VFX processing costs $0.017 per second of video."
- **Gotchas:**
  - Filter-specific params are mutually scoped: `bloom_filter_contrast` only applies to `filter_type` `7`; `motion_filter_kernel_size` and `motion_filter_decay_factor` only apply to `filter_type` `2`.
  - `fps` range is 1-60.
  - Supported video formats: MP4, MOV, and WebM.
  - Video URLs must be publicly accessible without authentication.

---

Coverage note for the caller: 6 of 7 endpoints fully extracted. **Seedance Pro 1080p could not be retrieved** — its doc page 404s at the official index slug and all probed variants, and there is no OpenAPI spec; its section above is flagged as unverified/inferred. The two Runway pages required dropping the `/overview` suffix (the `/overview` URLs in the brief 404; the bare slugs `/runway-gen4-turbo` and `/runway-act-two` resolve). All other facts match the known shared model (async `task_id`, `x-magnific-api-key`, Svix webhooks, base URL `https://api.magnific.com/v1`).

