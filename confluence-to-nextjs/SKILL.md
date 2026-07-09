---
name: confluence-to-nextjs
description: Convert Atlassian Confluence pages to native Next.js App Router pages — fetch content via Confluence REST API v2, parse storage-format HTML into semantic JSX, build a knowledge base with table of contents, anchor navigation, and matching design system. Use this skill whenever the user mentions Confluence migration, converting Confluence docs to Next.js, building a KB site from Confluence content, or replacing Atlassian-hosted pages with a self-hosted knowledge base — even if they just say "move our docs off Confluence" or "build a KB app".
---

# confluence-to-nextjs

Migrate Atlassian Confluence documentation to a self-hosted Next.js knowledge base. Fetches pages via the Confluence REST API, converts HTML storage format to semantic JSX, and wires up anchor navigation and a sticky table of contents.

## When to use

- Replacing external Confluence URLs in a product site with internal `/kb` routes
- Building a public knowledge base from Confluence content
- Porting support docs, deployment guides, or product documentation to Next.js

Do NOT use for:
- Wiki content that changes frequently and needs real-time sync (use Confluence embed instead)
- Non-Confluence CMS sources (use a different migration approach)

## Step 1: Fetch Confluence content

Use `scripts/fetch-page.sh` rather than hand-rolling the curl call — it pins `body-format=storage` (never `view` — see Anti-pattern 1), checks the HTTP status, and fails loudly with the response body on 401/403/404 instead of silently writing an error payload to disk:

```bash
CONFLUENCE_EMAIL=user@example.com CONFLUENCE_TOKEN=ATATT3x... \
  ./scripts/fetch-page.sh your-org PAGE_ID page.json
```

The `storage` format returns HTML with Confluence-specific tags (`<ac:structured-macro>`, `<ac:parameter>`, `<ri:attachment>`) that must be stripped and converted.

## Step 2: Storage format → JSX conversion rules

| Confluence HTML | JSX equivalent |
|----------------|---------------|
| `<h1>`, `<h2>`, `<h3>` with text | `<h1 id="slug">`, `<h2 id="slug">` (slugify for anchor nav) |
| `<ac:structured-macro ac:name="info">` | `<div className="info-callout">` |
| `<table>` | `<table className="kb-table">` |
| `<ac:link>` internal links | Remove or replace with external link |
| `<strong>`, `<em>`, `<code>` | Pass through as-is |
| `<ul>`, `<ol>`, `<li>` | Pass through as-is |

Slug generation for heading IDs — use `scripts/slugify.mjs` rather than reimplementing it per migration; it also dedupes collisions (Anti-pattern 6) via `dedupeSlugs()`:

```bash
node scripts/slugify.mjs "Standard Support Contract"   # -> standard-support-contract
node scripts/slugify.mjs --file headings.txt           # dedup a whole page's headings in order
```

## Step 3: Page structure

Each knowledge base page follows this layout:

```tsx
// app/support-maintenance/page.tsx
import type { Metadata } from "next";
import { TableOfContents } from "@/components/toc";

export const metadata: Metadata = {
  title: "Support & Maintenance",
  description: "SLA tiers, response times, and maintenance windows.",
};

const tocItems = [
  { id: "definitions", label: "Definitions", level: 2 },
  { id: "standard-support-contract", label: "Standard Support", level: 2 },
  { id: "gold-support-contract", label: "Gold Support", level: 2 },
];

export default function SupportMaintenancePage() {
  return (
    <section className="section inner-hero">
      <div className="container section">
        <div className="article-layout">
          <div className="article-content">
            <h2 id="definitions">Definitions</h2>
            <p>...</p>
            <table className="kb-table">
              <thead><tr><th>Priority</th><th>Description</th></tr></thead>
              <tbody>...</tbody>
            </table>
          </div>
          <TableOfContents items={tocItems} />
        </div>
      </div>
    </section>
  );
}
```

## Step 4: Table of contents component

Sticky sidebar with `IntersectionObserver` for active heading tracking:

