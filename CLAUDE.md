## Agent skills

### Issue tracker

Local markdown under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Writing style

Before finishing any turn that includes written prose for the user (chat replies, commit messages, PR descriptions, docs), apply the `unslop` skill (`.claude/skills/unslop/SKILL.md`) to that text. This applies in every conversation in this project, not just when explicitly invoked.
