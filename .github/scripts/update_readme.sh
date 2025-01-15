#!/bin/bash

echo "Pull Request merged, updating README."

          # Get the issue numbers from the PR body (handles multiple issues)
          ISSUE_NUMBERS=$(echo "${{ github.event.pull_request.body }}" | grep -oE '#[0-9]+' | tr -d '#' | xargs -n1)

          if [[ -z "$ISSUE_NUMBERS" ]]; then
            echo "No issue numbers found in the PR body. Skipping README update."
            exit 0
          fi

          while IFS= read -r ISSUE_NUMBER; do
            echo "Processing Issue Number: $ISSUE_NUMBER"

            # Get Issue Labels (using jq for reliability)
            ISSUE_LABELS=$(curl -s -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
              -H "Accept: application/vnd.github.v3+json" \
              "https://api.github.com/repos/${{ github.repository }}/issues/$ISSUE_NUMBER" | jq -r '.labels[].name' | paste -sd ",")
            if [[ -z "$ISSUE_LABELS" ]]; then
              ISSUE_LABELS="No Labels"
            fi

            # Create the log entry (single line)
            LOG_ENTRY="Issue #$ISSUE_NUMBER - $ISSUE_LABELS - Closed - @${{ github.actor }}"

            # Use sed to append the line to the README.md
            sed -i "\$a$LOG_ENTRY" README.md

          done <<< "$ISSUE_NUMBERS"