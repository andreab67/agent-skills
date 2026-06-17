# Magnific API — Analytics & Stock Content Reference

> Team analytics (credit usage, members, API keys, groups, projects) and stock content access (images & templates, icons, videos). Analytics endpoints are Business/Enterprise-only and do not consume credits. See `foundations.md` for shared mechanics.

## Analytics & Stock Content

This family splits into two groups. **Analytics** (Business/Enterprise-only) reports credit consumption across your team and exposes discovery endpoints (members, API keys, groups, projects) whose IDs feed the credit-usage filters. **Stock content** (Resources/Images+Templates, Icons, Videos) is a read-and-download stock library: list/search assets, fetch one asset's metadata by ID, then download it. All endpoints here are **synchronous** GETs except `team-credit-usage`, which is a synchronous POST query (none use the async `task_id` model). Pick Analytics for billing/usage reporting and governance; pick a stock-content family for asset discovery and licensed downloads.

### Team Credit Usage — `POST /v1/analytics/team-credit-usage`
- **Purpose:** Report team credit consumption over a date range, optionally sliced by group, project, or API key.
- **Submit/Status:** Synchronous (returns data directly; no `task_id`).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `granularity` | enum | No | `day` | `day`, `week`, `month`, `year` |
| `start_date` | string | No | — | If no dates provided, returns the last 7 days |
| `end_date` | string | No | — | — |
| `group_ids` | array | No | — | Show only consumption from members of specific groups (IDs from `team-groups`) |
| `project_references` | array | No | — | Show only consumption within specific projects (UUIDs from `team-projects`) |
| `api_key_ids` | array | No | — | Show only consumption from specific API keys (IDs from `team-api-keys`) |

- **Request:**
```bash
curl -X POST https://api.magnific.com/v1/analytics/team-credit-usage \
  -H "X-Magnific-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "granularity": "day",
    "start_date": "2026-05-01",
    "end_date": "2026-05-31",
    "group_ids": [10]
  }'
```
- **Response:**
```json
{
  "data": [
    {
      "date": "2026-05-01T00:00:00+00:00",
      "consumptions": [
        {
          "tool": "AI Image Models",
          "user_uses": 45,
          "user_credits": 1800,
          "user_usages": [
            {
              "user_email": "designer@company.com",
              "user_uses": 30,
              "user_credits": 1200,
              "project_reference": "a1b2c3d4-1111-4000-8000-000000000001",
              "project_name": "Marketing Campaign",
              "group_name": "Design Team"
            },
            {
              "user_email": "developer@company.com",
              "user_uses": 15,
              "user_credits": 600
            }
          ]
        },
        {
          "tool": "Asset Download",
          "user_uses": 10,
          "user_credits": 900
        }
      ]
    }
  ]
}
```
- **Credits:** No per-call charge — "The Analytics API is included with your Business or Enterprise plan at no additional cost." (Response reports credit consumption of *other* tools.)
- **Gotchas:**
  - Available exclusively for Business and Enterprise plans.
  - Rate limit: all Analytics endpoints capped at 100 requests per day (100 RPD).
  - Max date range: Enterprise 365 days, Business 180 days.
  - Filter ID/reference values come from the four discovery GETs below.
  - Auth via `X-Magnific-API-Key` header; the team is resolved automatically from the key.
  - Note: the standalone `team-credit-usage/overview` doc URL returns 404; details above come from the analytics overview page.

### List Team Members — `GET /v1/analytics/team-members`
- **Purpose:** List all members of the caller's team with role and status.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| (none) | — | — | — | No query/path/body params. Team resolved automatically from the API key. `x-magnific-api-key` header required. |

- **Request:**
```
GET /v1/analytics/team-members
x-magnific-api-key: YOUR_API_KEY
```
- **Response:**
```json
{
  "data": [
    {
      "email": "designer@company.com",
      "role": "admin",
      "status": "active"
    },
    {
      "email": "developer@company.com",
      "role": "member",
      "status": "active"
    },
    {
      "email": "intern@company.com",
      "role": "member",
      "status": "invited"
    }
  ]
}
```
- **Credits:** Not documented (Analytics API included at no additional cost).
- **Gotchas:**
  - `role` enum: `owner`, `admin`, `member`. `status` enum: `active`, `inactive`, `invited`.
  - 403 if the user is not authorized to access the resource; 500 on internal error.
  - Subject to the 100 RPD Analytics rate limit; Business/Enterprise only.

