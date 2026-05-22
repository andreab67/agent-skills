# Contributing

Bug reports, fixes, and new skills welcome. The repo is BSD-3-Clause so anything you contribute lands under that license.

## Reporting a bug in an existing skill

Open an issue with:

- Which skill (`postgres-ops`, `loki-best-practices`, etc.) and what version you have installed (`npx skills list -g`).
- The exact prompt or scenario where the skill misfired — either didn't trigger when it should have, triggered when it shouldn't have, or gave wrong/incomplete output.
- Claude model + interface (Claude Code CLI, Claude.ai web, IDE extension).
- For wrong-output bugs: what the skill recommended and what the right answer would have been, with a sentence on how you know.

The most valuable bug reports are the ones where the skill *almost* worked — those are the cases description-tuning or a single instruction edit will fix.

## Proposing a new skill

A new skill belongs in this repo if it:

- Captures **real operational knowledge** from production work, not surface-level tutorials. The bar is "this would have saved me 3 hours during an incident."
- Has a clear **trigger condition** — when should Claude reach for it vs. handle the task directly? If you can't write a tight description, the skill probably needs to be smaller or split.
- Is **distinct from the existing skills** (see [`README.md`](./README.md) for the current table). If it overlaps, propose a merge or a section addition to the existing one instead.

Open an issue first with the proposed name + description + a paragraph on the trigger surface. We'll iterate on scoping before you write the full SKILL.md — most of the work is in the framing, not the prose.

## Submitting a PR

### Layout

Each skill is a directory at the repo root:

```text
skill-name/
└── SKILL.md       (required — YAML frontmatter + markdown body)
```

Plus a matching docs page:

```text
docs/
└── skill-name.md
```

And one row added to the table + install loop in [`README.md`](./README.md).

### SKILL.md frontmatter

```yaml
---
name: skill-name                       # kebab-case, matches directory
description: <one paragraph — when to trigger, what it does, what NOT to use it for>
---
```

The `description` is the entire triggering signal. Be specific about real user phrasings that should activate the skill, and explicit about the adjacent cases that should *not*. Skills under-trigger by default — err on the side of being a little pushy in the description.

### SKILL.md body

Mirror the structure of an existing skill (`postgres-ops` and `loki-best-practices` are the current reference templates):

1. **Title + 1–2 sentence positioning** — who the skill is for, what mindset it primes.
2. **When to use / When not to use** — bulleted, concrete.
3. **Instructions** — numbered sections, each with rationale (the *why*) not just rules. Heavy-handed `MUST`/`NEVER` is a yellow flag; explain the cost of getting it wrong and trust the model.
4. **Output discipline** — what good output looks like, what to flag explicitly (destructive ops, version-specific behavior, missing context).
5. **Example prompts** — 5–8 real things a user would actually type.
6. **Related skills** — link to neighbors so the model knows when to hand off.

Keep SKILL.md under ~500 lines. If you're going over, move reference material into a `references/` subdirectory and point the model there from the main body.

### Voice

- Senior engineer reading senior engineer. Skip the intro material.
- Show runnable commands with no placeholder values unless you also show how to compute them.
- Call out destructive operations explicitly.
- Cite version-specific behavior with the version where it changed.

### Tests

Skills don't ship with a test harness in this repo (yet), but before you open the PR, run the skill against 2–3 realistic prompts with the [`skill-creator`](https://github.com/anthropics/skills) workflow or just by invoking it in Claude Code and sanity-checking the output. PR description should include those prompts and a one-line note on the output for each.

### Commit + PR

- One skill per PR. Don't bundle.
- Conventional commit header (`feat:`, `docs:`, `fix:`).
- PR body should explain *what operational problem the skill solves* and link to the issue where scoping was agreed.

## Editing an existing skill

Small fixes (typos, tightening a description, adding an example prompt): just open the PR. No issue needed.

Behavioral changes (changing what the skill recommends, removing a section, expanding scope): open an issue first. These show up immediately for everyone who has the skill installed, so we want to think about regressions.

## License

By contributing you agree your contribution is licensed under [BSD 3-Clause](./LICENSE).
