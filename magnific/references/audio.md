# Magnific API — Audio Reference

> Music generation, sound effects, and audio isolation. All async submit→poll/webhook. See `foundations.md` for shared mechanics.

## Audio: Music Generation + Sound Effects

The audio family covers two asynchronous generation operations: **Music Generation** (`/v1/ai/music-generation`) produces full instrumental/vocal music tracks from a text prompt over a 10–240 second duration, and **Sound Effects** (`/v1/ai/sound-effects`) produces short (0.5–22 s) sound-effect clips from a text description, with optional seamless looping. Pick Music Generation when you need a composed track described by style/mood/instruments/tempo/genre; pick Sound Effects for short, atomic SFX (foley, ambience, impacts) where you may want looping or tighter prompt adherence. Both follow the standard submit-then-poll/webhook task model: the POST returns a `task_id`, and you either poll the matching GET task-status endpoint or supply a `webhook_url` to receive the completed result. Output is delivered as URLs in the `generated` array.

### Generate Music — `POST /v1/ai/music-generation`
- **Purpose:** Generate a music track from a text prompt for a specified duration.
- **Submit/Status:** Submit — returns a `task_id` (async; poll or use `webhook_url`).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `prompt` | string | Yes | — | "Text description of the music you want to generate. Be specific about the style, mood, instruments, tempo, and genre for best results." Max 2500 chars. |
| `music_length_seconds` | integer | Yes | — | "Duration of the generated music track in seconds." Min 10, Max 240 (4 minutes). |
| `webhook_url` | string | No | — | "Optional callback URL that will receive asynchronous notifications whenever the task changes status." |

- **Request:**
```json
{
  "prompt": "A Blues guitar solo with emotional bends and slides",
  "music_length_seconds": 60
}
```
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
- **Credits:** Not documented (overview page references an external pricing page; no per-call credit figure shown).
- **Gotchas:**
  - `music_length_seconds` must be in the inclusive range **10–240** seconds; values outside this range are rejected.
  - `prompt` max length is **2500** characters.
  - Output is **MP3** audio at "professional quality"; "Any music genre, style, or mood" supported.
  - Generation time is **30–90 seconds** depending on track duration; "Shorter tracks (10–30 seconds) usually complete in under a minute." Plan polling/webhook timeouts accordingly.
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.
  - Auth via `x-magnific-api-key` header (server-to-server only).
  - The example `generated` URL points to a `.jpg` in the docs — this is a docs placeholder; the real artifact is the audio file.

### List Music Generation Tasks — `GET /v1/ai/music-generation`
- **Purpose:** Get the status of all music-generation tasks.
- **Submit/Status:** Status — list/GET (returns an array of tasks).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| _(none documented)_ | — | — | — | No query or path parameters are documented in the OpenAPI spec. Pagination params `page` and `per_page` are implied by the 400 error text ("Parameter 'page' must be greater than 0") but are not formally listed on this page. |

- **Request:** No request body. `GET /v1/ai/music-generation` with the auth header.
- **Response:**
```json
{
  "data": [
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
      "status": "IN_PROGRESS",
      "generated": ["https://openapi-generator.tech", "https://openapi-generator.tech"]
    },
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee92",
      "status": "COMPLETED",
      "generated": ["https://openapi-generator.tech"]
    }
  ]
}
```
- **Credits:** Not documented (listing tasks is not noted as billable).
- **Gotchas:**
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.
  - Error responses: **400** (invalid parameters — "page > 0, non-empty query, valid filter"), **401** (missing/invalid API key), **500** (Internal Server Error), **503** (Service Unavailable).
  - The `generated` example URLs (`https://openapi-generator.tech`) are OpenAPI-generator placeholders, not real outputs.
  - Auth via `x-magnific-api-key` header.