### List Team API Keys — `GET /v1/analytics/team-api-keys`
- **Purpose:** List the team's API keys (IDs to use as `api_key_ids` filters in credit-usage).
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| (none) | — | — | — | No params. `x-magnific-api-key` header required; team resolved from key. |

- **Request:**
```
GET /v1/analytics/team-api-keys
x-magnific-api-key: YOUR_API_KEY
```
- **Response:**
```json
{
  "data": [
    {
      "api_key_id": "fpk-abc123def456",
      "display_name": "Production Backend",
      "status": "active",
      "created_at": "2026-01-15T10:30:00.000Z"
    },
    {
      "api_key_id": "fpk-xyz789ghi012",
      "display_name": "Staging",
      "status": "active",
      "created_at": "2026-03-20T14:00:00.000Z"
    }
  ]
}
```
- **Credits:** Not documented (Analytics API included at no additional cost).
- **Gotchas:**
  - Schema: `api_key_id` (string), `display_name` (string), `status` enum `active`/`inactive`, `created_at` (date-time).
  - Use returned `api_key_id` values in the `api_keys`/`api_key_ids` filter of `POST /v1/analytics/team-credit-usage`.
  - 403 / 500 error responses; subject to 100 RPD limit; Business/Enterprise only.

### List Team Groups — `GET /v1/analytics/team-groups`
- **Purpose:** List all groups in the team with member counts (IDs feed the `group_ids` filter).
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| (none) | — | — | — | No params. `X-Magnific-API-Key` header required; team resolved from key. |

- **Request:**
```
GET /v1/analytics/team-groups
X-Magnific-API-Key: YOUR_API_KEY
```
- **Response:**
```json
{
  "data": [
    {
      "group_id": 10,
      "name": "Design Team",
      "member_count": 5
    },
    {
      "group_id": 20,
      "name": "Marketing Team",
      "member_count": 8
    },
    {
      "group_id": 30,
      "name": "Engineering",
      "member_count": 12
    }
  ]
}
```
- **Credits:** Not documented (Analytics API included at no additional cost).
- **Gotchas:**
  - Schema: `group_id` (integer), `name` (string), `member_count` (integer).
  - Use returned `group_id` values in the `group_ids` filter of `POST /v1/analytics/team-credit-usage`.
  - 403 / 500 error responses; subject to 100 RPD limit; Business/Enterprise only.

### List Team Projects — `GET /v1/analytics/team-projects`
- **Purpose:** List all projects in the team (UUID references feed the `project_references` filter).
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| (none) | — | — | — | No params. `x-magnific-api-key` header required; team resolved from key. |

- **Request:**
```
GET /v1/analytics/team-projects
x-magnific-api-key: YOUR_API_KEY
```
- **Response:**
```json
{
  "data": [
    {
      "project_reference": "a1b2c3d4-1111-4000-8000-000000000001",
      "name": "Marketing Campaign Q4"
    },
    {
      "project_reference": "b2c3d4e5-2222-4000-8000-000000000002",
      "name": "Product Launch Assets"
    }
  ]
}
```
- **Credits:** Not documented (Analytics API included at no additional cost).
- **Gotchas:**
  - Schema: `project_reference` (string, UUID), `name` (string).
  - Use returned `project_reference` values in the `project_references` filter of `POST /v1/analytics/team-credit-usage`.
  - 403 (not authorized / not team owner) / 500 error responses; subject to 100 RPD limit; Business/Enterprise only.

