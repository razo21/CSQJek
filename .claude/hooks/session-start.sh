#!/bin/bash
# CSQJek SessionStart hook — shared-branch clash check.
#
# The user runs/builds CSQJek in Xcode on their Mac, while Claude works in this
# session. Both share one branch, so changes can clash. This hook reminds Claude
# (and the user) to reconcile pull/push state before building, and flags when the
# remote branch already has commits this session's checkout does not.
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ]; then
  exit 0
fi

# Best-effort fetch so the ahead/behind comparison is accurate (never block on it).
git fetch origin "$BRANCH" --quiet 2>/dev/null || true

LOCAL=$(git rev-parse HEAD 2>/dev/null || true)
REMOTE=$(git rev-parse "origin/$BRANCH" 2>/dev/null || true)

echo "=== CSQJek shared-branch check (branch: $BRANCH) ==="
echo "Before building on CSQJek, Claude MUST check with the user and confirm they have:"
echo "  1. Pushed any local Xcode/desktop changes to '$BRANCH', and"
echo "  2. Pulled the latest from '$BRANCH' onto their Mac."
echo "The desktop and this session share one branch, so this prevents clashes."
echo "Ask the user 'Have you already pulled?' — if not, pause and reconcile before editing."

if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
  BEHIND=$(git rev-list --count "HEAD..origin/$BRANCH" 2>/dev/null || echo 0)
  AHEAD=$(git rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo 0)
  if [ "${BEHIND:-0}" -gt 0 ]; then
    echo ""
    echo "WARNING — POTENTIAL CLASH: origin/$BRANCH has $BEHIND commit(s) not in this"
    echo "session's checkout (this session is ahead by $AHEAD). Someone — likely the"
    echo "user's desktop — pushed changes that are not here yet. STOP and confirm with"
    echo "the user before building; offer to run 'git pull origin $BRANCH' (or rebase) first."
  fi
fi

exit 0
