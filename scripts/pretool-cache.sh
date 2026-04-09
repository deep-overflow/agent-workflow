#!/bin/bash
# Cache the most recent tool invocation per session so that the
# Notification hook can include "what is being approved" context.
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [ -z "$SESSION_ID" ]; then
  exit 0
fi
echo "$INPUT" | jq '{tool_name, tool_input}' > "/tmp/claude-last-tool-${SESSION_ID}.json"