### List Resources (Images & Templates) — `GET /v1/resources`
- **Purpose:** Search/list stock photos, vectors, and PSD resources with sorting and filters.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 (2-letter language code); falls back to `en-US` if missing/invalid |
| `x-magnific-api-key` (header) | string | Yes | — | API key for authentication |
| `page` | integer | No | — | Must be > 0 and ≤ 100 |
| `limit` | integer | No | — | Results per page; must be > 0 |
| `term` | string | No | — | Search term or slug for resource discovery |
| `order` | string | No | `relevance` | `relevance`, `recent` |
| `filters` | object | No | — | Deep-object filters (see below) |
| `filters[orientation][landscape]` | 0/1 | No | — | — |
| `filters[orientation][portrait]` | 0/1 | No | — | — |
| `filters[orientation][square]` | 0/1 | No | — | — |
| `filters[orientation][panoramic]` | 0/1 | No | — | — |
| `filters[content_type][photo]` | 0/1 | No | — | — |
| `filters[content_type][psd]` | 0/1 | No | — | — |
| `filters[content_type][vector]` | 0/1 | No | — | — |
| `filters[license][freemium]` | 0/1 | No | — | — |
| `filters[license][premium]` | 0/1 | No | — | — |
| `filters[period]` | string | No | — | `last-month`, `last-quarter`, `last-semester`, `last-year` |
| `filters[color]` | string | No | — | `black`, `blue`, `gray`, `green`, `orange`, `red`, `white`, `yellow`, `purple`, `cyan`, `pink` |
| `filters[author]` | integer | No | — | Numeric author ID |
| `filters[ai-generated][excluded]` | 0/1 | No | — | — |
| `filters[ai-generated][only]` | 0/1 | No | — | — |
| `filters[vector][type]` | string | No | — | `jpg`, `ai`, `eps`, `svg` |
| `filters[vector][style]` | string | No | — | `watercolor`, `flat`, `cartoon`, `geometric`, `gradient`, `isometric`, `3d`, `hand-drawn` |
| `filters[psd][type]` | string | No | — | `jpg`, `psd` |
| `filters[ids]` | string | No | — | Comma-separated list; incompatible with any other filters |
| `filters[people][include]` | 0/1 | No | — | — |
| `filters[people][exclude]` | 0/1 | No | — | — |
| `filters[people][number]` | string | No | — | `1`, `2`, `3`, `more_than_three` |
| `filters[people][age]` | string | No | — | `infant`, `child`, `teen`, `young-adult`, `adult`, `senior`, `elder` |
| `filters[people][gender]` | string | No | — | `male`, `female` |
| `filters[people][ethnicity]` | string | No | — | `south-asian`, `middle-eastern`, `east-asian`, `black`, `hispanic`, `indian`, `white`, `multiracial`, `southeast-asian` |

- **Request:**
```
GET /v1/resources?term=nature&page=1&limit=100&order=recent&filters[content_type][vector]=1&filters[orientation][landscape]=1
Accept-Language: en-US
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": [
    {
      "id": 770011,
      "title": "Sports car",
      "url": "https://www.freepik.com/free-icon/sports-car_770011.htm",
      "filename": "sports-car.zip",
      "licenses": [
        {
          "type": "freemium",
          "url": "https://www.freepik.com/profile/license/pdf/770011?lang=en"
        }
      ],
      "image": {
        "type": "photo",
        "orientation": "square",
        "source": {
          "url": "https://img.flaticon.com/icons/png/512/67/67994.png",
          "key": "large",
          "size": "128x128"
        }
      },
      "author": {
        "id": 744082,
        "name": "flaticon",
        "avatar": "https://avatar.cdnpk.net/744082.jpg",
        "slug": "flaticon",
        "assets": 0
      },
      "meta": {
        "published_at": "2022-01-14T20:45:28.000Z",
        "is_new": true,
        "available_formats": {
          "jpg": {
            "total": 2,
            "items": [
              {
                "id": 444,
                "name": "Sports car",
                "colorspace": "RGB",
                "size": 100
              }
            ]
          }
        }
      },
      "related": {
        "serie": [],
        "others": [],
        "keywords": []
      },
      "stats": {
        "downloads": 52527,
        "likes": 137
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 32,
    "per_page": 2,
    "total": 63,
    "clean_search": true
  }
}
```
- **Credits:** Not documented for the list call (credit cost applies on download).
- **Gotchas:**
  - `page` must be > 0 and ≤ 100; `limit` must be > 0.
  - `filters[ids]` is incompatible with any other filters.
  - Errors: 400 (page ≤ 0, empty query, invalid filters), 401 (bad/missing key), 403 (insufficient/premium access), 404, 503.
  - Rate limits apply (see Magnific Rate limits page).

