#!/usr/bin/env bash
set -euo pipefail

MODEL="qwen2.5:14b"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/lang-tool.sh"
TARGET_DIR="$HOME/.local/bin"
TARGET_SCRIPT="$TARGET_DIR/lang-tool.sh"
SHORTCUT_NAME="Language Tool"
SHORTCUT_BINDING="<Ctrl><Shift>l"

missing_commands=()
missing_packages=()
declare -A seen_packages=()

check_dependency() {
  local command_name="$1"
  local package_name="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing_commands+=("$command_name")
    if [ -z "${seen_packages[$package_name]+x}" ]; then
      missing_packages+=("$package_name")
      seen_packages["$package_name"]=1
    fi
  fi
}

check_dependency xclip xclip
check_dependency xdotool xdotool
check_dependency xprop x11-utils
check_dependency rofi rofi
check_dependency notify-send libnotify-bin
check_dependency curl curl
check_dependency jq jq

if [ "${#missing_commands[@]}" -gt 0 ]; then
  printf 'Missing dependencies: %s\n' "${missing_commands[*]}"
  printf 'Install them with:\n'
  printf '  sudo apt install %s\n' "${missing_packages[*]}"
  exit 1
fi

if ! command -v ollama >/dev/null 2>&1; then
  printf 'Ollama is not installed.\n'
  printf 'Install it with:\n'
  printf '  curl -fsSL https://ollama.com/install.sh | sh\n'
  exit 1
fi

if ! ollama list 2>/dev/null | grep -Fq "$MODEL"; then
  printf 'Pulling model %s...\n' "$MODEL"
  ollama pull "$MODEL"
fi

if [ ! -f "$SOURCE_SCRIPT" ]; then
  printf 'Source script not found: %s\n' "$SOURCE_SCRIPT"
  exit 1
fi

mkdir -p "$TARGET_DIR"
cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"

if ! command -v gsettings >/dev/null 2>&1; then
  printf 'gsettings is required to register the GNOME shortcut.\n'
  exit 1
fi

EXISTING_SHORTCUTS="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"

# Check if Language Tool shortcut already exists (idempotent re-install)
ALREADY_REGISTERED=0
if [ "$EXISTING_SHORTCUTS" != "@as []" ]; then
  for existing_path in $(printf '%s' "$EXISTING_SHORTCUTS" | tr -d "[]' " | tr ',' '\n'); do
    existing_name="$(gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${existing_path}" name 2>/dev/null || true)"
    if [ "$existing_name" = "'${SHORTCUT_NAME}'" ]; then
      SHORTCUT_PATH="$existing_path"
      ALREADY_REGISTERED=1
      printf 'Updating existing Language Tool shortcut.\n'
      break
    fi
  done
fi

# Create new slot if not already registered
if [ "$ALREADY_REGISTERED" -eq 0 ]; then
  SLOT=0
  while printf '%s' "$EXISTING_SHORTCUTS" | grep -q "custom${SLOT}/"; do
    SLOT=$((SLOT + 1))
  done
  SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${SLOT}/"

  if [ "$EXISTING_SHORTCUTS" = "@as []" ]; then
    UPDATED_SHORTCUTS="['${SHORTCUT_PATH}']"
  else
    UPDATED_SHORTCUTS="$(printf '%s' "$EXISTING_SHORTCUTS" | sed "s|]|, '${SHORTCUT_PATH}']|")"
  fi
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_SHORTCUTS"
fi

gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SHORTCUT_PATH}" name "${SHORTCUT_NAME}"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SHORTCUT_PATH}" command "${TARGET_SCRIPT}"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SHORTCUT_PATH}" binding "${SHORTCUT_BINDING}"

printf 'Language Tool installed successfully.\n'
printf 'Usage:\n'
printf '  1. Select text in any X11 application.\n'
printf '  2. Press Ctrl+Shift+L.\n'
printf '  3. Choose Translate to Portuguese, Translate to English, or Fix Grammar.\n'
