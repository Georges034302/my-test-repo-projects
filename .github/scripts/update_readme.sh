#!/bin/bash

echo "Pull Request merged, updating README."

# Get the issue numbers from the PR body
RAW_ISSUE_NUMBERS=$(echo "$PR_BODY" | tr -d '\n' | grep -oE '#[0-9]+' | tr -d '#')
ISSUE_NUMBERS=$(echo "$RAW_ISSUE_NUMBERS" | xargs -n1 || true)

while IFS= read -r ISSUE_NUMBER; do
  echo "Processing Issue #$ISSUE_NUMBER"

  # Get Issue Labels (using jq for reliability with fallback)
  ISSUE_LABELS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
              -H "Accept: application/vnd.github.v3+json" \
              "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER" 2>/dev/null | jq -r '.labels[].name' | paste -sd "," || echo "No Labels")

  # Create the log entry
  LOG_ENTRY="Issue #$ISSUE_NUMBER - ${ISSUE_LABELS} - Closed - @$ACTOR_USERNAME"

  # Append to README
  printf "\n%s\n" "$LOG_ENTRY" >> README.md
done <<< "$ISSUE_NUMBERS"

# Commit and push changes (no error checking on commit/push)
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"
git add README.md
git commit -m "Update issue status log"
git push

echo "README update completed."