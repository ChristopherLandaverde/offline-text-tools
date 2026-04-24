# Lang Tool — Hotkey-Powered Translation & Grammar Fix

**Date:** 2026-04-16
**Status:** Draft
**Approach:** Bash script + GNOME custom shortcut

## Overview

A single bash script (`lang-tool.sh`) that lets the user select text in any application, press `Ctrl+Shift+L`, pick a mode from a rofi menu, and get the result pasted back in place — powered by a local Ollama model.

Entirely offline. No API keys, no cloud services.

## User Flow

1. User selects text in any application
2. Presses `Ctrl+Shift+L`
3. Script captures selected text from X11 PRIMARY selection (`xclip -selection primary -o`)
4. Rofi menu appears with three options:
   - `Translate to Portuguese`
   - `Translate to English`
   - `Fix Grammar`
5. User picks an option (can type to filter: `t` for translate, `f` for fix)
6. Script saves the current clipboard contents (`xclip -selection clipboard -o`) and the active window ID (`xdotool getactivewindow`)
7. `notify-send` shows a progress toast (e.g., "Translating...")
8. Script sends text + system prompt to Ollama API (`POST http://localhost:11434/api/generate`)
9. Response is written to clipboard (`xclip -selection clipboard`)
10. Script refocuses the original window (`xdotool windowactivate`) and detects if it is a terminal (by checking WM_CLASS via `xprop`)
11. `xdotool` simulates `Ctrl+V` (or `Ctrl+Shift+V` for terminals) to paste over the selected text
12. After a 0.5s delay, script restores the original clipboard contents
13. `notify-send` shows "Done"

## Rofi Menu

Three modes, displayed in `dmenu` mode (simple vertical list):

| Label                    | Action                                          |
| ------------------------ | ----------------------------------------------- |
| Translate to Portuguese  | Translates any language to Brazilian Portuguese  |
| Translate to English     | Translates any language to English               |
| Fix Grammar              | Fixes grammar/spelling, preserves input language |

## Ollama Model

**Model: `qwen2.5:14b`**

Selected for:
- Strong multilingual support with good nuance and formality awareness for Brazilian Portuguese
- Fast inference (~3s on this hardware)
- Moderate resource usage (~9GB VRAM, ~7% of available 128GB)
- Good context understanding — handles idioms, tone, and mixed-language text well

**Keep-alive:** Model stays loaded permanently (`--keepalive -1`) to eliminate cold starts. With 128GB VRAM, this is negligible.

**Upgrade path:** If translation quality feels flat, step up to `qwen2.5:32b` (~20GB VRAM, ~4s). No script changes needed — just pull the new model and update the `MODEL` variable.

## System Prompts

Each mode uses a dedicated system prompt. All prompts end with "Output ONLY the corrected/translated text, no explanations." to prevent the model from adding commentary that would pollute the pasted result.

### Translate to Portuguese
```
You are a translator. Translate the following text to Brazilian Portuguese. Output ONLY the translated text, no explanations. Preserve all line breaks, whitespace, and formatting exactly. Do not translate URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping.
```

### Translate to English
```
You are a translator. Translate the following text to English. Output ONLY the translated text, no explanations. Preserve all line breaks, whitespace, and formatting exactly. Do not translate URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping.
```

### Fix Grammar
```
You are a grammar editor. Fix the grammar and spelling in the following text. Keep the same language. Output ONLY the corrected text, no explanations. Preserve all line breaks, whitespace, formatting, and capitalization style exactly. Do not alter URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping.
```

## API Call

```
POST http://localhost:11434/api/generate
{
  "model": "qwen2.5:14b",
  "system": "<system prompt for selected mode>",
  "prompt": "<selected text>",
  "stream": false
}
```

Response field: `.response` (extracted via `jq -r '.response'`).

**Input size limit:** Max 5000 characters. If the selected text exceeds this, show "Text too long (max 5000 chars)" notification. This prevents slow requests and accidental prompt truncation.

**JSON safety:** The selected text must be properly escaped before embedding in the JSON payload. Use `jq` to construct the JSON body (e.g., `jq -n --arg text "$SELECTED" --arg sys "$SYSTEM_PROMPT" ...`) rather than string interpolation, to avoid quoting bugs with newlines, quotes, and special characters.

