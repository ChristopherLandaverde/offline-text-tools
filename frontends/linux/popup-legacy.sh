#!/usr/bin/env bash
set -euo pipefail

MODEL="qwen2.5:14b"
NOTIFY_TITLE="Language Tool"
SELECTED_SENTINEL="__LANG_TOOL_SELECTED_$$__"
CLIPBOARD_SENTINEL="__LANG_TOOL_CLIPBOARD_$$__"
RESULT_SENTINEL="__LANG_TOOL_RESULT_$$__"

error_exit() {
  notify-send "$NOTIFY_TITLE" "$1"
  exit 1
}

# 1. Grab selected text
SELECTED_TEXT="$(
  {
    xclip -selection primary -o 2>/dev/null || true
    printf '%s' "$SELECTED_SENTINEL"
  }
)"
SELECTED_TEXT="${SELECTED_TEXT%"$SELECTED_SENTINEL"}"

# 2. Validate (not empty, not too long)
if [ -z "$SELECTED_TEXT" ]; then
  error_exit "No text selected"
fi

if [ "${#SELECTED_TEXT}" -gt 5000 ]; then
  error_exit "Text too long (max 5000 chars)"
fi

# 3. Save window ID
WINDOW_ID="$(xdotool getactivewindow 2>/dev/null)" || error_exit "Could not detect active window"

# 4. Show rofi menu
MENU_CHOICE="$(
  printf '%s\n' \
    "Translate to Portuguese" \
    "Translate to English" \
    "Fix Grammar" | rofi -dmenu 2>/dev/null || true
)"

if [ -z "$MENU_CHOICE" ]; then
  exit 0
fi

# 5. Set system prompt based on selection
case "$MENU_CHOICE" in
  "Translate to Portuguese")
    SYSTEM_PROMPT="You are a translator. Translate the following text to Brazilian Portuguese. Output ONLY the translated text, no explanations. Preserve all line breaks, whitespace, and formatting exactly. Do not translate URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping."
    PROGRESS_MESSAGE="Translating..."
    ;;
  "Translate to English")
    SYSTEM_PROMPT="You are a translator. Translate the following text to English. Output ONLY the translated text, no explanations. Preserve all line breaks, whitespace, and formatting exactly. Do not translate URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping."
    PROGRESS_MESSAGE="Translating..."
    ;;
  "Fix Grammar")
    SYSTEM_PROMPT="You are a grammar editor. Fix the grammar and spelling in the following text. Keep the same language. Output ONLY the corrected text, no explanations. Preserve all line breaks, whitespace, formatting, and capitalization style exactly. Do not alter URLs, code, file paths, or proper nouns. Do not add quotes, markdown fences, or any wrapping."
    PROGRESS_MESSAGE="Fixing grammar..."
    ;;
  *)
    exit 0
    ;;
esac

# 6. Save current clipboard
ORIGINAL_CLIPBOARD="$(
  {
    xclip -selection clipboard -o 2>/dev/null || true
    printf '%s' "$CLIPBOARD_SENTINEL"
  }
)"
ORIGINAL_CLIPBOARD="${ORIGINAL_CLIPBOARD%"$CLIPBOARD_SENTINEL"}"

# 7. Show progress notification
notify-send "$NOTIFY_TITLE" "$PROGRESS_MESSAGE"

# 8. Call Ollama API (jq to build JSON, curl to send)
PAYLOAD="$(
  jq -n \
    --arg model "$MODEL" \
    --arg system "$SYSTEM_PROMPT" \
    --arg prompt "$SELECTED_TEXT" \
    '{model: $model, system: $system, prompt: $prompt, stream: false}'
)"

if ! API_RESPONSE="$(curl -sS \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    http://localhost:11434/api/generate 2>/dev/null)"; then
  error_exit "Ollama is not running"
fi

# 9. Validate response
API_ERROR="$(printf '%s' "$API_RESPONSE" | jq -r '.error // empty' 2>/dev/null || true)"
if [ -n "$API_ERROR" ] && printf '%s' "$API_ERROR" | grep -qi 'not found'; then
  error_exit "Model $MODEL not found. Run: ollama pull $MODEL"
fi

RESULT="$(
  {
    printf '%s' "$API_RESPONSE" | jq -r '.response' 2>/dev/null || true
    printf '%s' "$RESULT_SENTINEL"
  }
)"
RESULT="${RESULT%"$RESULT_SENTINEL"}"
if [ -z "$RESULT" ] || [ "$RESULT" = "null" ] || [ -n "$API_ERROR" ]; then
  error_exit "Translation failed"
fi

# 10. Write result to clipboard
printf '%s' "$RESULT" | xclip -selection clipboard

# 11. Refocus window
xdotool windowactivate "$WINDOW_ID"

# 12. Detect terminal, paste with correct keystroke
WM_CLASS="$(xprop -id "$WINDOW_ID" WM_CLASS 2>/dev/null || true)"
sleep 0.1

if printf '%s' "$WM_CLASS" | tr '[:upper:]' '[:lower:]' | grep -Eq 'gnome-terminal|kitty|alacritty|tilix|xterm|konsole|terminator'; then
  xdotool key ctrl+shift+v
else
  xdotool key ctrl+v
fi

# 13. Restore clipboard
sleep 0.5
printf '%s' "$ORIGINAL_CLIPBOARD" | xclip -selection clipboard

# 14. Show done notification
notify-send "$NOTIFY_TITLE" "Done"