### Get Resource Detail by ID — `GET /v1/resources/{resource-id}`
- **Purpose:** Retrieve full metadata for one photo, vector, or PSD resource (response shape varies by type; AI assets add `model_type`/`model_subtype`).
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `resource-id` (path) | string | Yes | — | Photo, video or PSD resource ID (e.g. `30955`) |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnificApiKey` / `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/resources/30955
Accept-Language: en-US
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": {
    "id": 770012,
    "name": "Abstract of white lines background generative ai",
    "slug": "abstract-white-lines-background-generative-ai",
    "type": "photo",
    "is_ai_generated": false,
    "premium": true,
    "new": true,
    "url": "https://www.freepik.com/premium-photo/abstract-white-lines-background-generative-ai_39178780.htm",
    "preview": {
      "url": "https://www.freepik.com/premium-photo/abstract-white-lines-background-generative-ai_39178780.htm",
      "width": 300,
      "height": 200
    },
    "has_prompt": false,
    "author": {
      "id": 744082,
      "name": "flaticon",
      "avatar": "https://avatar.cdnpk.net/744082.jpg",
      "slug": "flaticon",
      "assets": 100
    },
    "license": "https://www.freepik.com/profile/license/pdf/4350594",
    "created": "2020-01-01T00:00:00.000Z",
    "dimensions": {
      "width": 1000,
      "height": 1000
    },
    "download_size": 1024,
    "available_formats": {
      "jpg": {
        "total": 1,
        "items": [{"size": 100}]
      }
    },
    "related_resources": {
      "suggested": [],
      "same_author": [],
      "same_collection": {"url": "...", "items": []},
      "same_series": {"url": "...", "items": []}
    },
    "related_tags": [
      {"name": "coloring pages", "slug": "coloring-pages"}
    ]
  }
}
```
  AI-generated variant adds:
```json
{
  "data": {
    "id": 770012,
    "name": "Abstract of white lines background generative ai",
    "type": "photo",
    "is_ai_generated": true,
    "has_prompt": true,
    "model_type": "Midjourney",
    "model_subtype": "Midjourney 5",
    "dimensions": {"width": 1000, "height": 1000}
  }
}
```
- **Credits:** Not documented (cost applies on download).
- **Gotchas:**
  - Supports four resource types — photo, vector, PSD, AI-generated; `available_formats` and `related_resources` differ by type.
  - `download_size` is in bytes.
  - Errors: 400 (`{"message": "Parameter ':attribute' is not valid"}`), 401 (`Invalid API key`), 404 (`Resource not found`), 500, 503.

### Download a Resource — `GET /v1/resources/{resource-id}/download`
- **Purpose:** Get a signed download URL for a resource (with optional resize).
- **Submit/Status:** Synchronous GET (returns download links).
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `resource-id` (path) | integer | Yes | — | Photo, video or PSD resource ID (e.g. `30955`) |
| `image_size` (query) | string | No | — | Resize longest side, keeping aspect ratio. Pixel value `100px`–`2000px`, or keywords `small` (1000px), `medium` (1500px), `large` (2000px), `original` |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/resources/30955/download?image_size=2000px
Accept-Language: en-US
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": {
    "filename": "blackboard-template.zip",
    "url": "https://downloadscdn5.freepik.com/d/1137445/blackboard-template.zip",
    "signed_url": "https://img.freepik.com/premium-photo/close-up-cat-resting_1048944-9269194.jpg?t=st=1725276607~exp=1725280207~hmac=...",
    "prompt": "Two cute cats are playing with a ball of wool"
  }
}
```
- **Credits:** Not documented numerically; download consumes credits / counts against download limits (see 429).
- **Gotchas:**
  - 403: "The user cannot download this item because it is premium."
  - 429: download limits exceeded.
  - `image_size` resizes only the longest side; applies to photos.

### Download Resource by ID and Format — `GET /v1/resources/{resource-id}/download/{resource-format}`
- **Purpose:** Get a signed download URL for a specific file format of a resource.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `resource-id` (path) | integer | Yes | — | Photo, video or PSD resource ID |
| `resource-format` (path) | string | Yes | — | `psd`, `ai`, `eps`, `atn`, `fonts`, `resources`, `png`, `jpg`, `3d-render`, `svg`, `mockup` |
| `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/resources/1137445/download/psd
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": [
    {
      "filename": "blackboard-template.zip",
      "url": "https://downloadscdn5.freepik.com/d/1137445/blackboard-template.zip",
      "signed_url": "https://img.freepik.com/premium-photo/close-up-cat-resting_1048944-9269194.jpg?t=st=1725276607~exp=1725280207~hmac=..."
    }
  ]
}
```
- **Credits:** Not documented numerically; counts against download limits (see 429).
- **Gotchas:**
  - Response `data` is an array here (vs. an object in the base download endpoint).
  - 403 ("…premium"), 404 ("Resource not found"), 429 ("…download limits has been reached").

