#!/usr/bin/env bash
# review_watcher.sh — Background watcher for MassGen review modal state.
#
# Polls status.json for review_pending=true and prints structured markers
# that the calling agent (e.g., Claude Code) can parse. When detected,
# the agent can alert the user or resolve the review via REST API.
#
# Usage:
#   review_watcher.sh <LOG_DIR> [--poll-interval SECONDS]
#
# Output markers:
#   __REVIEW_PENDING__
#   REVIEW_URL: <url>
#   REVIEW_API: <api_url>
#   FILES_CHANGED: file1.py (M), file2.py (A)
#   ANSWER_PREVIEW: <first 200 chars>
#   __END_REVIEW_INFO__
#
#   __REVIEW_COMPLETE__ APPROVED=<true|false>

set -euo pipefail

LOG_DIR="${1:-}"
POLL_INTERVAL="${2:-2}"
NOTIFIED=false

if [[ -z "$LOG_DIR" ]]; then
    echo "Error: LOG_DIR required as first argument" >&2
    exit 1
fi

STATUS_FILE="$LOG_DIR/status.json"
REVIEW_REQUEST_FILE="$LOG_DIR/review_request.json"
REVIEW_RESULT_FILE="$LOG_DIR/review_result.json"

while true; do
    # Check if status.json exists
    if [[ -f "$STATUS_FILE" ]]; then
        # Check for review_pending
        review_pending=$(jq -r '.review_pending // false' "$STATUS_FILE" 2>/dev/null || echo "false")

        if [[ "$review_pending" == "true" ]] && [[ "$NOTIFIED" != "true" ]]; then
            # Read review_request.json for details
            if [[ -f "$REVIEW_REQUEST_FILE" ]]; then
                review_url=$(jq -r '.url // "http://localhost:8000/?v=2"' "$REVIEW_REQUEST_FILE" 2>/dev/null)
                review_api=$(jq -r '.api_url // ""' "$REVIEW_REQUEST_FILE" 2>/dev/null)
                answer_preview=$(jq -r '.answer_preview // ""' "$REVIEW_REQUEST_FILE" 2>/dev/null)

                # Build files changed summary
                files_changed=$(jq -r '.files[]? | "\(.path) (\(.status))"' "$REVIEW_REQUEST_FILE" 2>/dev/null | paste -sd', ' - || echo "")
            else
                review_url="http://localhost:8000/?v=2"
                review_api=""
                files_changed=""
                answer_preview=""
            fi

            # Print structured markers for the calling agent
            echo "__REVIEW_PENDING__"
            echo "REVIEW_URL: $review_url"
            if [[ -n "$review_api" ]]; then
                echo "REVIEW_API: $review_api"
            fi
            if [[ -n "$files_changed" ]]; then
                echo "FILES_CHANGED: $files_changed"
            fi
            if [[ -n "$answer_preview" ]]; then
                echo "ANSWER_PREVIEW: $answer_preview"
            fi
            echo "__END_REVIEW_INFO__"

            NOTIFIED=true
        fi

        # Check if review was resolved (review_result.json appeared)
        if [[ "$NOTIFIED" == "true" ]] && [[ -f "$REVIEW_RESULT_FILE" ]]; then
            approved=$(jq -r '.approved // false' "$REVIEW_RESULT_FILE" 2>/dev/null || echo "false")
            echo "__REVIEW_COMPLETE__ APPROVED=$approved"
            NOTIFIED=false
        fi

        # Check if coordination is complete — exit watcher
        is_complete=$(jq -r '.is_complete // false' "$STATUS_FILE" 2>/dev/null || echo "false")
        if [[ "$is_complete" == "true" ]]; then
            break
        fi
    fi

    sleep "$POLL_INTERVAL"
done
