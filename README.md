# Offline Text Tools

Offline-first shortcuts for:

- grammar fixes
- English to Portuguese translation
- Portuguese to English translation

## Goal

Build the smallest reliable desktop tool that can:

1. read selected text or clipboard text
2. run a constrained local text action
3. show a safe diff before applying output
4. paste or copy the result back

## Principles

- local-first, no hosted dependency in the main path
- conservative edits over aggressive rewrites
- separate commands for grammar and translation
- never auto-apply risky output

## Initial Scope

- macOS and Linux
- one hotkey entry point
- three commands:
  - `fix-grammar`
  - `translate-en-to-pt`
  - `translate-pt-to-en`
- local model runtime via `Ollama` or `llama.cpp`
- diff-based review before replace

## Proposed Layout

- `docs/architecture.md` - system design and flow
- `docs/evaluation.md` - how to test output quality
- `prompts/` - strict prompts for grammar and translation
- `src/` - app code

## Next Build Steps

1. choose runtime: `Tauri` or a smaller script-first prototype
2. choose local model host: `Ollama` or `llama.cpp`
3. implement prompt runner
4. add diff guardrails
5. add clipboard and shortcut integration

# offline-raycast
