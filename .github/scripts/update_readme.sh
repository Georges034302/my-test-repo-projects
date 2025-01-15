#!/bin/bash

echo "Pull Request merged, updating README."

# Get the issue numbers from the PR body (using the environment variable)
ISSUE_NUMBERS=$(echo "$PR_BODY" | tr -d '\n' | grep -oE '#[0-9]+')

if [[ -z "$ISSUE_NUMBERS" ]]; then
  echo "No issue numbers found in the PR body. Skipping README update."
  exit 0
fi

while IFS= read -r ISSUE_NUMBER; do
  echo "Processing Issue Number: $ISSUE_NUMBER"

  # Get the access token from the secret
  GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }}

  # Get Issue Labels (using jq for reliability)
  ISSUE_LABELS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${{ github.repository }}/issues/$ISSUE_NUMBER" 2>/dev/null | jq -r '.labels[].name' | paste -sd "," || echo "No Labels")

  # Get the username of the actor
  ACTOR_USERNAME=${{ github.actor }}

  # Create the log entry (single line) - Improved formatting
  LOG_ENTRY="Issue #$ISSUE_NUMBER - ${ISSUE_LABELS} - Closed - @$ACTOR_USERNAME"

  # Use sed to append the line to the README.md
  sed -i "\$a$LOG_ENTRY" README.md

done <<< "$ISSUE_NUMBERS"

# Commit the changes to the README (assuming success)
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"
git add README.md
git commit -m "Update issue status log in README"
git push

echo "README update completed."