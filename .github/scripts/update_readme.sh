#!/bin/bash

echo "Pull Request merged, updating README."

# Get the issue numbers from the PR body using a here string
ISSUE_NUMBERS=$(cat <<EOF
${{ github.event.pull_request.body }}
EOF
)

# Extract issue numbers (handle potential errors)
ISSUE_NUMBERS=$(echo "$ISSUE_NUMBERS" | tr -d '\n' | grep -oE '#[0-9]+' || true)

if [[ -z "$ISSUE_NUMBERS" ]]; then
  echo "No issue numbers found in the PR body. Skipping README update."
  exit 0
fi

while IFS= read -r ISSUE_NUMBER; do
  echo "Processing Issue Number: $ISSUE_NUMBER"

  # Get Issue Labels (using jq for reliability)
  ISSUE_LABELS=$(curl -s -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${{ github.repository }}/issues/$ISSUE_NUMBER" | jq -r '.labels[].name' || true)

  if [[ -z "$ISSUE_LABELS" ]]; then
    ISSUE_LABELS="No Labels"
  fi

  # Create the log entry (single line) - Improved formatting
  LOG_ENTRY="Issue #$ISSUE_NUMBER - ${ISSUE_LABELS} - Closed - @${{ github.actor }}"

  # Use sed to append the line to the README.md
  sed -i "\$a$LOG_ENTRY" README.md || true

done <<< "$ISSUE_NUMBERS"

# Commit the changes to the README (handle potential errors)
git config --global user.email "actions@github.com"
git config --global user.name "GitHub Actions"
git add README.md || true
git commit -m "Update issue status log in README" || true
git push || true

echo "Script execution completed."