#!/usr/bin/env python3
import json, sys
from datetime import datetime

data = json.load(sys.stdin)

def get(path, default=""):
    obj = data
    for key in path.split("."):
        if isinstance(obj, dict) and key in obj:
            obj = obj[key]
        else:
            return default
    return obj if obj is not None else default

C = "\033[36m"  # cyan
R = "\033[0m"   # reset
B = "\033[1;36m"  # bold cyan

def bar(pct, length=10):
    pct = float(pct) if pct else 0
    filled = int(pct * length / 100)
    return "━" * filled + "░" * (length - filled)

def fmt_time(epoch):
    if not epoch:
        return "N/A"
    try:
        return datetime.fromtimestamp(int(epoch)).strftime("%H:%M")
    except Exception:
        return "N/A"

# --- Values ---
model = get("model.display_name", "N/A")
cwd = get("workspace.current_dir", "N/A")
project = get("workspace.project_dir", "N/A")
added = get("cost.total_lines_added", 0)
removed = get("cost.total_lines_removed", 0)
in_tok = get("context_window.total_input_tokens", 0)
out_tok = get("context_window.total_output_tokens", 0)
used_pct = get("context_window.used_percentage", 0)

# Build all parts
parts = []

# Model
parts.append(f"{B}{model}{R}")

# Context with progress bar
parts.append(f"{C}ctx:{R}[{bar(used_pct)}]{float(used_pct):.1f}% in:{in_tok} out:{out_tok}")

# Workspace
parts.append(f"{C}cwd:{R}{cwd}")
parts.append(f"{C}proj:{R}{project}")

# Diff
parts.append(f"{C}diff:{R}\033[32m+{added}\033[0m\033[31m-{removed}\033[0m")

# Rate Limits with progress bars
rl5_pct = get("rate_limits.five_hour.used_percentage")
if rl5_pct != "":
    rl5_time = fmt_time(get("rate_limits.five_hour.resets_at"))
    rl7_pct = get("rate_limits.seven_day.used_percentage", 0)
    rl7_time = fmt_time(get("rate_limits.seven_day.resets_at"))
    parts.append(f"{C}5h:{R}[{bar(rl5_pct)}]{float(rl5_pct):.1f}%({rl5_time})")
    parts.append(f"{C}7d:{R}[{bar(rl7_pct)}]{float(rl7_pct):.1f}%({rl7_time})")

# Worktree
wt_name = get("worktree.name")
if wt_name:
    wt_branch = get("worktree.branch", "?")
    wt_path = get("worktree.path", "?")
    parts.append(f"{C}wt:{R}{wt_name}({wt_branch})@{wt_path}")

# Single line output
print(" | ".join(parts))
