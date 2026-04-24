# Linux frontends

## `popup-legacy.sh` (the working 2026-04-16 prototype)

Self-contained X11 bash script. Reads selected text from the PRIMARY selection,
shows a rofi menu (Translate to Portuguese / English / Fix Grammar), calls
Ollama at `localhost:11434/api/generate`, pastes the result in-place via
`xdotool`, restores the original clipboard. Terminal-aware paste keystroke
(Ctrl+Shift+V in terminals, Ctrl+V elsewhere).

**This file is the canonical reference during v0.1 migration.** Do not edit it.
The new `popup.sh` (not yet written) will replace it once it reaches parity
against the evaluation set.

Dependencies: `xclip`, `xdotool`, `xprop`, `rofi`, `notify-send`, `curl`, `jq`,
`ollama` (with `qwen2.5:14b` pulled).

## `install-legacy.sh` (the working installer)

Checks deps, auto-pulls the model, copies the script to `~/.local/bin/`,
registers the GNOME custom keybinding (Ctrl+Shift+L → `lang-tool.sh`).
Idempotent — safe to re-run.

**This file is the canonical reference for the install flow.** The new
`install.sh` (not yet written, part of Phase 3) will extend this pattern to
also install the Python core.

## What's changing in v0.1

- The prototype stays byte-for-byte until v0.1 ships, as a seatbelt
- New `popup.sh` will call the Python core (`python -m offline_text run`) for
  safety checks and action lookup, but preserve the PRIMARY-selection read,
  the rofi menu, and the in-place `xdotool` paste
- Commands beyond grammar/translation (summarize, formalize, etc.) become
  data-driven via `actions.toml` — no bash edits needed
- Hosted providers (Anthropic/OpenAI) plug in via the Python core for
  translation actions; grammar stays local

See `docs/design-v0.1.md` for the full migration plan.
