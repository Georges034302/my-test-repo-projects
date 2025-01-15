#!/bin/bash

echo "Pull Request merged, updating README."

# Extract issue numbers (using tr to remove newlines and grep to find #numbers)
ISSUE_NUMBERS=$(echo "${{ github.event.pull_request.body }}" | tr -d '\n' | grep -oE '#[0-9]+' | tr -d '#' | xargs -n1)

if [[ -z "$ISSUE_NUMBERS" ]]; then
  echo "No issue numbers found. Skipping README update."
  exit 0
fi

while IFS= read -r ISSUE_NUMBER; do
  echo "Processing Issue #$ISSUE_NUMBER"

  # Get Issue Labels (with fallback if no labels)
  ISSUE_LABELS=$(curl -s -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${{ github.repository }}/issues/$ISSUE_NUMBER" | jq -r '.labels[].name' | paste -sd "," || echo "No Labels")

  # Append to README (using printf for better formatting control)
  printf "Issue #%s - %s - Closed - @%s\n" "$ISSUE_NUMBER" "$ISSUE_LABELS" "${{ github.actor }}" >> README.md
done <<< "$ISSUE_NUMBERS"

# Commit and push changes
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"
git add README.md
git commit -m "Update issue status log"
git push