```tsx
"use client";

import { useEffect, useState } from "react";

interface TocItem { id: string; label: string; level: number; }

export function TableOfContents({ items }: { items: TocItem[] }) {
  const [active, setActive] = useState<string>("");

  useEffect(() => {
    const observers = items.map(({ id }) => {
      const el = document.getElementById(id);
      if (!el) return null;
      const obs = new IntersectionObserver(
        ([entry]) => { if (entry.isIntersecting) setActive(id); },
        { rootMargin: "-20% 0px -70% 0px" }
      );
      obs.observe(el);
      return obs;
    });
    return () => observers.forEach((o) => o?.disconnect());
  }, [items]);

  return (
    <nav className="toc-sidebar" aria-label="On this page">
      <p className="toc-title">On this page</p>
      <ul>
        {items.map(({ id, label, level }) => (
          <li key={id} className={`toc-item level-${level} ${active === id ? "active" : ""}`}>
            <a href={`#${id}`}>{label}</a>
          </li>
        ))}
      </ul>
    </nav>
  );
}
```

## Step 5: Update source URLs

Replace Confluence links across the product site with KB routes:

```typescript
// Before (in site-data.ts, pricing.ts, etc.)
discoverUrl: "https://your-org.atlassian.net/wiki/spaces/SPACE/pages/12345"

// After
discoverUrl: `${process.env.NEXT_PUBLIC_KB_URL ?? "https://kb.example.com"}/deployment-motions#docker`
```

Anchor IDs must match the `id` attributes on the converted headings.

## Step 6: KB app scaffold

Minimal Next.js app for the knowledge base:

```
apps/kb/
├── app/
│   ├── layout.tsx          # SiteHeader + SiteFooter + GA script
│   ├── page.tsx            # Article index / home
│   ├── robots.ts
│   ├── sitemap.ts
│   └── <article-slug>/
│       └── page.tsx        # One file per Confluence page
├── components/
│   ├── site-header.tsx
│   ├── site-footer.tsx
│   └── toc.tsx             # TableOfContents
├── lib/
│   └── kb-data.ts          # Article metadata array
├── __tests__/              # Vitest + RTL tests per page
├── Dockerfile
└── package.json
```

Add the app to CI and K8s following the `nextjs-monorepo-ci` and `k8s-nextjs-deploy` skills.

## Testing converted pages

Each page needs a Vitest test checking:
1. H1 heading renders
2. Key section headings exist with correct anchor IDs
3. Tables contain expected content
4. TOC renders

```typescript
import { render, screen } from "@testing-library/react";
import SupportMaintenancePage from "@/app/support-maintenance/page";

vi.mock("@/components/toc", () => ({
  TableOfContents: () => <nav data-testid="toc" />,
}));

it("renders standard support anchor", () => {
  render(<SupportMaintenancePage />);
  const h = screen.getByRole("heading", { name: /Standard Support Contract/ });
  expect(h.id).toBe("standard-support-contract");
});
```

When a heading appears at multiple levels (h2 + h3 with similar text), use `{ level: 2 }` in the query to avoid `Found multiple elements` errors.

## Anti-patterns

These look reasonable during a Confluence migration but cause broken pages or stale content:

1. **Fetching in `body-format=view` instead of `body-format=storage`** — `view` returns rendered HTML with session-relative image URLs and Confluence CDN paths that are unauthenticated and will 404 in production. Always use `storage` format and handle the `<ac:*>` macros explicitly.
2. **Using heading text as anchor IDs without slugification** — Confluence heading anchors can contain spaces, special characters, and accents. Using heading text directly as `id=` attributes breaks `#fragment` links. Always run the text through `slugify()` and store the mapping.
3. **Assuming the `sub` UUID in headings is stable across page versions** — Confluence internally uses UUID-based heading IDs in some contexts; these change when content is edited. Base your anchor IDs on the visible heading text, not on any Confluence internal identifier.
4. **Building the Table of Contents from static render rather than `IntersectionObserver`** — a static list of links scrolls fine but shows no active state. The `IntersectionObserver` approach in Step 4 is non-negotiable for UX parity with Confluence's native sidebar.
5. **Migrating pages with `<ac:structured-macro name="include">` transclusion** — Confluence's include macro pulls content from other pages at render time. In a static Next.js migration, the included content must be inlined at build time or fetched as a separate API call. Treating it as a simple HTML element will produce a broken macro tag in production.
6. **Not deduplicating `id` attributes across a page** — when Confluence content has two headings with the same text (e.g., two "Overview" sections in a long doc), both will get `id="overview"`, breaking anchor navigation. Append a numeric suffix on collision: `overview`, `overview-2`, etc.
7. **Forgetting to update `next-sitemap.config.js`** — migrated KB pages won't appear in Google's index until the sitemap lists them. Add the new routes explicitly or ensure the dynamic route is covered by the sitemap generation logic.

