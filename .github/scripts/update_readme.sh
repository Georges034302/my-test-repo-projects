#!/bin/bash

echo "Pull Request merged, updating README."

# Get the PR body from the environment variable (set in the workflow YAML)
PR_BODY="${PR_BODY}"

# Extract issue numbers (using tr to remove newlines and grep to find #numbers)
ISSUE_NUMBERS=$(echo "$PR_BODY" | tr -d '\n' | grep -oE '#[0-9]+' | tr -d '#' | xargs -n1)

if [[ -z "$ISSUE_NUMBERS" ]]; then
  echo "No issue numbers found. Skipping README update."
  exit 0
fi

while IFS= read -r ISSUE_NUMBER; do
  echo "Processing Issue #$ISSUE_NUMBER"

  # Get the access token from the secret (set as environment variable in workflow)
  GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}"

  # Get Issue Labels (with fallback if no labels)
  ISSUE_LABELS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${{ github.repository }}/issues/$ISSUE_NUMBER" 2>/dev/null | jq -r '.labels[].name' | paste -sd "," || echo "No Labels")

  # Get the username of the actor (set as environment variable in workflow)
  ACTOR_USERNAME="${{ github.actor }}"

  # Append to README (using printf for better formatting control)
  printf "Issue #%s - %s - Closed - @%s\n" "$ISSUE_NUMBER" "$ISSUE_LABELS" "$ACTOR_USERNAME" >> README.md
done <<< "$ISSUE_NUMBERS"

# Commit and push changes
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"
git add README.md
git commit -m "Update issue status log"
git push