# Implementation Task: lang-tool.sh

Read the design spec at `2026-04-16-lang-tool-design.md` in this repo. Then implement `src/lang-tool.sh` — a single bash script that does exactly what the spec describes.

## What to build

A bash script that:
1. Grabs the currently selected text via `xclip -selection primary -o`
2. Shows a rofi dmenu with 3 options: "Translate to Portuguese", "Translate to English", "Fix Grammar"
3. Sends the text + a system prompt to the local Ollama API
4. Pastes the result back over the selection

## Requirements

Follow the spec exactly. Key implementation details:

### Clipboard & Window Management
- Save the active window ID with `xdotool getactivewindow` BEFORE rofi opens
- Save the current clipboard with `xclip -selection clipboard -o` BEFORE the API call
- After getting the result, write it to clipboard with `xclip -selection clipboard`
- Refocus the original window with `xdotool windowactivate $WINDOW_ID`
- Detect if the window is a terminal by checking WM_CLASS via `xprop -id $WINDOW_ID`
- Known terminal classes: gnome-terminal, kitty, alacritty, tilix, xterm, konsole, terminator
- Use `Ctrl+Shift+V` for terminals, `Ctrl+V` for everything else
- Sleep 0.1s before paste to allow focus to settle
- Sleep 0.5s after paste, then restore the original clipboard

### Model & API
- Model: `qwen2.5:14b`
- Store model name in a variable at the top of the script for easy changing
- API: `POST http://localhost:11434/api/generate` with `stream: false`
- Use `jq` to build the JSON payload (NOT string interpolation) for safety with special characters
- Parse response with `jq -r '.response'`

### System Prompts
- Translate to Portuguese: "You are a translator. Translate the following text to Brazilian Portuguese. Output ONLY the translated text, no explanations. Preserve all line breaks, whitespace, and formatting exactly. Do not translate URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping."
- Translate to English: "You are a translator. Translate the following text to English. Output ONLY the translated text, no explanations. Preserve all line breaks, whitespace, and formatting exactly. Do not translate URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping."
- Fix Grammar: "You are a grammar editor. Fix the grammar and spelling in the following text. Keep the same language. Output ONLY the corrected text, no explanations. Preserve all line breaks, whitespace, formatting, and capitalization style exactly. Do not alter URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping."

### Error Handling
All errors use `notify-send "Language Tool" "<message>"` then exit.
- No text selected (empty string from xclip): "No text selected"
- Text > 5000 chars: "Text too long (max 5000 chars)"
- Ollama not running (curl fails to connect): "Ollama is not running"
- Model not found (check response for "model not found"): "Model qwen2.5:14b not found. Run: ollama pull qwen2.5:14b"
- Empty/error response: "Translation failed"
- User dismisses rofi (empty selection): silent exit, no notification

### Notifications
- Show "Translating..." or "Fixing grammar..." toast when starting the API call
- Show "Done" toast when complete

### Script Structure
```
#!/usr/bin/env bash
set -euo pipefail

MODEL="qwen2.5:14b"
NOTIFY_TITLE="Language Tool"

# 1. Grab selected text
# 2. Validate (not empty, not too long)
# 3. Save window ID
# 4. Show rofi menu
# 5. Set system prompt based on selection
# 6. Save current clipboard
# 7. Show progress notification
# 8. Call Ollama API (jq to build JSON, curl to send)
# 9. Validate response
# 10. Write result to clipboard
# 11. Refocus window
# 12. Detect terminal, paste with correct keystroke
# 13. Restore clipboard
# 14. Show done notification
```

## Do NOT
- Do not use string interpolation for JSON — use jq
- Do not add features not in the spec
- Do not add comments explaining what bash builtins do
- Do not create multiple files — everything goes in `src/lang-tool.sh`
- Do not create tests, READMEs, or other files

## Also create

Create `src/install.sh` — an installer script that:
1. Checks all dependencies are present (xclip, xdotool, xprop, rofi, notify-send, curl, jq)
2. Reports any missing dependencies with install commands
3. Checks if ollama is installed, if not prints install instructions
4. Checks if qwen2.5:14b model is pulled, if not runs `ollama pull qwen2.5:14b`
5. Copies lang-tool.sh to ~/.local/bin/ and makes it executable
6. Registers the GNOME shortcut (auto-detects next available slot, updates custom-keybindings array)
7. Prints success message with usage instructions