### List Icons — `GET /v1/icons`
- **Purpose:** Search/list icons with sorting and filters.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `term` | string | No | — | Search term. If only `term`, searches by term; if only `slug`, searches by slug; if both, searches by slug |
| `slug` | string | No | — | Search by slug |
| `page` | integer | No | — | Must be > 0 |
| `per_page` | integer | No | — | Must be > 0 |
| `family-id` | integer | No | — | Icon family id (minimum: 1) |
| `order` | string | No | `relevance` | `relevance`, `recent` |
| `thumbnail_size` | string | No | `128` | Thumbnail size; defaults to 128 if unspecified |
| `filters[color]` | string | No | — | `gradient`, `solid-black`, `multicolor`, `azure`, `black`, `blue`, `chartreuse`, `cyan`, `gray`, `green`, `orange`, `red`, `rose`, `spring-green`, `violet`, `white`, `yellow` |
| `filters[shape]` | string | No | — | `outline`, `fill`, `lineal-color`, `hand-drawn` |
| `filters[period]` | string | No | `all` | `three-months`, `six-months`, `one-year`, `all` |
| `filters[free_svg]` | string | No | `all` | `all`, `free`, `premium` |
| `filters[icon_type]` | array | No | — | `standard`, `animated`, `sticker`, `uicon` |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/icons?term=dog&page=1&per_page=20&order=relevance&filters[shape]=outline
Accept-Language: en-US
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": [
    {
      "id": 52912,
      "name": "a woman reads a book in a tablet sits in the luxurious back of the library",
      "created": "2023-03-07T23:05:26.000Z",
      "slug": "a-woman-reads-a-book-in-a-tablet-sits-in-the-luxurious-back-of-the-library",
      "style": {
        "id": 50,
        "name": "Meticulous Yellow shadow"
      },
      "family": {
        "id": 1,
        "name": "Outline",
        "total": 1200
      },
      "author": {
        "id": 2147483647,
        "name": "John Doe",
        "avatar": "https://avatar.cdnpk.net/61668527-220726032514.jpg",
        "assets": 0,
        "slug": "merry-christmas"
      },
      "thumbnails": [
        {
          "url": "https://v4.cdnpk.net/videvo_files/video/free/video0485/thumbnails/_import_61a866e2519c71.61070863_large.png",
          "width": 512,
          "height": 512
        }
      ],
      "free_svg": true,
      "tags": [
        {
          "name": "Dog",
          "slug": "dog"
        }
      ]
    }
  ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "per_page": 1,
      "last_page": 1,
      "total": 1
    }
  }
}
```
- **Credits:** Not documented for the list call (cost applies on download).
- **Gotchas:**
  - `page` and `per_page` must be > 0; empty queries are rejected (400).
  - When both `term` and `slug` are sent, search is by `slug`.
  - Errors: 400, 401 (missing/invalid key), 404, 500.

### Get Icon by ID — `GET /v1/icons/{id}`
- **Purpose:** Retrieve metadata for a single icon, including related items.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `id` (path) | integer | Yes | — | Icon resource ID (e.g. `30955`) |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/icons/30955
Accept-Language: en-US
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": {
    "id": 52912,
    "name": "a woman reads a book in a tablet sits in the luxurious back of the library",
    "created": "2023-03-07T23:05:26.000Z",
    "slug": "a-woman-reads-a-book-in-a-tablet-sits-in-the-luxurious-back-of-the-library",
    "style": {
      "id": 50,
      "name": "Meticulous Yellow shadow"
    },
    "family": {
      "id": 1,
      "name": "Outline",
      "total": 1200
    },
    "author": {
      "id": 2147483647,
      "name": "John Doe",
      "avatar": "https://avatar.cdnpk.net/61668527-220726032514.jpg",
      "assets": 0,
      "slug": "merry-christmas"
    },
    "thumbnails": [
      {
        "url": "https://v4.cdnpk.net/videvo_files/video/free/video0485/thumbnails/_import_61a866e2519c71.61070863_large.png",
        "width": 512,
        "height": 512
      }
    ],
    "free_svg": true,
    "tags": [
      {
        "name": "Dog",
        "slug": "dog"
      }
    ],
    "related": {
      "visual_concept": [],
      "style": [],
      "variants": []
    }
  }
}
```
- **Credits:** Not documented (cost applies on download).
- **Gotchas:**
  - Adds a `related` object (`visual_concept`, `style`, `variants`) over the list-item shape.
  - Errors: 400 (invalid syntax), 401 (unauthorized), 404 ("Icon with provided id does not exist" / "Icon not found"), 500.

