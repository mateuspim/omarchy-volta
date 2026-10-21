# Contributing to Volta

Thanks for helping. Volta is a small project; issues and focused pull
requests are welcome.

## Before you start

- Bugs and ideas: open an issue first for anything larger than a small fix.
  Volta is deliberately a focused stereo control, not a mixer
  ([ADR 3](docs/adr/0003-focused-scope-not-a-mixer.md)).
- Security problems: follow [SECURITY.md](SECURITY.md), not a public issue.
- Read [AGENTS.md](AGENTS.md): it holds the code rules for people and coding
  agents alike, and [docs/architecture.md](docs/architecture.md).

## Set up

You need Omarchy 4.0+ and Node.js 22+. Clone the repository, link it into the
user plugin directory, then rescan and enable it:

```sh
git clone https://github.com/mateuspim/omarchy-volta.git
ln -s "$PWD/omarchy-volta" ~/.config/omarchy/plugins/pym.volta
omarchy-shell shell rescanPlugins
omarchy plugin enable pym.volta
```

Edits hot-reload with the shell. Never edit files under `/usr/share/omarchy`.
More in the [development runbook](docs/runbooks/development.md).

## Make a change

1. Branch from `master`.
2. Keep the change focused; update the README section or doc it affects.
3. Add or update tests. Run `npm test` and `omarchy plugin validate .`.
4. For UI changes, attach an offscreen render
   (`VOLTA_PREVIEW_DIR=<dir> bash tests/preview.sh`, see the
   [development runbook](docs/runbooks/development.md)), never a desktop
   screenshot with personal data.
5. Durable design choice? Add an ADR under [docs/adr](docs/adr/README.md).

## Commit style

Plain imperative subject ("Add …", "Keep …"), under ~72 characters, and a
body that explains why.

## Pull request checklist

- [ ] `npm test` passes and `omarchy plugin validate .` exits 0
- [ ] Docs and CHANGELOG updated
- [ ] No personal paths, device names, serials or addresses in tracked files

## License

By contributing you agree your work is released under the [MIT License](LICENSE).
