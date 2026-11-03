# 15. Keep agent instructions out of the install; contributors opt in

- Status: Accepted
- Date: 2026-11-03

## Context

`omarchy plugin add` installs a plugin with a plain `git clone` of the whole
repository into `~/.config/omarchy/plugins/<id>` (`omarchy-plugin-add`; there
is no install-time exclude list, and `.gitattributes` `export-ignore` does
not apply to clones). Up to 0.2.0 Volta tracked a root `AGENTS.md` with the
contributor rules (test and release commands, commit and push policy) and a
`CLAUDE.md` that imported it.

Coding agents load those files without being asked: Claude Code reads
`CLAUDE.md` in the working directory and its parents, and in subfolders it
reads files from; Codex and other tools read `AGENTS.md` from the repository
root down to the working directory. Anyone running an agent in or above an
ordinary Volta install therefore got Volta's contributor instructions in
their session. The Omarchy plugin marketplace review of 0.2.0
(omacom/omarchy-plugin-marketplace#13775) asked that these instructions be
kept outside automatic discovery, excluded from the ordinary install, or
made an explicit opt-in.

## Decision

- The contributor and agent rules live in
  [`docs/contributing/agent-instructions.md`](../contributing/agent-instructions.md),
  a name and path no agent loads automatically.
- No tracked file is one that agents auto-load: no root or nested
  `AGENTS.md`/`CLAUDE.md`, and no `.claude/`, `.cursor/`, `.windsurf/`,
  `.gemini/`, `.codex/`, `.clinerules`, `.github/copilot-instructions.md` or
  `.github/instructions/`. `tests/repo.test.js` fails on any of them.
- Root `AGENTS.md` and `CLAUDE.md` are gitignored. Contributors opt in by
  running `scripts/dev-setup` in a checkout they develop in. It links
  `AGENTS.md` to the instructions (so tools that read the file get the full
  text) and writes `CLAUDE.md` as a one-line
  `@docs/contributing/agent-instructions.md` import. It never overwrites a
  file it did not create, and `--remove` undoes it.
- The opt-in is documented as a development step in `CONTRIBUTING.md`, the
  README's Development section and the development runbook, never under
  Install.

## Consequences

- An ordinary install carries the instructions only as an inert Markdown
  file under `docs/`; agents run there see nothing unless asked to read it.
- A fresh contributor clone has no agent instructions until
  `scripts/dev-setup` runs; the docs say to run it first.
- A checkout linked as the plugin directory (the development setup) does
  have the opt-in files. That is the contributor's own choice.
- Adding agent configuration for a new tool means adding its discovery path
  to `tests/repo.test.js` and keeping the file local, not tracked.
- This departs from the shared repo standard, which prescribed tracked root
  `AGENTS.md`/`CLAUDE.md`.
