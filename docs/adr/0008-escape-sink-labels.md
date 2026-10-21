# 8. Escape and bound sink labels from PipeWire metadata

- Status: Accepted
- Date: 2026-08-26 (documented from the code; landed in `66e753a`, `a0bff99`)

## Context

Sink descriptions come from PipeWire metadata that any local client or
attached device can set. Omarchy's shared `Dropdown` and the bar tooltip
render text with `Text.AutoText`, so a description containing markup such
as `<img src=...>` would be interpreted, and a very long name would live
in the persistent shell.

## Decision

`Model.sinkLabel` picks `description`, then `nickname`, then `name`, and
`Model.safeSinkText` escapes `<` and `>` and cuts the text to 160
characters. Ampersands are left alone so names such as "B&O" read
correctly.

## Consequences

- Labels cannot load images or styled markup.
- Every new place that shows a sink name must go through `sinkLabel`.
