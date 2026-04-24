# TODOs

Deferred work. Revisit after v0.1 ships.

---

## [v0.2] Custom user actions overlay

**What:** Let users drop their own prompt files in
`~/.config/offline-text/prompts/` and add entries to a personal
`~/.config/offline-text/actions.toml`, which merges on top of the shipped
default registry.

**Why:** Users can extend the tool with their own commands (e.g., `formalize`,
`explain-code`, `translate-fr-to-en`) without forking the repo.

**Pros:** Extensibility without code changes. Keeps power users happy.

**Cons:** Adds merge-conflict logic (user override of same-id action), and
error surfaces multiply (malformed user TOML, missing user prompt file).

**Context:** v0.1 ships with a single repo-level `actions.toml`. The registry
loader already reads TOML, so extending it to merge two sources is
straightforward. Merge rule: user entries by `id` replace shipped entries;
unknown shipped entries pass through.

**Depends on:** v0.1 `actions.py` landed and stable.

---

## [v0.2] In-place text replacement

**What:** Replace selected text directly in the source app rather than routing
through the clipboard. macOS: Accessibility API. Linux: `xdotool`/`wtype`
plus xdg-desktop-portal for Wayland.

**Why:** "Select text, hit hotkey, text changes" is the dream UX. Clipboard
bounce is a small friction that adds up on heavy use.

**Pros:** No clipboard pollution. Feels like a system feature, not an app.

**Cons:** Requires Accessibility permission on macOS (a real onboarding step).
Wayland is still inconsistent for synthetic input. Failure modes multiply.

**Context:** v0.1 reads/writes clipboard via `pbpaste`/`pbcopy` on macOS and
`xclip`/`wl-copy` on Linux. In-place replacement is a frontend concern — the
Python core returns the fixed text either way.

**Depends on:** v0.1 shipped and the clipboard flow proven.

---

## [v0.2] LLM-as-judge for qualitative eval criteria

**What:** Extend the v0.1 eval harness with an LLM-as-judge pass for the
qualitative criteria (meaning preserved, tone preserved) that can't be
checked programmatically.

**Why:** v0.1 eval catches mechanical pass/fail (entity drift, edit ratio,
safety rejects, unchanged-when-correct). It flags qualitative cases for
manual review. An LLM judge would auto-score those.

**Pros:** Scales eval to larger case sets without manual review. Makes
"meaning preservation" a number.

**Cons:** Judge bias (GPT judges may favor GPT outputs), token cost on every
run, judge disagreements with humans need calibration.

**Context:** The v0.1 harness (Next Steps step 9) already runs cases across
providers with programmatic checks. This is the qualitative-criteria layer
on top.

**Depends on:** v0.1 eval harness shipped and in regular use.

---

## [v0.2] Streaming model output

**What:** Support `stream=True` on LiteLLM calls and render partial output in
the diff view as tokens arrive.

**Why:** Hosted providers (OpenAI, Anthropic) take 1-3s — streaming makes the
popup feel instant.

**Pros:** Perceived latency drops to ~200ms. Feels more alive.

**Cons:** Diff rendering during stream is non-trivial (you're diffing against
a moving target). Simplest approach is show "streaming..." then the final
diff when the stream closes, which is only a marginal UX win over sync.

**Context:** LiteLLM supports streaming uniformly across providers. Lazy
import keeps this cheap to add later.

**Depends on:** v0.1 synchronous path proven, diff UX dialed in.

---

## [v0.2] llama.cpp direct adapter

**What:** Add `providers/llamacpp.py` for users who run llama.cpp directly
(not via Ollama).

**Why:** Some users prefer the raw llama.cpp server or have existing setups.
LiteLLM supports it via the `ollama/` prefix when pointed at the OpenAI-
compatible endpoint `llama-server` exposes, so this may not need separate work.

**Pros:** Explicit support path for llama.cpp users.

**Cons:** LiteLLM probably already covers it. Verify before writing code.

**Context:** `docs/architecture.md` lists llama.cpp as a later adapter. With
LiteLLM landed in v0.1, check whether pointing the OpenAI-compatible base_url
at llama-server's endpoint already works.

**Depends on:** v0.1 LiteLLM integration stable.

---

## [v0.2] GitHub Actions CI + release pipeline

**What:** GitHub Actions workflow that runs `pytest` on push, plus a release
workflow that tags versions and publishes a Homebrew tap / `pipx`-installable
package.

**Why:** Confidence that tests stay green. Easier install path than
`git clone && make install`.

**Pros:** Reproducible installs. Test regressions caught early.

**Cons:** Setup cost. Homebrew tap needs its own repo.

**Context:** v0.1 distribution is git-clone-and-install, which is fine for
self-use but a barrier to any other user.

**Depends on:** v0.1 shipped and stable.