### Download an Icon — `GET /v1/icons/{id}/download`
- **Purpose:** Get a download URL for an icon in a chosen format.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `id` (path) | integer | Yes | — | Icon resource ID (e.g. `30955`) |
| `format` (query) | string | No | — | `svg`, `png`, `gif`, `mp4`, `aep`, `json`, `psd`, `eps` |
| `png_size` (query) | integer | No | `512` | Only applies to format `png`. `512`, `256`, `128`, `64`, `32`, `24`, `16` |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/icons/30955/download?format=svg
Accept-Language: en-US
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": {
    "filename": "filename",
    "url": "https://openapi-generator.tech"
  }
}
```
- **Credits:** Not documented numerically; download consumes credits / counts against limits.
- **Gotchas:**
  - `gif`, `mp4`, `aep`, `json`, `psd`, and `eps` are NOT available for standard and sticker icon types.
  - `png_size` is ignored unless `format=png`.

### List Videos — `GET /v1/videos`
- **Purpose:** Search/list stock videos (footage / motion graphics) with sorting and rich filters.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `term` | string | Yes* | — | Search term. *Required whenever the `author` filter is not in the request. |
| `page` | integer | No | — | Must be > 0 |
| `order` | string | No | `relevance` | `relevance`, `recent`, `random` |
| `filters` | object | No | — | See sub-fields below |
| `filters[aspect_ratio]` | array enum | No | — | `1:1`, `4:3`, `9:16`, `16:9`, `256:135` |
| `filters[category]` | enum | No | — | `footage`, `motion_graphics` |
| `filters[duration]` | object | No | — | `from` / `to` (integer, minimum 1) |
| `filters[orientation]` | array enum | No | — | `horizontal`, `vertical`, `square`, `panoramic` |
| `filters[license]` | object | No | — | `free` / `premium` (boolean) |
| `filters[resolution]` | object | No | — | `720`, `1080`, `2k`, `4k` (boolean) |
| `filters[fps]` | array enum | No | — | `24`, `25`, `30`, `60`, `gt60` |
| `filters[topic]` | array enum | No | — | `people`, `nature`, `business`, `background`, `food`, `travel`, `sports`, `events` |
| `filters[ai-generated]` | object | No | — | `excluded` / `only` (boolean) |
| `filters[video-tool]` | object | No | — | `after-effects`, `premiere-pro` (boolean) |
| `filters[ids]` | string | No | — | — |
| `filters[author]` | integer | No | — | Minimum 1 (when present, `term` not required) |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnificApiKey` (header) | string | Yes | — | API key (note: this page documents the header as `x-magnificApiKey`) |

- **Request:**
```
GET /v1/videos?term=nature&page=1&order=relevance HTTP/1.1
Host: api.magnific.com
x-magnificApiKey: [YOUR_API_KEY]
Accept-Language: en-US
```
- **Response:**
```json
{
  "data": [
    {
      "id": 70000,
      "url": "https://www.freepik.com/free-video/white-t-shirts-copy-space-gray-background_15667335",
      "name": "Cute cat looking at the camera",
      "aspect-ratio": "16:9",
      "created": "2019-01-01T00:00:00.000Z",
      "code": "cute-cat-looking-camera",
      "quality": "720p",
      "premium": 1,
      "duration": "00:25",
      "author": {
        "id": 23,
        "name": "Magnific",
        "code": "magnific",
        "avatar": "https://avatar.cdnpk.net/23.jpg",
        "metas": {
          "downloads": 555,
          "assets": 2330000
        },
        "slug": "magnific"
      },
      "thumbnails": [
        {
          "width": 468,
          "height": 264,
          "url": "https://v4.cdnpk.net/videvo_files/video/free/video0485/thumbnails/_import_61b436a9c16290.44924640_small.jpg",
          "aspect-ratio": "16:9"
        }
      ],
      "previews": [
        {
          "width": 468,
          "height": 264,
          "url": "https://v4.cdnpk.net/videvo_files/video/free/video0485/thumbnails/_import_61b436a9c16290.44924640_small.jpg",
          "aspect-ratio": "16:9"
        }
      ],
      "active": true,
      "is_ai_generated": false,
      "item_subtype": "footage"
    }
  ],
  "meta": {
    "pagination": {
      "total": 2000,
      "per_page": 50,
      "current_page": 1,
      "last_page": 40
    }
  }
}
```
- **Credits:** Not documented for the list call (cost applies on download).
- **Gotchas:**
  - `term` is required unless the `author` filter is supplied (mutually exclusive requirement).
  - `page` must be > 0; empty query rejected.
  - Errors: 400 (page ≤ 0, empty query, invalid filters), 404 (no results), 500.

