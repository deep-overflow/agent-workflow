#!/usr/bin/env bash
# Claude Code custom status line

DATA=$(cat)

get() {
  echo "$DATA" | awk -F'"' -v key="\"$1\"" '{for(i=1;i<=NF;i++){if($i==key){gsub(/^[: \t]+/,"",$((i+1)));print $(i+2);exit}}}'
}

# Simple JSON value extractor using grep+sed
val() {
  echo "$DATA" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//;s/^"//;s/"$//'
}

C="\033[38;5;218m"
R="\033[0m"
B="\033[1;38;5;218m"
G="\033[32m"
RD="\033[31m"

bar() {
  local pct="${1:-0}"
  local len=10
  # Handle empty or non-numeric
  case "$pct" in
    ''|*[!0-9.]*) pct=0 ;;
  esac
  local filled=$(awk "BEGIN{printf \"%d\", $pct * $len / 100}")
  local empty=$((len - filled))
  local b=""
  for ((i=0; i<filled; i++)); do b+="━"; done
  for ((i=0; i<empty; i++)); do b+="░"; done
  echo "$b"
}

fmt_pct() {
  local p="${1:-0}"
  case "$p" in
    ''|*[!0-9.]*) p="0" ;;
  esac
  awk "BEGIN{printf \"%.1f\", $p}"
}

fmt_time() {
  local epoch="$1"
  if [ -z "$epoch" ] || [ "$epoch" = "null" ]; then
    echo "N/A"
    return
  fi
  date -d "@$epoch" "+%H:%M" 2>/dev/null || echo "N/A"
}

# Extract values - handle nested JSON with jq-like grep approach
model=$(echo "$DATA" | grep -o '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"display_name"[[:space:]]*:[[:space:]]*"//;s/"$//')
cwd=$(echo "$DATA" | grep -o '"current_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"current_dir"[[:space:]]*:[[:space:]]*"//;s/"$//')
project=$(echo "$DATA" | grep -o '"project_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"project_dir"[[:space:]]*:[[:space:]]*"//;s/"$//')
added=$(val "total_lines_added")
removed=$(val "total_lines_removed")
in_tok=$(val "total_input_tokens")
out_tok=$(val "total_output_tokens")
used_pct=$(val "used_percentage")

: "${model:=N/A}"
: "${cwd:=N/A}"
: "${added:=0}"
: "${removed:=0}"
: "${in_tok:=0}"
: "${out_tok:=0}"
: "${used_pct:=0}"

parts=""
sep=" | "

# Model
parts+="${B}${model}${R}"

# Context
parts+="${sep}${C}ctx:${R}[$(bar "$used_pct")]$(fmt_pct "$used_pct")% ${C}in:${R}${in_tok} ${C}out:${R}${out_tok}"

# Workspace
parts+="${sep}${C}cwd:${R}${cwd}"
if [ -n "$project" ]; then
  parts+="${sep}${C}proj:${R}${project}"
fi

# Diff
parts+="${sep}${C}diff:${R}${G}+${added}${R}${RD}-${removed}${R}"

# Rate limits - find five_hour used_percentage
rl5_pct=$(echo "$DATA" | grep -o '"five_hour"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"used_percentage"[[:space:]]*:[[:space:]]*[0-9.]*' | sed 's/.*:[[:space:]]*//')
if [ -n "$rl5_pct" ]; then
  rl5_reset=$(echo "$DATA" | grep -o '"five_hour"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"resets_at"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*:[[:space:]]*//')
  rl7_pct=$(echo "$DATA" | grep -o '"seven_day"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"used_percentage"[[:space:]]*:[[:space:]]*[0-9.]*' | sed 's/.*:[[:space:]]*//')
  rl7_reset=$(echo "$DATA" | grep -o '"seven_day"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"resets_at"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*:[[:space:]]*//')
  parts+="${sep}${C}5h:${R}[$(bar "$rl5_pct")]$(fmt_pct "$rl5_pct")%($(fmt_time "$rl5_reset"))"
  parts+="${sep}${C}7d:${R}[$(bar "${rl7_pct:-0}")]$(fmt_pct "${rl7_pct:-0}")%($(fmt_time "$rl7_reset"))"
fi

# Worktree
wt_name=$(echo "$DATA" | grep -o '"worktree"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"name"[[:space:]]*:[[:space:]]*"//;s/"$//')
if [ -n "$wt_name" ]; then
  wt_branch=$(echo "$DATA" | grep -o '"worktree"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"branch"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"branch"[[:space:]]*:[[:space:]]*"//;s/"$//')
  wt_path=$(echo "$DATA" | grep -o '"worktree"[[:space:]]*:[[:space:]]*{[^}]*}' | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"path"[[:space:]]*:[[:space:]]*"//;s/"$//')
  parts+="${sep}${C}wt:${R}${wt_name}(${wt_branch:-?})@${wt_path:-?}"
fi

echo -e "$parts"
