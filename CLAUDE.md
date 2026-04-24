# CLAUDE.md

Project context for Claude Code and any AI assistant working in this repo.

## What this is

Offline Text Tools — a cross-platform (macOS + Linux) command-line + popup tool
that runs local-first grammar fixes and EN↔PT translations via Ollama, with an
optional hosted-model path (OpenAI / Anthropic / any LiteLLM-supported provider)
selected per action. Every edit requires a diff review before anything is
applied. Clipboard in, clipboard out.

The authoritative spec is `docs/design-v0.1.md`. That doc is post-review and
post-approval — it's the source of truth for architecture and scope.

## Repo layout

```
src/offline_text/    # Python core (empty until implementation lands)
frontends/           # rofi (Linux) + choose (macOS) popup wrappers
prompts/             # action prompt files, one per command
docs/                # design, architecture, evaluation
TODOS.md             # v0.2 deferrals
```

## Testing

Test framework: **pytest** + **pytest-httpx** (for mocking LiteLLM calls).

```
pip install -e ".[dev]"   # once src/ lands with pyproject.toml
pytest                    # runs the full suite
pytest tests/safety.py    # single module
```

Test expectations:
- 100% coverage on the core modules (safety, diff, providers, actions).
  Greenfield repo — there's no excuse for uncovered paths.
- Every new function gets a test. Every new if/else gets tests for both paths.
- Every error handler gets a test that triggers the error.
- Regression tests are mandatory, no AskUserQuestion needed.
- Never commit code that makes existing tests fail.
- Mock all external calls (Ollama, OpenAI, Anthropic). Use pytest-httpx.

## Coding standards

- Python 3.11+
- Type hints throughout, `mypy --strict` in CI
- No clever one-liners when a named variable reads better
- No comments that restate the code; comments explain non-obvious WHY only
- Error paths use the discriminated JSON schema from design-v0.1.md

## Development workflow — two-model split

This project uses a deliberate two-model workflow. Respect the split.

**Claude Code — architect + hardness engineer.**
- Writes and maintains `docs/design-v0.1.md` and any future design docs.
- Decomposes work into module-level specs with explicit input/output contracts.
- Authors the test suites, including edge cases and regression tests.
- Owns the safety layer correctness (URL / email / number invariants), the
  error-kind schema, and the provider healthcheck logic.
- Reviews every Codex implementation before it lands. No Codex code ships
  without Claude verifying the spec was met and the tests pass.
- Drives `/plan-eng-review`, `/review`, `/ship`, and pre-landing hardening.

**Codex — implementation engine.**
- Given a Claude-written spec (type signatures, invariants, test cases already
  in place), Codex writes the function bodies and module internals.
- Produces straightforward, unclever implementations. No side quests, no
  refactors beyond what the spec asks for.
- Codex work always targets green tests written by Claude. If the tests fail,
  Codex iterates until they pass, or escalates back to Claude for spec
  clarification.
- Invoked via the `/codex` skill when the spec is ready.

**Canonical orchestrator: `scripts/build-loop.sh`.**

The Claude → Codex → review loop runs through `scripts/build-loop.sh`, which
predates this CLAUDE.md and has been road-tested. Use it, don't reinvent it.

```
./scripts/build-loop.sh              # First run: Codex implements from CODEX_PROMPT.md
./scripts/build-loop.sh review       # After Claude review: Codex applies REVIEW_FEEDBACK.md
./scripts/build-loop.sh "fix X"      # Ad-hoc: Codex gets targeted instructions
```

It tracks iteration count, logs every Codex run to `.codex-output-N.log`, and
shows the diff after each iteration.

**Handoff flow:**
1. Claude writes the spec to `CODEX_PROMPT.md` using the template at
   `docs/workflow/codex-handoff-template.md`. The spec includes: module stub
   with type signatures + docstrings, full pytest suite that fails against
   the stub, a one-paragraph "make the tests pass, add nothing more" brief.
2. Run `./scripts/build-loop.sh`. Codex implements; Claude reads the diff.
3. If the diff drifts from spec: Claude writes `REVIEW_FEEDBACK.md` with
   specific asks, runs `./scripts/build-loop.sh review`. Codex applies
   feedback. Loop until green + no drift.
4. Merge via `/ship`. Delete `.iteration` + `.codex-output-*.log` as part
   of cleanup.

**What Claude checks before accepting a Codex diff:**
1. All tests pass (no changes to test files to make them pass).
2. No out-of-scope changes (files outside the spec scope are untouched).
3. No new dependencies not in the spec.
4. No invented behavior the spec didn't describe.

If anything drifts, write `REVIEW_FEEDBACK.md` and re-run. Never silently
accept "close enough" — the spec is the contract.

**What stays with Claude regardless of workflow:**
- `safety.py` — invariant checks on URLs, emails, numbers. Silent failures
  here corrupt user text, so this module is Claude-authored and
  Claude-tested, end to end. Codex may extend it only with an airtight new
  invariant spec.
- `diff.py` — same reasoning; if the diff is wrong the user ships bad edits.
- Error handling and exit codes — the contract the frontends depend on.
- Any security-adjacent code (keyring usage, API key handling).

**What Codex owns cleanly:**
- `providers/litellm_adapter.py` — the LiteLLM call plus healthcheck. Thin,
  well-specified, easy to verify with mocked tests.
- `actions.py` — TOML loading, prompt-file resolution, per-action provider
  override. Deterministic config plumbing.
- `__main__.py` CLI — argparse wiring. Boilerplate, but lots of it.
- Frontend shell scripts (`frontends/linux/popup.sh`, `frontends/macos/popup.sh`)
  once the contract with the Python core is frozen.

**Rule of thumb:** if the module's correctness is enforced by passing tests,
it's fair game for Codex. If its correctness depends on a human (or Claude)
reasoning about what can go wrong, it's Claude work.

## Skill routing

When a user request matches an available gstack skill, invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.

- Product ideas, "is this worth building", brainstorming → /office-hours
- Bugs, errors, "why is this broken" → /investigate
- Ship, deploy, push, create PR → /ship
- QA, test the site, find bugs → /qa
- Code review, check my diff → /review
- Update docs after shipping → /document-release
- Weekly retro → /retro
- Architecture review → /plan-eng-review
- Save progress, checkpoint, resume → /checkpoint
- Code quality, health check → /health

## Non-goals (from design-v0.1.md, worth repeating)

- Windows support (macOS + Linux only)
- Hosted-model fallback on the default path (local Ollama is always the default)
- Auto-apply edits without diff review (never, not even for small edits)
- Accessibility-API direct-replace in v0.1 (clipboard-only for now)
- Telemetry or phone-home of any kind