### Get Video by ID — `GET /v1/videos/{id}`
- **Purpose:** Retrieve full metadata for one video, including downloadable `options` (per-resolution renditions).
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `id` (path) | integer | Yes | — | Video id; minimum 1 (e.g. `30955`) |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/videos/30955
Accept-Language: en-US
x-magnific-api-key: [your-api-key]
```
- **Response:**
```json
{
  "data": {
    "id": 99332243,
    "url": "https://www.freepik.com/free-video/white-t-shirts-copy-space-gray-background_15667327",
    "name": "gorgeous woman stretching neck",
    "created": "2000-01-23T04:56:07.000Z",
    "code": "gorgeous-woman-stretching-neck",
    "quality": "4k",
    "premium": 0,
    "duration": "00:00:28",
    "fps": "25",
    "active": 1,
    "explicit": 0,
    "is_ai_generated": true,
    "item_subtype": "footage",
    "aspect_ratio": "16:9",
    "author": {
      "id": 2147483647,
      "name": "John Doe",
      "code": "merry-christmas",
      "avatar": "https://avatar.cdnpk.net/61668527-220726032514.jpg",
      "slug": "merry-christmas",
      "metas": {"downloads": 0, "assets": 0}
    },
    "thumbnails": [{"url": "https://img.freepik.com/free-photo/image_8353-7579.jpg", "width": 100, "height": 100, "aspect_ratio": "16:9"}],
    "previews": [{"url": "https://v1.cdnpk.net/videvo_files/video/premium/video0289/watermarked/_Geometric80s30_FPpreview.mp4", "width": 100, "height": 100, "aspect_ratio": "16:9"}],
    "tags": [{"name": "Merry Christmas", "slug": "merry-christmas"}],
    "options": [{"id": 76989, "active": true, "width": 4096, "height": 2304, "quality": "4k", "container": "mp4", "codec": "AVC Coding", "bit_rate": 25.44, "size": 400, "aspect_ratio": "16:9", "is_original": true}]
  }
}
```
- **Credits:** Not documented (cost applies on download).
- **Gotchas:**
  - `options[]` lists available renditions (width/height/quality/codec/bit_rate/size/`is_original`).
  - Errors: 400 (invalid parameters), 404 ("Video not found"), 500.

### Download a Video — `GET /v1/videos/{id}/download`
- **Purpose:** Get a direct download URL for a video asset.
- **Submit/Status:** Synchronous GET.
- **Parameters:**

| Param | Type | Req | Default | Allowed / Notes |
|-------|------|-----|---------|-----------------|
| `id` (path) | integer | Yes | — | Video id; minimum 1 (e.g. `30955`) |
| `Accept-Language` (header) | string | No | `en-US` | ISO 639-1 + ISO 3166-1 |
| `x-magnific-api-key` (header) | string | Yes | — | API key |

- **Request:**
```
GET /v1/videos/30955/download
x-magnific-api-key: [your-api-key]
Accept-Language: en-US
```
- **Response:**
```json
{
  "data": {
    "filename": "_import_61490450321f37.49858282.mov",
    "url": "https://joy1.videvo.net/verify_download_video.php?path=video/free/video0466&vid=_import_61490450321f37.49858282.mov&source=freepik&videvo_id=1109082&filename=1109082_1080p_4k_2k_4096x2160.mov&verify=lkdadslfjads3434"
  }
}
```
- **Credits:** Not documented numerically; download consumes credits / counts against limits (see 429).
- **Gotchas:**
  - No format/resolution query parameters are exposed on this endpoint — it returns a single direct download URL.
  - Errors: 403 ("The user cannot download this item because it is premium"), 404 ("Video not found" or "Video with provided id has not associated assets"), 429 (download limits exceeded).

