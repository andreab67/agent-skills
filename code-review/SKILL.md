---
name: code-review
description: "Adversarially-verified multi-angle code review. Use when asked to review code — a working diff, branch, MR/PR, or commit range — or before merging or shipping changes. Fans ten review angles (five bug-hunting, five quality) out to cheap subagents, verifies every candidate finding adversarially, sweeps for coverage gaps, and reports only confirmed findings ranked by severity."
---

# Code Review

**Contract:** review a diff; report only findings that survive adversarial verification. Never pad — "no confirmed findings" is a valid, complete result.

## 0. Scope the diff

- Default target: working tree + staged changes vs the merge-base with the default branch. Include untracked files.
- If the user names an MR/PR, branch, or commit range, review that instead (GitLab: `glab` or the API; GitHub: `gh`).
- Empty diff → say so and stop.

## 1. Cost model — cheap subagents do the reading

The model running this skill is the **orchestrator**: it scopes, briefs, judges verdicts, and writes the report. All bulk reading — angle scans and verification — is delegated to the **cheapest capable subagent tier** the host offers, to keep review cost low. Track progress with a todo list (one item per angle, plus the two later phases). If the host cannot spawn subagents, run the same briefs yourself as sequential focused passes — one angle at a time, never merged. Host-specific mechanics: `references/hosts.md`.

## 2. Phase 1 — Find (10 angles, in parallel)

Each angle agent gets: the full diff, the repo root, and its single angle brief below. It returns **candidates** — `{file, line, claim, evidence, severity guess}` — not verdicts.

Bug angles:

- **Angle A — line-by-line diff scan:** read every hunk literally: inverted or off-by-one conditions, wrong variable, bad copy-paste, typos in strings/keys/paths.
- **Angle B — removed-behavior auditor:** for every deleted or rewritten line, what did the old code do that the new code doesn't? Who depended on it?
- **Angle C — cross-file tracer:** for every changed symbol, signature, or contract, find all callers/callees in the repo; flag stale call sites and broken assumptions.
- **Angle D — language-pitfall specialist:** footguns of the diff's languages (mutable defaults, async races, encoding, timezones, integer division, truthiness of empty containers, shell quoting…) — only where the diff actually exhibits them.
- **Angle E — wrapper/proxy correctness:** anything wrapping, forwarding, or adapting another interface — are args, defaults, errors, return shapes, and edge cases preserved?

Quality angles:

- **Reuse:** logic the codebase already provides; new helpers duplicating existing ones.
- **Simplification:** needless branches, dead code, over-abstraction introduced by the diff.
- **Efficiency:** introduced N+1 queries, quadratic loops, repeated IO, waste on hot paths.
- **Altitude:** is the change at the right layer — source vs symptom, config vs code, right module?
- **Conventions:** violations of rules the repo's CLAUDE.md / AGENTS.md / style docs explicitly state. Cite the rule.

## 3. Phase 2 — Verify candidates

Dedupe overlapping candidates, then for each spawn a cheap **skeptic** briefed to REFUTE it against the actual code, defaulting to refuted when uncertain. Auto-refute: pre-existing issues the diff didn't introduce; anything a linter/typechecker/compiler catches; intentional behavior changes the rest of the diff supports; nitpicks a senior engineer wouldn't raise; rules explicitly silenced in code. A finding survives only with a concrete failure scenario — specific inputs/state → wrong outcome — verified in the code. The orchestrator reads each verdict's evidence and makes the final keep/kill call.

## 4. Phase 3 — Sweep for gaps

List what Phase 1 did not cover: diff files no angle fully read; affected tests, migrations, configs, docs; TODO/FIXME left in the diff; generated-vs-source drift. Run one targeted pass per gap; route new candidates back through Phase 2.

## 5. Report

Severity-ranked, most severe first: **critical** (breaks correctness/security/data) → **major** (wrong under realistic conditions) → **minor** (real but low impact). Each finding: one-sentence claim, `file:line`, and its concrete failure scenario. Confirmed findings only — plausible-but-unverified items get one footnote line or nothing. If nothing survives, state "No confirmed findings", plus one line on what was checked.