## Hotkey

**`Ctrl+Shift+L`** — registered as a GNOME custom keyboard shortcut.

Command: `/home/chrisland/.local/bin/lang-tool.sh`

Not using `Super+` to avoid conflict with the GNOME Activities Overview trigger.

## Error Handling

All errors show a `notify-send` notification with title "Language Tool" and auto-dismiss after a few seconds.

| Condition              | Message                                                  |
| ---------------------- | -------------------------------------------------------- |
| No text selected       | "No text selected"                                       |
| Ollama not running     | "Ollama is not running"                                  |
| Model not installed    | "Model qwen2.5:14b not found. Run: ollama pull qwen2.5:14b"  |
| Text too long          | "Text too long (max 5000 chars)"                         |
| API returns empty/error| "Translation failed"                                     |
| User dismisses rofi    | Silent exit (no notification)                            |

## File Structure

```
~/.local/bin/lang-tool.sh    # Single bash script, executable
```

## Dependencies

| Tool         | Purpose                        |
| ------------ | ------------------------------ |
| `xclip`      | Clipboard read/write           |
| `xdotool`    | Simulate paste + window focus  |
| `xprop`      | Detect terminal windows via WM_CLASS |
| `rofi`       | Mode selection menu            |
| `notify-send`| Desktop notifications          |
| `curl`       | HTTP calls to Ollama API       |
| `jq`         | Parse JSON response + build JSON payload |
| `ollama`     | Local LLM runtime              |

## Installation Steps

1. **Install Ollama:**
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```
2. **Pull the model and keep it loaded:**
   ```bash
   ollama pull qwen2.5:14b
   ollama run qwen2.5:14b --keepalive -1
   ```
3. **Copy the script:**
   ```bash
   cp lang-tool.sh ~/.local/bin/lang-tool.sh
   chmod +x ~/.local/bin/lang-tool.sh
   ```
4. **Register the GNOME shortcut:**
   ```bash
   # Find the next available custom shortcut slot (avoids colliding with existing ones)
   EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
   SLOT=0
   while echo "$EXISTING" | grep -q "custom${SLOT}/"; do SLOT=$((SLOT + 1)); done
   KPATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${SLOT}/"

   # Register the slot in the custom-keybindings array
   if [ "$EXISTING" = "@as []" ]; then
     gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${KPATH}']"
   else
     gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$(echo "$EXISTING" | sed "s|]|, '${KPATH}']|")"
   fi

   # Configure the shortcut itself
   gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KPATH} name "'Language Tool'"
   gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KPATH} command "'/home/chrisland/.local/bin/lang-tool.sh'"
   gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KPATH} binding "'<Ctrl><Shift>l'"
   ```

## Limitations & Notes

- **X11 only.** The script uses `xclip` and `xdotool`, which are X11 tools. Wayland would require `wl-copy`/`wl-paste` and `wtype`, plus different clipboard/focus semantics. Not a trivial port.
- **Selection must persist.** The text must remain selected after rofi closes. Since we capture from PRIMARY selection before rofi opens, this is handled.
- **Paste delay.** A small `sleep` (e.g., 0.1s) may be needed before `xdotool key ctrl+v` to allow focus to return to the original window after rofi closes.
- **Model cold start.** First invocation after Ollama starts may take longer (~10-30s) while the model loads into memory. Subsequent calls are fast. No timeout is enforced — the "Translating..." notification lets the user know it's working.
- **Terminal apps.** Terminals use `Ctrl+Shift+V` for paste, not `Ctrl+V`. The script detects the focused window's WM_CLASS via `xprop` and checks for known terminal classes (`gnome-terminal`, `kitty`, `alacritty`, `tilix`, `xterm`, `konsole`, `terminator`). If matched, uses `Ctrl+Shift+V`.
- **Clipboard restore.** The script saves the user's clipboard before overwriting it with the result, and restores it after pasting. This avoids permanently trashing clipboard contents.
- **Not all apps supported.** Some apps (sandboxed Flatpaks, remote desktops, certain Electron apps) may not expose PRIMARY selection or accept synthetic paste events. This is a best-effort personal tool, not a universal solution.
