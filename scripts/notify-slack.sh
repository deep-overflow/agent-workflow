#!/bin/bash
# Send a Slack notification with rich context for Claude Code hooks.
# Reads hook event JSON from stdin. Uses Slack Block Kit for visual formatting.

WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
if [ -z "$WEBHOOK_URL" ]; then
  exit 0
fi

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Session label: customTitle from transcript, fallback to first 8 chars of session_id.
SESSION_LABEL=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  SESSION_LABEL=$(grep -m1 '"type":"custom-title"' "$TRANSCRIPT" 2>/dev/null \
    | jq -r '.customTitle // empty' 2>/dev/null)
fi
if [ -z "$SESSION_LABEL" ]; then
  SESSION_LABEL="${SESSION_ID:0:8}"
fi

# Event-specific icon, label, color.
case "$EVENT" in
  Notification)
    ICON="🔐"
    TYPE_LABEL="승인 요청"
    COLOR="#F2994A"  # orange
    ;;
  Stop)
    ICON="✅"
    TYPE_LABEL="작업 완료"
    COLOR="#27AE60"  # green
    ;;
  *)
    ICON="🔔"
    TYPE_LABEL="$EVENT"
    COLOR="#2D9CDB"  # blue
    ;;
esac

# Build body depending on event type.
BODY=""
TOOL_NAME=""
TOOL_DETAIL=""
if [ "$EVENT" = "Notification" ]; then
  CACHE="/tmp/claude-last-tool-${SESSION_ID}.json"
  if [ -f "$CACHE" ]; then
    TOOL_NAME=$(jq -r '.tool_name // empty' "$CACHE")
    TOOL_DETAIL=$(jq -r '
      .tool_input as $i
      | if   $i.command   then $i.command
        elif $i.file_path then $i.file_path
        elif $i.pattern   then $i.pattern
        elif $i.url       then $i.url
        else ($i | tostring)
        end
    ' "$CACHE")
  fi
  if [ -z "$TOOL_NAME" ]; then
    NOTIF_MSG=$(echo "$INPUT" | jq -r '.message // empty')
    BODY="${NOTIF_MSG:-(도구 정보 없음)}"
  fi
elif [ "$EVENT" = "Stop" ]; then
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    LAST_TEXT=$(jq -rs '
      map(select(.type=="assistant"
                 and (.message.content // [] | map(select(.type=="text")) | length > 0)))
      | last
      | .message.content
      | map(select(.type=="text") | .text)
      | join("\n")
    ' "$TRANSCRIPT" 2>/dev/null)
    if [ -n "$LAST_TEXT" ] && [ "$LAST_TEXT" != "null" ]; then
      BODY=$(echo "$LAST_TEXT" | head -c 200)
    fi
  fi
fi

# Build Slack Block Kit payload using jq.
# Header: icon + type label
HEADER="${ICON}  *${TYPE_LABEL}*"

# Context fields as compact key-value lines.
DIR_SHORT=$(basename "$PWD")
CONTEXT_TEXT="*Server*  \`${USER}\`    *Dir*  \`${DIR_SHORT}\`    *Session*  \`${SESSION_LABEL}\`"

# Build detail block content.
DETAIL_BLOCK=""
if [ "$EVENT" = "Notification" ] && [ -n "$TOOL_NAME" ]; then
  # Truncate tool detail for readability.
  DETAIL_TRUNCATED=$(echo "$TOOL_DETAIL" | head -c 300)
  DETAIL_BLOCK=$(jq -n --arg name "$TOOL_NAME" --arg detail "$DETAIL_TRUNCATED" \
    '[
      {"type": "section", "text": {"type": "mrkdwn", "text": ("*Tool:*  `" + $name + "`")}},
      {"type": "section", "text": {"type": "mrkdwn", "text": ("```" + $detail + "```")}}
    ]')
elif [ -n "$BODY" ]; then
  BODY_ESCAPED=$(echo "$BODY" | head -c 200)
  DETAIL_BLOCK=$(jq -n --arg body "$BODY_ESCAPED" \
    '[{"type": "section", "text": {"type": "mrkdwn", "text": $body}}]')
else
  DETAIL_BLOCK="[]"
fi

PAYLOAD=$(jq -n \
  --arg color "$COLOR" \
  --arg header "$HEADER" \
  --arg context "$CONTEXT_TEXT" \
  --argjson detail "$DETAIL_BLOCK" \
  '{
    "attachments": [
      {
        "color": $color,
        "blocks": (
          [
            {"type": "section", "text": {"type": "mrkdwn", "text": $header}},
            {"type": "context", "elements": [{"type": "mrkdwn", "text": $context}]},
            {"type": "divider"}
          ] + $detail
        )
      }
    ]
  }')

curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-type: application/json' \
  -d "$PAYLOAD" > /dev/null
