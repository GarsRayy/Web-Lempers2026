#!/usr/bin/env bash
# reset-github.sh — menghapus issue, milestone, label (dari backlog.yml), dan project
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKLOG="$SCRIPT_DIR/backlog.yml"
REPO="$(yq -r '.repo' "$BACKLOG")"
OWNER="${REPO%%/*}"
PTITLE="$(yq -r '.project.title' "$BACKLOG")"

echo "==> Issue"
gh issue list --repo "$REPO" --state all --limit 1000 --json number --jq '.[].number' </dev/null |
while read -r n; do
  gh issue delete "$n" --repo "$REPO" --yes </dev/null >/dev/null && echo "  - issue #$n"
done

echo "==> Milestone"
gh api "repos/$REPO/milestones?state=all&per_page=100" --paginate --jq '.[].number' </dev/null |
while read -r n; do
  gh api -X DELETE "repos/$REPO/milestones/$n" </dev/null >/dev/null && echo "  - milestone #$n"
done

echo "==> Label (hanya yang ada di backlog.yml)"
yq -r '.labels[].name' "$BACKLOG" |
while read -r name; do
  gh label delete "$name" --repo "$REPO" --yes </dev/null >/dev/null 2>&1 && echo "  - label $name"
done

echo "==> Project"
num="$(gh project list --owner "$OWNER" --limit 100 --format json </dev/null 2>/dev/null \
  | jq -r --arg t "$PTITLE" '[.projects[] | select(.title == $t)][0].number // empty')"
if [ -n "$num" ]; then
  gh project delete "$num" --owner "$OWNER" </dev/null >/dev/null && echo "  - project #$num"
else
  echo "  (tidak ada project dengan judul itu)"
fi

echo "Selesai."
