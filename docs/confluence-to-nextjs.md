# confluence-to-nextjs

Migrates Atlassian Confluence pages to a self-hosted Next.js knowledge base. Knows the Confluence REST API v2 storage format, the JSX conversion rules, and the component patterns needed to produce a polished, navigable KB site.

## Install

```bash
npx skills add andreab67/agent-skills@confluence-to-nextjs -g -y
```

## What it does

Guides the full migration workflow: fetch pages via the Confluence REST API, parse Confluence-specific HTML (`<ac:structured-macro>`, `<ri:attachment>`) into semantic JSX, build anchor navigation from headings, and wire up a sticky table of contents with active-section tracking. The output is a standalone Next.js App Router app (`apps/kb/`) that can be added to an existing monorepo.

## Migration workflow

| Step | What happens |
|------|-------------|
| **1. Fetch** | `curl` with personal API token → raw Confluence storage-format HTML |
| **2. Parse** | Map Confluence tags to JSX equivalents (headings → anchored headings, macros → callout divs, tables → styled tables) |
| **3. Build page** | Each Confluence page becomes one `page.tsx` file in `app/<slug>/` |
| **4. Table of contents** | `TableOfContents` component with `IntersectionObserver` for active-section highlighting |
| **5. Update links** | Replace `atlassian.net/wiki/...` URLs site-wide with internal `/kb/<slug>#anchor` routes |
| **6. Test** | Vitest + React Testing Library tests per page checking headings, anchor IDs, and table content |

## Example prompts

- *"I want to replace our Confluence KB with a self-hosted Next.js site. Where do I start?"*
- *"How do I fetch a Confluence page's content via the REST API?"*
- *"Show me how to convert a Confluence storage-format table to JSX."*
- *"Generate the TableOfContents component with IntersectionObserver for active-section tracking."*
- *"I have a Confluence macro `<ac:structured-macro ac:name="info">` — what does it become in JSX?"*
- *"Write a Vitest test for the support-maintenance KB page that checks anchor IDs."*

## Key conversion rules

| Confluence HTML | JSX output |
|----------------|-----------|
| `<h2>` with text | `<h2 id="slugified-text">` |
| `<ac:structured-macro name="info">` | `<div className="info-callout">` |
| `<table>` | `<table className="kb-table">` |
| `<ac:link>` | Removed or replaced with external link |
| `<strong>`, `<em>`, `<code>` | Passed through unchanged |

## Prerequisites

- A Confluence Cloud account with a personal API token
- An existing Next.js monorepo (or willingness to scaffold one)
- Page IDs from the Confluence URL (`/wiki/spaces/SPACE/pages/PAGE_ID`)

## What it won't do

- Real-time sync (this is a one-time or periodic migration, not a live embed)
- Non-Confluence CMS sources (WordPress, Notion, etc.)
- WYSIWYG editing of the migrated content

## Related skills

- [`nextjs-monorepo-ci`](./nextjs-monorepo-ci.md) — add the `apps/kb` app to CI
- [`k8s-nextjs-deploy`](./k8s-nextjs-deploy.md) — deploy the KB app to Kubernetes
