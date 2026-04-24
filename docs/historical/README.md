# Historical design docs

Pre-v0.1 design thinking. Preserved for context; not authoritative for current
implementation. The current authoritative spec is `docs/design-v0.1.md`.

## Files

- **`2026-04-16-lang-tool-design.md`** — The design that shipped as the Linux
  rofi prototype (`frontends/linux/popup-legacy.sh`). Concrete, grounded,
  working. Several of its decisions (PRIMARY selection, in-place `xdotool`
  paste, `--keepalive -1`, terminal-aware paste keystroke) have been adopted
  into the v0.1 design after the import.

- **`improvements-backlog.md`** — Product thinking about where to take the
  tool next: command palette pattern, richer command set (summarize, rewrite,
  formalize, casualize, etc.), command registry, app-specific behavior. Most
  of this is now addressable via `actions.toml` + prompt files with zero
  Python changes. See the Feature Roadmap section of `docs/design-v0.1.md`.

- **`raycast-reference.md`** — Background notes on Raycast's interaction
  model. Used as a reference point for "what does a keyboard-first command
  palette feel like." Not a direct requirement.

## Why these are kept

Design docs decay fast, but the *reasoning* behind a decision is load-bearing.
If a future question arises ("why did we pick qwen2.5:14b over a smaller
model?"), the answer lives in `2026-04-16-lang-tool-design.md`, not in the
current spec.
