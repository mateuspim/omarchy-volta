# Security

## Reporting a vulnerability

Please report privately through GitHub's
[security advisories](https://github.com/mateuspim/omarchy-volta/security/advisories/new)
rather than a public issue. Include the version (`manifest.json`), steps to
reproduce and impact. You can expect a reply within a week.

## Supported versions

Only the latest release on `master` receives fixes.

## Privilege model

Omarchy plugins run unsandboxed inside `omarchy-shell` as your user. This is
what Volta does with that access:

- Runs: three Omarchy helpers, each with a fixed argument list and no shell:
  `omarchy-audio-output-sink` (which sink is the real output; at start, on
  output changes and every 15 s), `omarchy-audio-sink-availability` (which
  outputs to list; every 5 s), and `omarchy-audio-output-set-default <id>
  <name>` (only when you pick an output; the id and name come from
  PipeWire).
- Reads: PipeWire node metadata and volumes through Quickshell's PipeWire
  API, and the helpers' stdout.
- Writes: the current output's channel volumes, volume and mute through
  PipeWire, and the default output through the helper above. No files.
- Root: never.
- Network: none.
- Secrets: none.

Sink names come from PipeWire metadata that local clients and devices
control; Volta escapes markup and limits their length before display
([ADR 8](docs/adr/0008-escape-sink-labels.md)).

It never changes configuration outside its own files on load, and installs
no compositor bindings.
