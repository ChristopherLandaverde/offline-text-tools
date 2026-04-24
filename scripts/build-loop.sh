#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Lang Tool Build Loop
# Orchestrates: Codex implements → Claude reviews → iterate
#
# Usage:
#   ./build-loop.sh              # First run: implement from spec
#   ./build-loop.sh review       # After Claude review: apply fixes
#   ./build-loop.sh "fix X"      # Send specific instructions to Codex
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$PROJECT_DIR/CODEX_PROMPT.md"
REVIEW_FILE="$PROJECT_DIR/REVIEW_FEEDBACK.md"
ITERATION=0

# Track iteration count
if [ -f "$PROJECT_DIR/.iteration" ]; then
  ITERATION=$(cat "$PROJECT_DIR/.iteration")
fi
ITERATION=$((ITERATION + 1))
echo "$ITERATION" > "$PROJECT_DIR/.iteration"

echo "============================================"
echo "  Lang Tool Build Loop — Iteration $ITERATION"
echo "============================================"
echo ""

# Determine mode
MODE="${1:-implement}"

case "$MODE" in
  implement)
    echo "[1/3] Running Codex to implement from spec..."
    echo ""
    PROMPT=$(cat "$PROMPT_FILE")
    ;;
  review)
    if [ ! -f "$REVIEW_FILE" ]; then
      echo "ERROR: No $REVIEW_FILE found."
      echo "Create it with Claude's review feedback, then run again."
      exit 1
    fi
    echo "[1/3] Running Codex to apply review feedback..."
    echo ""
    PROMPT="Read the review feedback in REVIEW_FEEDBACK.md. Apply ALL the requested changes to the files in src/. Do not add features not requested. Do not remove working code unless the review says to."
    ;;
  *)
    echo "[1/3] Running Codex with custom instructions..."
    echo ""
    PROMPT="$MODE

Working on the lang-tool project. The spec is in 2026-04-16-lang-tool-design.md. Apply changes to files in src/."
    ;;
esac

# Run Codex
echo "--- Codex starting ---"
codex exec "$PROMPT" \
  -C "$PROJECT_DIR" \
  -s full-auto \
  -c 'model_reasoning_effort="high"' \
  --enable web_search_cached \
  2>&1 | tee "$PROJECT_DIR/.codex-output-$ITERATION.log"

CODEX_EXIT=$?
echo ""
echo "--- Codex finished (exit: $CODEX_EXIT) ---"
echo ""

# Show what changed
echo "[2/3] Changes made:"
echo ""
cd "$PROJECT_DIR"
git diff --stat
echo ""
echo "--- Full diff ---"
git diff
echo ""

# Save diff for Claude review
git diff > "$PROJECT_DIR/.diff-$ITERATION.patch"

echo "[3/3] Ready for review"
echo ""
echo "============================================"
echo "  Next steps:"
echo "  1. Go back to Claude Code"
echo "  2. Ask Claude to review: .diff-$ITERATION.patch"
echo "  3. If changes needed, Claude writes REVIEW_FEEDBACK.md"
echo "  4. Run: ./build-loop.sh review"
echo "============================================"
echo ""
echo "Files to review:"
git diff --name-only
echo ""
echo "Diff saved to: .diff-$ITERATION.patch"
echo "Codex log: .codex-output-$ITERATION.log"
