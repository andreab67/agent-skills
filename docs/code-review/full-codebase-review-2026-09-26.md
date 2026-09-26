# Full codebase review — 2026-09-26

## Executive summary

**Terminal status: READY FOR MERGE (pending owner action on tags; see Blockers).** Only the proposal to merge was made; nothing was merged.

The review covered all 57 tracked files of `andreab67/agent-skills` over four passes. **43 findings were confirmed and fixed**: 2 critical, 12 high, 13 medium and 16 low. Four candidates were rejected as invalid or intentional. One item, the stray `v1.0.0` tag, is blocked on an action only the owner can take.

The most serious defects were in scripts users run:
- The Ubuntu 24.04 STIG remediation script enabled UFW with no SSH allow rule, which locks you out remotely.
- The same script wrote `faillock.conf` without wiring `pam_faillock`, so failed-login lockout never applied.
- The session-handoff `/clear` hook blocked every other prompt in a session.
- The CI skill's obfuscation step silently obfuscated nothing.
- The CI skill's Kaniko template never built or pushed an image.

The SDK skills also had pricing tables that were wrong by 2–3x.

At the owner's request, the `anthropic-sdk` skill was renamed to `messages-api-sdk`. Skill names may not contain the reserved words "anthropic" or "claude". This is a **breaking change** for existing installs.

## Repository and range

| | |
|---|---|
| Repository | `andreab67/agent-skills` |
| Target branch | `main` |
| Base SHA | `4265a4dc9b2340115225786cd00156cfd38bb257` |
| Review branch | `code-review/full-codebase-review-20260926-1340` |
| Reviewed range | `4265a4d..HEAD` (22 commits; the report commit is the last) |

**Initial Git state.** The clone was fresh and shallow, on `main` with a clean tree and upstream `origin/main`. Isolation came from creating the review branch in place; no worktree was needed because the tree was clean. Full history and tags were fetched later to investigate the tags.

## Scope

- **Languages and content:**
  - Markdown skill definitions: 15 `SKILL.md` files, 15 `docs/*.md` pages, and `references/`.
  - Bash: `confluence-to-nextjs/scripts/fetch-page.sh` and `ubuntu24-stig/remediate-mac2-sensitive.sh`.
  - Node ESM: `slugify.mjs` and `session-handoff-gate.js`.
  - Embedded code samples in Python, TypeScript, JavaScript, YAML (Kubernetes and GitLab CI), SQL and shell.
- **Coverage:** all 57 tracked files were reviewed in pass 1. None were excluded (no generated, vendored or binary files).
- **Partition ownership in pass 1:**
  - Sonnet workers:
    - A: scripts, STIG, session-handoff, confluence
    - B: Anthropic/OpenAI/Kilo/OpenRouter SDK skills
    - C: magnific and its 6 references
    - D: postgres, loki, k8s, CI, arcgis, login-gov, code-review
  - Opus: cross-cutting review of README, CHANGELOG, CONTRIBUTING, LICENSE, all docs pages, frontmatter and cross-skill links.
  - Opus skeptic: verified the version- and price-sensitive and contract-sensitive candidates against official vendor pages.
- **Pass 2:** three Sonnet workers re-covered every file, and an independent Opus agent challenged the full branch diff.
- **Passes 3–4:** each used a fresh independent Opus challenger over the full branch diff plus a whole-repo validation sweep. The files not changed after pass 2 had come back clean from the pass-2 full-coverage review.

## Baseline validation

The repo has no native CI or test harness; CONTRIBUTING says as much. The baseline was therefore these checks:
- `bash -n` and `shellcheck` on `*.sh`
- `node --check` on `*.js` and `*.mjs`
- YAML frontmatter parsing, `name`==dir, description length and keys
- README table, install list and loop compared with the skill directories
- Relative-link resolution
- Syntax checks on fenced code (bash, python, js, json, yaml)
- `agentskills validate` (the skills-ref reference validator for the Agent Skills spec)

The baseline showed:
- shellcheck: SC2038 once.
- Two descriptions over the 1024-character spec limit.
- 15 broken cross-skill links.
- Fence noise: `<placeholder>` bash and intentional non-JSON placeholders.
- `agentskills validate`: 2 of 15 skills failed (magnific, postgres-ops).

## Findings and disposition

Severity scale: critical, high, medium, low. All findings are **fixed** unless marked otherwise.

