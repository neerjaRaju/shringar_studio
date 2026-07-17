#!/usr/bin/env bash
# Push the combined Shringar Studio repo to GitHub.
#
# Prereqs (one-time):
#   - GitHub CLI:  https://cli.github.com   (macOS: brew install gh) then: gh auth login
#     ...OR a Personal Access Token:        export GITHUB_TOKEN=ghp_xxxxx
#
# Then run:  bash push_to_github.sh
set -euo pipefail

OWNER="neerjaRaju"
REPO="shringar_studio"
cd "$(dirname "$0")"

# Create the repo if gh is available and it doesn't exist.
if command -v gh >/dev/null 2>&1; then
  gh repo view "$OWNER/$REPO" >/dev/null 2>&1 || \
    gh repo create "$OWNER/$REPO" --public --source=. --remote=origin --disable-wiki >/dev/null
fi

git remote set-url origin "https://github.com/$OWNER/$REPO.git" 2>/dev/null \
  || git remote add origin "https://github.com/$OWNER/$REPO.git"
git branch -M main
git push -u origin main

echo
echo "Pushed -> https://github.com/$OWNER/$REPO"
echo "Next: enable Actions, then run 'Daily Database Build' once to cut the first Release."
