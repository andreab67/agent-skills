# Review Standards

This repository is a catalog of reusable LLM agent skills. Code reviews should evaluate whether changes improve the skill catalog for real operational use, not whether the repo follows generic application-development conventions.

## Review priorities

1. **Operational value first**
   - New or changed skills should capture production-grade knowledge that would save time during real incidents, deployments, migrations, or support workflows.
   - Prefer concrete runbooks, commands, failure modes, and decision rules over tutorial-style explanations.

2. **Trigger clarity**
   - Each `SKILL.md` description must state when the skill should activate and when it should not.
   - Flag vague trigger text such as "use for advanced tasks" or "help with cloud work".
   - Prefer explicit user phrasing and adjacent non-goals.

3. **Repository layout**
   - Each skill should live in a root-level directory named exactly like the skill.
   - Required layout:
     ```text
     skill-name/
     └── SKILL.md
     ```
   - Public docs should mirror the skill in `docs/skill-name.md`.
   - `README.md` must include the new skill in the table and install loop when a new skill is added.

4. **`SKILL.md` quality**
   - Frontmatter must include `name` and `description`.
   - `name` must be kebab-case and match the directory name.
   - Body should include:
     - title and positioning
     - when to use / when not to use
     - numbered workflow instructions with rationale
     - output discipline
     - 5–8 realistic example prompts
     - related skills or handoff notes
   - Keep the main `SKILL.md` concise. Move large reference material into `references/` and link to it.

5. **Voice and style**
   - Write for a senior engineer. Avoid generic introductions.
   - Use runnable commands only when required values are shown or computable.
   - Call out destructive operations explicitly.
   - Cite version-specific behavior when it affects decisions.
   - Avoid placeholder-only examples.

6. **Safety and correctness**
   - Do not introduce secrets, tokens, credentials, or private URLs.
   - Avoid fabricating product names, API endpoints, or version behavior.
   - For infrastructure or security skills, require explicit warnings for destructive commands and environment assumptions.
   - If a recommendation depends on a specific platform, state the platform and version.

7. **Change scope**
   - One skill per PR.
   - Avoid bundling unrelated skill edits.
   - Behavioral changes to existing skills should have an issue or clear rationale because installed users see them immediately.

## What not to flag

- Missing unit-test harnesses are not blockers; this repo does not currently ship skill tests.
- Documentation-only fixes are expected and acceptable.
- Minor wording cleanup is acceptable when it improves trigger accuracy or operational clarity.

## Preferred review output

Review comments should be actionable and tied to this repository's conventions. Prefer comments that explain the operational cost of the issue and the exact file or section to change.

For completed non-trivial changes, suggest `/local-review-uncommitted` before pushing.
