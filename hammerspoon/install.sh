#!/usr/bin/env bash
# Installs Hammerspoon (if needed) and the Forward and Archive hotkey.
#
# Usage:
#   ./hammerspoon/install.sh
# Non-interactive:
#   ACCT_NAME="you@gmail.com" DEST_ADDRESS="dest@example.com" ./hammerspoon/install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HS_DIR="$HOME/.hammerspoon"
SRC_SCRIPT="$REPO_DIR/src/forward-and-archive.applescript"
SRC_LUA="$REPO_DIR/hammerspoon/forward-and-archive.lua"
DEST_SCRIPT="$HS_DIR/forward-and-archive.applescript"
DEST_LUA="$HS_DIR/forward-and-archive.lua"
INIT_LUA="$HS_DIR/init.lua"
REQUIRE_LINE='require("forward-and-archive")'

# 1. Hammerspoon
if [ -d "/Applications/Hammerspoon.app" ] || [ -d "$HOME/Applications/Hammerspoon.app" ]; then
  echo "✓ Hammerspoon already installed"
elif command -v brew >/dev/null 2>&1; then
  echo "→ Installing Hammerspoon with Homebrew…"
  brew install --cask hammerspoon
else
  echo "✗ Hammerspoon not found and Homebrew isn't installed."
  echo "  Install Hammerspoon from https://www.hammerspoon.org/ and re-run this script."
  exit 1
fi

# 2. Configuration
ACCT_NAME="${ACCT_NAME:-}"
DEST_ADDRESS="${DEST_ADDRESS:-}"
if [ -z "$ACCT_NAME" ]; then
  read -rp "Mail account Description (Mail > Settings > Accounts), e.g. you@gmail.com: " ACCT_NAME
fi
if [ -z "$DEST_ADDRESS" ]; then
  read -rp "Address to forward messages to: " DEST_ADDRESS
fi
if [ -z "$ACCT_NAME" ] || [ -z "$DEST_ADDRESS" ]; then
  echo "✗ Both values are required."; exit 1
fi
case "$ACCT_NAME$DEST_ADDRESS" in
  *'"'*|*'|'*|*'\'*) echo "✗ Values may not contain \" | or \\"; exit 1 ;;
esac

# 3. Copy files (backing up anything already there)
mkdir -p "$HS_DIR"
for f in "$DEST_SCRIPT" "$DEST_LUA"; do
  if [ -f "$f" ]; then cp "$f" "$f.bak"; echo "  (backed up $(basename "$f") → $(basename "$f").bak)"; fi
done

sed -e "s|^property acctName : .*|property acctName : \"$ACCT_NAME\"|" \
    -e "s|^property destAddress : .*|property destAddress : \"$DEST_ADDRESS\"|" \
    "$SRC_SCRIPT" > "$DEST_SCRIPT"
cp "$SRC_LUA" "$DEST_LUA"
echo "✓ Installed $DEST_SCRIPT"
echo "✓ Installed $DEST_LUA"

# 4. Load from init.lua
touch "$INIT_LUA"
if grep -qF "$REQUIRE_LINE" "$INIT_LUA"; then
  echo "✓ init.lua already loads forward-and-archive"
else
  printf '\n-- Forward and Archive (Apple Mail)\n%s\n' "$REQUIRE_LINE" >> "$INIT_LUA"
  echo "✓ Added $REQUIRE_LINE to $INIT_LUA"
fi

# 5. Launch
open -a Hammerspoon || true

cat <<MSG

Next steps:
  1. Grant Hammerspoon Accessibility access when prompted
     (System Settings → Privacy & Security → Accessibility → Hammerspoon).
  2. Hammerspoon menu-bar icon → Reload Config.
  3. In Mail, select messages in the Inbox and press Ctrl-Option-Cmd-F.
  4. Allow Hammerspoon/osascript to control Mail and System Events when prompted.
MSG
