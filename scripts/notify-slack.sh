#!/bin/bash
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
if [ -z "$WEBHOOK_URL" ]; then
  exit 0
fi
MESSAGE="$1"
curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-type: application/json' \
  -d "{\"text\": \"$MESSAGE\"}" > /dev/null