| ID | Sev | Location | Defect | Fix commit |
|---|---|---|---|---|
| A1 | critical | ubuntu24-stig/remediate-mac2-sensitive.sh | `ufw --force enable` ran with no SSH allow rule. `DEFAULT_INPUT_POLICY=DROP`, so new SSH connections were refused (remote lockout). | de9e0ed, 12ebe15 |
| A2 | critical | session-handoff hook, clear-hook.md, SKILL.md | `UserPromptSubmit` ignores matchers, and the script never read `prompt`, so every other prompt was blocked. The block reason also went to the user, not the agent. | 1213b9d |
| A3 | high | ubuntu24-stig script + SKILL.md | `faillock.conf` was written but `pam_faillock` was never added to the PAM stack (noble ships no pam-auth-update profile), so lockout was inert. | de9e0ed |
| A4 | high | confluence-to-nextjs/scripts/slugify.mjs | `dedupeSlugs(["a","a","a-2"])` produced a duplicate `a-2` anchor. | fe14b38 |
| O1 | high | magnific, postgres-ops SKILL.md | Descriptions of 1159 and 1102 characters exceed the spec's 1024 limit, so `skills-ref validate` and claude.ai upload fail. | a39bb53, c6042c5 |
| O2 | high | openrouter/references/* | About 310 KB of scraped Next.js 404 pages were advertised as the model reference. | f7987c2 |
| B1 | high | anthropic-sdk estimate_cost | KeyError for the exact Haiku ID the table recommends. | f114685 |
| B4/B5/O4 | high | anthropic-sdk table, README, docs | Opus 4.8 listed at $15/$75 (actual $5/$25). Haiku 4.5 listed at $0.80/$4 (actual $1/$5). Fable 5 shown as "$—". Docs listed Opus 4.7 at $15/$45. | f114685, 580ade4 |
| B2 | high | openai-sdk table, estimate_cost | gpt-4o listed at $5/$15 (actual $2.50/$10) and o3 at $10/$40 (actual $2/$8). o1 shutdown not noted. Current lineup missing. | f114685 |
| B3 | high | openrouter TS fallback sample | Top-level `models` fails to compile against openai-node (TS2769). | 7393905 |
| C1 | high | magnific `wait()` | `r.json()["data"]` raised KeyError on the unwrapped Style Transfer response. | a39bb53 |
| D1 | high | login-gov scope table | `verified_at` requires the `profile:verified_at` scope. | 4173eab |
| D2 | high | nextjs-monorepo-ci `.kaniko_package` | No `script:`, so no image was ever built or pushed. | fa9f622 |
| F3-1 | high | nextjs-monorepo-ci `.app_obfuscate` | Unescaped `find -path "*[turbopack]*"` is a glob character class that excluded every file, so nothing was obfuscated. Present before this branch. | d137e7e |
| A5 | medium | fetch-page.sh | `curl -s` combined with `set -e` exited silently on network errors. | fe14b38 |
| A6 | medium | fetch-page.sh | API token passed on curl's argv, visible in `ps`. | fe14b38 |
| A7 | medium | ubuntu24-stig script | `apt-get … \| grep … \|\| true` masked install failures. | de9e0ed |
| B6 | medium | openai-sdk anti-pattern 5 | Stale claim about tiktoken raising KeyError for o1/o3. | f114685 |
| C2 | medium | magnific webhook verifiers | No timestamp tolerance, so stale requests could be replayed. | a39bb53 |
| O3 | medium | 15 links in 7 SKILL.md files | `./other/SKILL.md` links were always broken. | ff9546e |
| O4b | medium | anthropic-sdk count_tokens | Labelled "No API Call", but it is a POST to `/v1/messages/count_tokens`. | f114685 |
| O5 | medium | k8s-nextjs-deploy namespace recovery | Deployments were applied before secrets were recreated. | ad0c1e6 |
| O6 | medium | 4 SDK/gateway descriptions | No when/when-not triggers (CONTRIBUTING requires them). Stale "400+". | f114685, 7393905 |
| O7 | medium | bundled scripts | Mode 100644, and invoked relative to cwd instead of the skill directory. | 58a124d, fe14b38 |
| CH-1 | medium | nextjs-monorepo-ci | New `needs: [obfuscate-*]` pointed at a job with no artifacts. | c849bc6 |
| CH-2 | medium | ubuntu24-stig UFW port detection | `ListenAddress host:port` and ssh.socket ports were missed. | 12ebe15 |
| F3-2 | medium | nextjs-monorepo-ci `.app_obfuscate` | Missing the `main` rule, so it failed on other branches. | d137e7e |
| O8 | low | anthropic-sdk name | Reserved word in the name. Renamed to `messages-api-sdk` at the owner's direction (BREAKING). | 580ade4 |
| O9 | low | k8s-nextjs-deploy, login-gov | Advertised Linkerd and SAML coverage the body doesn't have. | ad0c1e6, 4173eab, 50e7e2c |
| O10 | low | CHANGELOG | Wrong historical counts; loki missing from v1.0. | 03a8a65 |
| O11 | low | docs/confluence-to-nextjs.md, docs/postgres-ops.md | Docs drift (`ac:name`, fetch method, duplicated "Flyway"). | fe14b38, c6042c5 |
| O12 | low | postgres-ops, docs/code-review | Hand-offs to skills not in this catalog. | c6042c5 |
| O13 | low | CONTRIBUTING | `npx skills list -g` shows no version. | 580ade4 |
| X1 | low | slugify.mjs | main-guard crashed when `process.argv[1]` is undefined. | fe14b38 |
| X2 | low | slugify.mjs | Non-ASCII headings produced an empty or mangled id. | fe14b38 |
| P2A-2 | low | login-gov | SAML scope contradicted between description, body and docs. | 50e7e2c |
| CH-3 | low | openai-sdk | `count_message_tokens` raised KeyError for gpt-6-*; tiktoken versions wrong. | 719283b, c60b406 |
| CH-4 | low | openai-sdk | Stale "32× cheaper". | 719283b |
| CH-5 / F4-1 | low | CHANGELOG | Report link dangling; v1.8 entry understated the CI fixes. | this report commit |
| F3-3 | low | openai-sdk | gpt-5 exact key needs tiktoken ≥ 0.12.0. | c60b406 |
| F3-4 | low | ubuntu24-stig SKILL.md UFW snippet | Weaker than the script. | c60b406 |
| F3-5 | low | docs/login-gov.md | SAML line out of date. | c60b406 |
| A8 | — | STIG `ENCRYPT_METHOD` | **Invalid / intentional.** The STIG check reads `login.defs`. | — |
| A9 | — | STIG SC2038 find\|xargs | **Accepted.** Fixed, trusted set of binary names; no failure scenario. | — |
| O14 | — | non-ASCII in descriptions | **Invalid.** The spec and official docs don't require ASCII. Rewritten descriptions are ASCII anyway. | — |
| P2A-1 | — | hook exit code | **Invalid.** Official hooks docs: `UserPromptSubmit` with exit 0 and stdout `{"decision":"block"}` blocks and erases the prompt. | — |
| O10b | — | git tag `v1.0.0` → v1.7 commit | **Blocked.** The session's git proxy returns 403 on tag pushes. The owner must run the commands under Blockers. | — |

## Fix details and tests

- **ubuntu24-stig**
  - SSH ports are taken as the union of the `port` and `listenaddress` lines from `sshd -T` and `ssh.socket`'s `Listen=`, with a fallback of 22. Each is allowed before `ufw --force enable`.
  - `pam_faillock` preauth/authfail/authsucc lines go into `common-auth` just before the primary block's `pam_deny`. That position is correct whether or not pam_sss is present.
  - The `account` line goes into `common-account`.
  - The edit is idempotent and fails loudly if the anchor line is missing.
  - `apt-get` exit status is now honoured.
  - Verified with scratch-copy harnesses (stock noble and sssd variants, rerun, missing anchor) and with **pamtester against real PAM on Ubuntu 24.04**:
    - correct, wrong and post-failure logins
    - sss success and failure
    - 3 failures lock the account
- **session-handoff**
  - The script filters on `/clear` itself and blocks through stdout JSON with exit 0.
  - Non-`/clear`, malformed and empty input exit 0 with no state written.
  - `clear-hook.md` embeds a byte-identical copy of the script.
  - A caveat notes that delivery of `/clear` to `UserPromptSubmit` is not documented, so verify it locally.
- **confluence-to-nextjs**
  - `dedupeSlugs` now uses a Set of emitted slugs.
  - Slugs are NFKD-normalized, with a `section` fallback.
  - The main-guard no longer crashes when `process.argv[1]` is undefined.
  - `curl -sS -K -` carries the credentials, verified against a local server with tokens containing `"`, `\` and spaces.
  - Scripts are marked `+x` and invoked as `<this-skill-dir>/scripts/…`.
- **messages-api-sdk (formerly anthropic-sdk) and openai-sdk**
  - Model tables, `estimate_cost` (keyed by full ID, `ValueError` on an unknown model) and docs now match the official pricing pages of 2026-09-26.
  - The tiktoken fallback is in place.
  - Every Python fence passes `py_compile`, and both cost helpers were run for every model in their tables.
- **openrouter**
  - The junk reference files are removed.
  - The TS sample compiles under `tsc --strict` with current openai-node.
- **magnific**
  - Description is now 895 characters.
  - `wait()` handles both response shapes.
  - Python and Node verifiers were tested: valid, tampered, stale, non-numeric timestamp, multiple signatures, and cross-language interop.
- **nextjs-monorepo-ci**
  - The obfuscate `find` works (tested with bash, dash and busybox `find`).
  - Obfuscate artifacts are published, and the obfuscate job is gated on `main`.
  - Kaniko `script:` added.
  - All YAML blocks parse.
- **Repo docs**
  - README rows, install lines and loop are synced.
  - CONTRIBUTING documents the `../` link form, the reserved words and the 1024-character limit.
  - CHANGELOG has a v1.8 entry and corrected history.

## Validation (final HEAD)

| Command | Result |
|---|---|
| `agentskills validate <dir>` ×15 | 15/15 "Valid skill" (baseline: 13/15) |
| `bash -n` on all `*.sh` | pass |
| `shellcheck` on all `*.sh` | only the accepted SC2038 in the STIG script |
| `node --check` on `*.js`, `*.mjs` | pass |
| Frontmatter parse, name==dir, description ≤ 1024, no reserved words | pass |
| Relative-link check (fenced and inline code excluded) | 0 broken (baseline: 15) |
| README / docs / install-loop parity with skill directories | 15/15 |
| Hook and slugify self-tests, PAM/UFW/apt harnesses, pamtester, webhook verifier tests, `tsc --strict`, `estimate_cost` sweeps | pass (see Fix details) |

## Convergence history

| Pass | Scope | New confirmed | Fixed |
|---|---|---|---|
| 1 | All 57 files: 4 Sonnet partitions, Opus cross-cutting review, Opus skeptic | 31 (+3 invalid/accepted, 1 blocked) | 31 |
| 2 | All files: 3 Sonnet partitions + independent Opus challenge of the full diff | 6 (+1 refuted: P2A-1) | 6 |
| 3 | Independent Opus challenge of the full diff + whole-repo sweep | 5 | 5 |
| 4 | Fresh independent Opus challenge + whole-repo sweep | 1 (low, CHANGELOG) | 1 |

Pass 4's only finding was documentation, and it is fixed in the report commit. No actionable code or instruction defects remain open.

## Commits and rollback

The commits are listed in `git log --oneline 4265a4d..HEAD`. There are 22 in total: 21 fixes and this report commit. The batches are coherent per skill or per concern, so any one can be dropped with `git revert <sha>` and the others stay intact.

The rename commit `580ade4` is the only breaking change. Reverting it restores `anthropic-sdk`, but that name will still fail claude.ai / Skills API upload.

To roll back the whole branch, simply don't merge it; `main` was not modified.

## Remote, proposal and pipeline

- **Remote branch:** `code-review/full-codebase-review-20260926-1340` on `origin`, pushed without force.
- **Merge proposal:** the pull request against `main`. The URL is recorded in the final hand-off; a committed file cannot record its own PR.
- **Pipeline:** **NO PIPELINE CONFIGURED.** The repo has no `.github/workflows/`, `.gitlab-ci.yml` or other CI config. The authoritative final-SHA status is reported in the PR and the final response, not here: this file cannot record a result for the commit that contains it.

## Blockers and residual risks

- **Tags (owner action).** `v1.0.0` is a stray lightweight tag on `4265a4d`, the v1.7 release commit. The real `v1.0` tag correctly points at `66edc7e`. This session's git proxy refuses tag pushes (HTTP 403), so run these from your machine:
  ```bash
  git fetch origin --tags
  git tag -a v1.7 4265a4d -m "v1.7 — code-review skill"
  git push origin v1.7
  git push origin :refs/tags/v1.0.0     # delete the stray tag
  # after merging this branch:
  git tag -a v1.8 <merge-sha> -m "v1.8 — full review pass" && git push origin v1.8
  ```
- **Rename.** Existing `anthropic-sdk` installs keep working locally but no longer receive updates. Users must reinstall `@messages-api-sdk`. The skills.sh catalog entry for the old name will persist until it is re-crawled.
- **`/clear` interception.** Claude Code's docs don't say whether the built-in `/clear` reaches `UserPromptSubmit`. The skill now tells users to verify this locally.
- **Unverified claim.** openai-sdk anti-pattern 1 says `temperature` on o1/o3 is "accepted but has no effect". Community reports suggest the API returns a 400 "Unsupported parameter" instead. No official page could be reached to settle it, so it is left unchanged.
- **Pricing will drift.** Both SDK skills now link to the official pricing pages.
- **STIG PAM edits.** A later `pam-auth-update --force` would regenerate `common-auth` and drop the faillock lines.

## Recommendation

Merge after reviewing the breaking rename (`580ade4`) and the STIG PAM change (`de9e0ed`). If possible, run the STIG script on a disposable noble EC2 instance over SSH first, then apply the tag commands above.