### Get Music Generation Task by ID — `GET /v1/ai/music-generation/{task-id}`
- **Purpose:** Get the status and results of a single music-generation task by its ID.
- **Submit/Status:** Status — GET single task (the poll endpoint for the submit call above).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `task-id` | string (UUID) | Yes | — | Path parameter. "ID of the task." |

- **Request:** No body. `GET /v1/ai/music-generation/{task-id}` with the auth header.
- **Response (completed):**
```json
{
  "data": {
    "generated": ["https://ai-statics.freepik.com/completed_task_image.jpg"],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "COMPLETED"
  }
}
```
- **Response (in progress):**
```json
{
  "data": {
    "generated": [],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** Not documented (status polling not noted as billable).
- **Gotchas:**
  - `task-id` is a UUID path parameter.
  - While the task is running, `generated` is an empty array (`[]`); URLs appear only on `COMPLETED`.
  - Status values shown in examples: `IN_PROGRESS`, `COMPLETED` (the full task-status enum is `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`).
  - Error responses: **400** (Bad Request — invalid syntax), **401** (invalid/missing API key), **500**, **503**.
  - Auth via `x-magnific-api-key` header.

### Generate Sound Effect — `POST /v1/ai/sound-effects`
- **Purpose:** Generate a short sound-effect clip from a text description, optionally looping.
- **Submit/Status:** Submit — returns a `task_id` (async; poll or use `webhook_url`).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `text` | string | Yes | — | "The text to convert to sound effects." Max 2500 chars. |
| `duration_seconds` | number | Yes | — | "The duration of the generated audio in seconds." Range 0.5–22. |
| `loop` | boolean | No | `false` | "Whether to create a sound effect that loops smoothly." |
| `prompt_influence` | number | No | `0.3` | "The influence of the prompt on the generated audio. A value between 0 and 1." Range 0–1. |
| `webhook_url` | string | No | — | "Optional callback URL that will receive asynchronous notifications whenever the task changes status." |

- **Request:**
```json
{
  "text": "Ocean waves crashing on the beach",
  "duration_seconds": 10,
  "loop": true,
  "prompt_influence": 0.7
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
- **Credits:** Not documented (no per-call credit figure shown on the page).
- **Gotchas:**
  - `duration_seconds` must be in the range **0.5–22** seconds (much shorter than music generation).
  - `prompt_influence` must be in the range **0–1**; default `0.3`. Higher values bias output more strongly toward the prompt.
  - `text` max length is **2500** characters.
  - `loop: true` produces a seamless looping effect — use for ambient/repeating SFX.
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.
  - Auth via `x-magnific-api-key` header.
  - The example `generated` URL is a docs placeholder (`.jpg`); the real artifact is the audio file.

### List Sound Effects Tasks — `GET /v1/ai/sound-effects`
- **Purpose:** Get the status of all sound-effects tasks.
- **Submit/Status:** Status — list/GET (returns an array of tasks).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| _(none documented)_ | — | — | — | No query or path parameters documented. Pagination params `page` and `per_page` are implied by 400 error text ("Parameter 'page' must be greater than 0"; "Parameter 'per_page' must be greater than 0") but not formally listed. |

- **Request:** No request body. `GET /v1/ai/sound-effects` with the auth header.
- **Response:**
```json
{
  "data": [
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
      "status": "IN_PROGRESS",
      "generated": [
        "https://openapi-generator.tech",
        "https://openapi-generator.tech"
      ]
    }
  ]
}
```
- **Credits:** Not documented.
- **Gotchas:**
  - Task statuses: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`.
  - Pagination constraints from error text: "Parameter 'page' must be greater than 0"; "Parameter 'per_page' must be greater than 0".
  - Error responses: **400** (invalid parameters — "page > 0, query not empty, valid filter"), **401** (invalid/missing API key), **500**, **503**.
  - `generated` example URLs (`https://openapi-generator.tech`) are placeholders.
  - Auth via `x-magnific-api-key` header.

### Get Sound Effects Task by ID — `GET /v1/ai/sound-effects/{task-id}`
- **Purpose:** Get the status and results of a single sound-effects task by its ID.
- **Submit/Status:** Status — GET single task (the poll endpoint for the sound-effects submit call).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `task-id` | string (UUID) | Yes | — | Path parameter. "ID of the task." |

- **Request:** No body. `GET /v1/ai/sound-effects/{task-id}` with the auth header.
- **Response (completed):**
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
- **Response (in progress):**
```json
{
  "data": {
    "generated": [],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** Not documented.
- **Gotchas:**
  - `task-id` is a UUID path parameter.
  - While running, `generated` is an empty array (`[]`); URLs appear only on `COMPLETED`.
  - Status values shown in examples: `IN_PROGRESS`, `COMPLETED` (full enum: `CREATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`).
  - Error responses: **400** (Bad Request), **401** (Unauthorized), **500** (Internal Server Error), **503** (Service Unavailable).
  - Auth via `x-magnific-api-key` header.

> Cross-family notes: The music-generation overview page describes these as ElevenLabs-backed audio models (MP3 output, professional quality). No NSFW filter, LoRA, or mutually-exclusive-param constraints are documented for either operation. No per-call credit cost is published on any of these pages — usage is credit-based per the shared facts, but the exact figures are not on the audio endpoints. Webhooks follow the shared Svix-style scheme (`webhook-id`, `webhook-timestamp`, `webhook-signature`; HMAC-SHA256 over `id.timestamp.body`, base64).

---

## SAM Audio — Audio Isolation

SAM Audio isolates a specific sound from a recording given a natural-language description (e.g. "A person speaking", "Piano playing"), returning a clean WAV of just that sound. Submit one input — `audio` for pure audio recordings, or `video` when you need to localize the source visually via a bounding box (`x1,y1,x2,y2`) before extracting its audio. It is an asynchronous, credit-based family: `POST` to submit and get a `task_id`, then either poll the `GET` task-status endpoint or supply a `webhook_url` to receive the result; `GET` (list) enumerates all your tasks.

### Create Audio Isolation Task — `POST /v1/ai/audio-isolation`
- **Purpose:** Isolate a described sound from an input audio or video file, producing a WAV of the isolated sound.
- **Submit/Status:** Submit — returns a `task_id` with `status: "CREATED"`.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `description` | string | Yes | — | Text description of the sound to isolate from the input audio or video (e.g. "A person speaking", "Piano playing"). Max 2500 chars. |
| `audio` | string | No* | — | Audio input — publicly accessible HTTPS URL or base64-encoded audio. Formats: WAV, MP3, FLAC, OGG, M4A. Mutually exclusive with `video`. |
| `video` | string | No* | — | Video input — publicly accessible HTTPS URL or base64-encoded video. Formats: MP4, MOV, WEBM, AVI. Mutually exclusive with `audio`. |
| `x1` | integer | No | 0 | Bounding box x1 coordinate (left edge) in pixels. Min: 0. Only applicable for video input (video localization). |
| `y1` | integer | No | 0 | Bounding box y1 coordinate (top edge) in pixels. Min: 0. Only applicable for video input. |
| `x2` | integer | No | 0 | Bounding box x2 coordinate (right edge) in pixels. Min: 0. Only applicable for video input. |
| `y2` | integer | No | 0 | Bounding box y2 coordinate (bottom edge) in pixels. Min: 0. Only applicable for video input. |
| `sample_fps` | number/integer | No | 2 | Frame sampling rate in FPS for video processing. Min: 1, Max: 5. |
| `reranking_candidates` | integer | No | 1 | Number of reranking candidates — quality vs. latency trade-off. Min: 1, Max: 8 (higher = better quality, slower). |
| `predict_spans` | boolean | No | false | Enable span prediction for better isolation of non-ambient, event-based sounds. |
| `webhook_url` | string (URI) | No | — | Optional callback URL that will receive asynchronous task-completion notifications. |

- **Request:**
```json
{
  "description": "A person speaking",
  "audio": "https://example.com/noisy-recording.wav"
}
```
(Video input variant:)
```json
{
  "description": "Piano playing",
  "video": "https://example.com/concert.mp4",
  "x1": 100,
  "y1": 50,
  "x2": 400,
  "y2": 300,
  "sample_fps": 2
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
- **Credits:** Not documented.
- **Gotchas:**
  - Exactly one of `audio` or `video` must be provided — they are mutually exclusive; supplying both (or neither) is invalid.
  - Bounding-box coordinates (`x1`,`y1`,`x2`,`y2`) and `sample_fps` only apply to `video` input.
  - Input audio formats: WAV, MP3, FLAC, OGG, M4A; input video formats: MP4, MOV, WEBM, AVI.
  - Output is always a high-quality WAV file containing the isolated sound.
  - `description` capped at 2500 chars; `sample_fps` range 1–5; `reranking_candidates` range 1–8.
  - Processing is asynchronous: the task_id is returned immediately and the result arrives later (poll the GET endpoint or use `webhook_url`).
  - Auth header `x-magnific-api-key` required (server-to-server only).
  - No file-size or duration maximums documented.

### List Audio Isolation Tasks — `GET /v1/ai/audio-isolation`
- **Purpose:** List all audio isolation tasks for the authenticated account.
- **Submit/Status:** Status/GET — returns an array of task objects.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| _(none documented)_ | — | — | — | No query, path, or request-body parameters documented. (Error 400 references `page must be >0` and a `filter`, but no such params are documented on this page.) |

- **Request:**
```
GET /v1/ai/audio-isolation
x-magnific-api-key: YOUR_API_KEY
```
- **Response:**
```json
{
  "data": [
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
      "status": "IN_PROGRESS",
      "generated": ["https://openapi-generator.tech"]
    },
    {
      "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee92",
      "status": "COMPLETED",
      "generated": ["https://openapi-generator.tech"]
    }
  ]
}
```
- **Credits:** Not documented.
- **Gotchas:**
  - `data` is a flat array of task objects; each has `task_id` (UUID), `status` (CREATED | IN_PROGRESS | COMPLETED | FAILED), and `generated` (array of result URLs).
  - No pagination parameters documented despite a 400 error mentioning `page must be >0` / non-empty query / valid filter.
  - Error responses: 400 (invalid parameters), 401 (missing/invalid API key), 500 (Internal Server Error), 503 (Service Unavailable).
  - Auth header `x-magnific-api-key` required.

### Get Audio Isolation Task by ID — `GET /v1/ai/audio-isolation/{task-id}`
- **Purpose:** Get the status and results of a single audio isolation task by its ID.
- **Submit/Status:** Status/GET — poll this to retrieve task progress and the isolated-audio output URL(s).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `task-id` | string (UUID) | Yes | — | Path parameter — ID of the task. |

- **Request:**
```
GET /v1/ai/audio-isolation/046b6c7f-0b8a-43b9-b35d-6489e6daee91
x-magnific-api-key: YOUR_API_KEY
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
(In-progress variant:)
```json
{
  "data": {
    "generated": [],
    "task_id": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
    "status": "IN_PROGRESS"
  }
}
```
- **Credits:** Not documented.
- **Gotchas:**
  - `status` is one of CREATED | IN_PROGRESS | COMPLETED | FAILED; `generated` is empty until the task reaches COMPLETED, then holds the isolated-audio output URL(s).
  - The documented COMPLETED example URL points at a `.jpg` (`https://ai-statics.freepik.com/completed_task_image.jpg`) — a docs placeholder; actual output is a WAV audio file.
  - Path param is rendered as `{task-id}` (hyphen) in the route even though the JSON field is `task_id` (underscore).
  - Error responses: 400 (Bad Request — invalid syntax), 401 (Unauthorized), 500 (Internal Server Error), 503 (Service Unavailable).
  - Auth header `x-magnific-api-key` required.