## Error Handling

Realistic failure modes when running a Confluence migration, how to detect them, and how to recover:

1. **401/403 from the REST API** — invalid or expired personal API token, or the page lives in a restricted space. Detect: the response body is `{"statusCode":401,...}` or `403`. Recovery: regenerate the token in Atlassian account settings, or get a space admin to grant read access before retrying.
2. **404 on `pages/PAGE_ID`** — wrong page ID, or the ID belongs to a different Confluence site/cloud instance. Detect: JSON body `{"statusCode":404}`. Recovery: re-derive the page ID from "..." → "Page information" (`pageId=` in that URL), not from the pretty URL slug.
3. **429 rate limiting on bulk exports** — hit when migrating many pages in a tight loop. Detect: HTTP 429 with a `Retry-After` header. Recovery: back off per the header and batch requests in small groups instead of fetching the whole space at once.
4. **Unmapped `<ac:structured-macro>` types** — the conversion table in Step 2 only covers `info`. Macros like `note`, `warning`, `expand`, `code`, or `jira` pass through as raw `<ac:structured-macro>` tags. Detect: build fails on an unknown tag, or the macro renders as literal markup in the browser. Recovery: extend the conversion table per macro name before converting the page — don't blind-strip unfamiliar macros.
5. **Broken image/attachment links** — `<ri:attachment>` references Confluence-hosted binaries that the page-body API doesn't return inline. Detect: `<img>` 404s against the Confluence CDN in production (unauthenticated). Recovery: fetch attachments separately via `/wiki/api/v2/pages/{id}/attachments`, download into `public/`, and rewrite `src` to the local path.
6. **Malformed storage HTML breaks JSX parsing** — unclosed tags or stray entities from Confluence's rich text editor aren't valid JSX. Detect: build-time JSX syntax error pointing at the converted file. Recovery: normalize the storage HTML (balance tags, escape entities) before hand-authoring the `.tsx`, rather than pasting raw storage output directly.
7. **Internal `<ac:link>` targets not yet migrated** — linking to a Confluence page that hasn't been converted produces a dead `/kb/...` route. Detect: 404 when clicking through during review. Recovery: keep a migration tracking table (Confluence page ID → KB route) and point unconverted links at the original Confluence URL until that page ships.

## Example prompts

- *"I want to replace our Confluence KB with a self-hosted Next.js site. Where do I start?"*
- *"How do I fetch a Confluence page's content via the REST API?"*
- *"Show me how to convert a Confluence `<ac:structured-macro name='info'>` callout to JSX."*
- *"Generate the TableOfContents component with IntersectionObserver for active-section tracking."*
- *"Write a Vitest test for the support-maintenance KB page checking anchor IDs."*
- *"How do I replace Confluence URLs across the product site with internal KB routes?"*

## Related skills

- [`nextjs-monorepo-ci`](./nextjs-monorepo-ci/SKILL.md) — add the `apps/kb` Next.js app to the CI pipeline
- [`k8s-nextjs-deploy`](./k8s-nextjs-deploy/SKILL.md) — deploy the KB app to Kubernetes
