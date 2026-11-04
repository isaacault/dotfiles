#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Claude Code status line:  Opus 5 | ctx 98k/1.0M 10% | $1.82 | dotfiles
#
# Claude Code runs this on every render and pipes session JSON on stdin
# (https://code.claude.com/docs/en/statusline). Wire it up in
# ~/.claude/settings.json:
#   "statusLine": {"type": "command", "command": "python3 ~/.claude/statusline.py"}
# It must never fail loudly: any error prints nothing rather than a traceback.

import json
import os
import sys

DIM, CYAN, YELLOW, RED, RESET = "\033[2m", "\033[36m", "\033[33m", "\033[31m", "\033[0m"


def short(n):
    if n < 1000:
        return str(n)
    if n < 999500:
        return "%dk" % round(n / 1000)
    return "%.1fM" % (n / 1e6)


def number(v):
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) else None


def context(cw):
    size = number(cw.get("context_window_size"))
    if not size:
        return None
    usage = cw.get("current_usage")
    if not isinstance(usage, dict):  # before the first reply, and right after /compact
        return DIM + "ctx --/" + short(size) + RESET
    used = sum(number(usage.get(k)) or 0 for k in
               ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
    pct = number(cw.get("used_percentage"))
    if pct is None:
        pct = 100.0 * used / size
    colour = RED if pct >= 80 else YELLOW if pct >= 60 else DIM
    return colour + "ctx %s/%s %d%%" % (short(used), short(size), pct) + RESET


def main():
    data = json.loads(sys.stdin.read() or "{}")
    if not data:
        return
    model = data.get("model") or {}
    parts = [CYAN + (model.get("display_name") or model.get("id") or "?") + RESET]

    ctx = context(data.get("context_window") or {})
    if ctx:
        parts.append(ctx)

    cost = number((data.get("cost") or {}).get("total_cost_usd"))
    if cost is not None:
        parts.append(DIM + "$%.2f" % cost + RESET)

    cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or ""
    if cwd:
        parts.append(DIM + os.path.basename(cwd.rstrip("/")) + RESET)

    sys.stdout.write((DIM + " | " + RESET).join(parts))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
