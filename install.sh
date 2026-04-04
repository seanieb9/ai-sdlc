#!/usr/bin/env bash
# SDLC Framework — Claude Code hook installer
# Merges SDLC hooks into ~/.claude/settings.json without touching other settings.
# Safe to re-run: skips hooks that are already installed.

set -e

SETTINGS="$HOME/.claude/settings.json"

# ── dependencies ────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required.  Install with: brew install jq  (or apt install jq)"
  exit 1
fi

# ── ensure settings file exists ─────────────────────────────────────────────
mkdir -p "$HOME/.claude"
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
  echo "Created $SETTINGS"
fi

# ── detect OS for stat command ───────────────────────────────────────────────
if stat -f %m "$SETTINGS" &>/dev/null; then
  STAT_CMD='stat -f %m'   # macOS
else
  STAT_CMD='stat -c %Y'   # Linux
fi

# ── hook definitions ─────────────────────────────────────────────────────────

SESSION_START_CMD="BRANCH=\$(git branch --show-current 2>/dev/null | tr '[:upper:]' '[:lower:]' | sed 's|/|--|g;s|[^a-z0-9-]|-|g;s|-\\\\+|-|g;s|^-||;s|-\$||'); [ -z \"\$BRANCH\" ] && BRANCH=\"default\"; STATE=\".claude/ai-sdlc/workflows/\$BRANCH/state.json\"; if [ ! -f \"\$STATE\" ]; then echo '{\"systemMessage\": \"No SDLC checkpoint found. Run /sdlc:checkpoint to save your session state.\"}'; elif [ \$(( \$(date +%s) - \$($STAT_CMD \"\$STATE\") )) -gt 86400 ]; then echo '{\"systemMessage\": \"SDLC checkpoint is over 24h old. Run /sdlc:checkpoint to refresh before starting work.\"}'; fi"

POST_COMPACT_CMD="echo '{\"hookSpecificOutput\": {\"hookEventName\": \"PostCompact\", \"additionalContext\": \"Context was just auto-compacted. Immediately run /sdlc:resume to restore project state from the checkpoint saved in state.json.\"}}'"

# ── install helpers ───────────────────────────────────────────────────────────

install_hook() {
  local event="$1"
  local status_msg="$2"
  local cmd="$3"

  # Skip if a hook with this statusMessage already exists under this event
  if jq -e --arg event "$event" --arg sm "$status_msg" \
    '.hooks[$event][]?.hooks[]? | select(.statusMessage == $sm)' \
    "$SETTINGS" &>/dev/null; then
    echo "  ✓ $event ($status_msg) — already installed, skipped"
    return
  fi

  local hook_entry
  hook_entry=$(jq -n \
    --arg cmd "$cmd" \
    --arg sm "$status_msg" \
    '{"hooks": [{"type": "command", "command": $cmd, "statusMessage": $sm}]}')

  local tmp
  tmp=$(jq \
    --arg event "$event" \
    --argjson entry "$hook_entry" \
    '.hooks[$event] = ((.hooks[$event] // []) + [$entry])' \
    "$SETTINGS")

  echo "$tmp" > "$SETTINGS"
  echo "  ✓ $event ($status_msg) — installed"
}

# ── run installs ──────────────────────────────────────────────────────────────

echo ""
echo "Installing SDLC hooks into $SETTINGS"
echo ""

install_hook "SessionStart"  "Checking SDLC checkpoint..."  "$SESSION_START_CMD"
install_hook "PostCompact"   "Restoring SDLC context..."    "$POST_COMPACT_CMD"

# ── validate JSON ─────────────────────────────────────────────────────────────

if ! jq empty "$SETTINGS" &>/dev/null; then
  echo ""
  echo "Error: $SETTINGS has invalid JSON after install. Check the file manually."
  exit 1
fi

echo ""
echo "Done. Open Claude Code and run /hooks to confirm they're active."
echo ""
echo "  SessionStart  →  warns if no checkpoint or checkpoint is >24h old"
echo "  PostCompact   →  auto-injects /sdlc:resume after context compaction"
echo ""
echo "Run /sdlc:checkpoint in your project to save your first checkpoint."
