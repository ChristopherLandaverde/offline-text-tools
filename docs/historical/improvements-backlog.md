# Lang Tool Improvement Ideas

## Current State

The current tool is a focused X11 workflow:

1. Read selected text
2. Let the user choose an action
3. Send text to Ollama
4. Paste the result back into the original app

That is a good foundation because it is fast and practical. The main limitation is that it behaves like one script with three options, not a broader system.

## Product Goal

Turn the tool from a narrow translator/grammar helper into a keyboard-first local command palette for text operations.

## High-Value Improvements

### 1. Expand The Command Set

Add commands beyond translation and grammar:

- Summarize
- Rewrite for clarity
- Make more formal
- Make more casual
- Simplify text
- Expand terse notes
- Draft reply
- Explain selected text
- Convert bullets to prose
- Convert prose to bullets

This increases daily usefulness without changing the core interaction model.

### 2. Split Commands Into Separate Units

Instead of one large bash case statement, define commands as separate entries with:

- Name
- Description
- Prompt
- Model
- Behavior flags

That creates a path toward a command registry and plugin-like architecture.

### 3. Add Command Metadata

Each command should have structured metadata:

- Display name
- Search aliases
- Category
- Input type
- Output mode
- Preferred model
- App compatibility notes

This makes search and launcher UX much stronger.

### 4. Add Output Modes

Not every action should replace the selection. Support:

- Replace selection
- Copy to clipboard only
- Show preview first
- Append instead of replace

This would make the tool safer and more flexible.

### 5. Add Stronger Output Validation

The model should be checked before paste-back. Reject outputs that:

- Add explanations
- Add markdown fences
- Add quotes around the whole response
- Return empty or obviously broken text

This reduces failure cases and makes the tool feel more reliable.

### 6. Improve Model Routing

Different tasks do not need the same model quality. Route by task:

- Small/fast model for short grammar fixes
- Better multilingual model for translation
- Higher quality model for rewrite/summarize tasks

This lowers cost and latency.

### 7. Improve Context Awareness

Use active window/app context to choose safer behavior:

- Terminal: preserve paste semantics carefully
- Code editor: avoid altering code-like text
- Browser/chat app: standard replace flow

Longer term, app-specific rules would make the tool feel much smarter.

### 8. Add History And Favorites

Track:

- Recently used commands
- Most used commands
- Last prompts/actions

This helps the launcher rank relevant actions faster.

### 9. Add Direct Hotkeys

Keep the launcher, but also add dedicated shortcuts for the most common actions:

- Direct translate to Portuguese
- Direct translate to English
- Direct fix grammar

This removes one interaction step for high-frequency use.

### 10. Support More Than X11

Wayland support would materially increase usefulness. Right now the tool is constrained by:

- `xclip`
- `xdotool`
- X11 selection behavior

A future version should abstract clipboard, selection, and paste backends so the platform is not tied to one display stack.

## Product Direction Options

### Option A: Better Single-Purpose Tool

Keep it focused on text transformation, but make it more polished:

- More commands
- Better prompts
- Better validation
- Better paste handling
- Better model choices

This is the lowest-risk path.

### Option B: Raycast-Like Text Launcher

Keep text as the main input, but build a real launcher with a registry and plugin model.

This is likely the best next step if the goal is a personal productivity tool.

### Option C: Full Desktop Command Palette

Expand beyond text into:

- Clipboard tools
- Snippets
- Window actions
- File actions
- Developer helpers

This is the most ambitious path and probably requires moving beyond bash.

## Recommended Near-Term Roadmap

### Phase 1

- Add 5 to 8 more high-value text commands
- Add copy-only and preview modes
- Add output validation
- Add direct hotkeys for common actions

### Phase 2

- Move commands into a registry/config file
- Add aliases, categories, and command metadata
- Add usage history and ranking

### Phase 3

- Add plugin-style commands
- Add app-aware behavior
- Add Wayland backend support

## Suggested Technical Shift

If the project grows past a small personal script, bash will become awkward. A better long-term implementation would likely use:

- Python for fast iteration and good system integration
- Go for a small fast binary
- Node only if a richer extension ecosystem is desired

The most important shift is not language choice. It is moving from "script with hardcoded branches" to "launcher with commands and shared services."

## Bottom Line

The current tool already proves the core UX: select, invoke, transform, paste. The best way to improve it is to preserve that fast loop while turning the implementation into a reusable command platform rather than adding more ad hoc logic to one script.
