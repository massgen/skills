#!/usr/bin/env bash
# massgen_run.sh — Lightweight wrapper for MassGen skill invocations.
#
# Translates skill-level flags (--mode, --cwd-context) into massgen CLI args.
# MassGen handles config discovery, logging, and workspace management internally.
#
# Usage:
#   bash massgen_run.sh [options] "prompt"
#
# Options:
#   --mode MODE          general (default), evaluate, plan, spec
#   --cwd-context CTX    ro (default), rw, off
#   --quick              Skip refinement (one-shot, no voting)
#   --web                Enable WebUI (default: on)
#   --no-web             Disable WebUI
#   --web-port PORT      WebUI port (default: 8000)
#   --criteria FILE      Custom criteria JSON file
#   --config FILE        Override config path
#   --extra "ARGS"       Additional massgen CLI args (word-split)
#
# Output:
#   MassGen prints LOG_DIR, STATUS, ANSWER paths. Answer in LOG_DIR answer.txt.

set -euo pipefail

MODE="general"
CWD_CTX="off"
QUICK=false
WEB=true
WEB_PORT=8000
CRITERIA=""
CONFIG=""
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)        MODE="$2"; shift 2 ;;
        --cwd-context) CWD_CTX="$2"; shift 2 ;;
        --quick)       QUICK=true; shift ;;
        --web)         WEB=true; shift ;;
        --no-web)      WEB=false; shift ;;
        --web-port)    WEB_PORT="$2"; shift 2 ;;
        --criteria)    CRITERIA="$2"; shift 2 ;;
        --config)      CONFIG="$2"; shift 2 ;;
        --extra)       # shellcheck disable=SC2206
                       EXTRA_ARGS+=($2); shift 2 ;;
        --)            shift; break ;;
        *)             break ;;
    esac
done

PROMPT="${*}"
if [[ -z "$PROMPT" ]]; then
    echo "Error: prompt required" >&2
    exit 1
fi

# Clear CLAUDECODE so claude_code backend agents can spawn nested sessions
unset CLAUDECODE

CMD=(uv run massgen --automation --no-parse-at-references)

# CWD context
if [[ "$CWD_CTX" != "off" ]]; then
    CMD+=(--cwd-context "$CWD_CTX")
fi

# Mode
case "$MODE" in
    general)  ;;
    evaluate) CMD+=(--checklist-criteria-preset evaluation) ;;
    plan)     CMD+=(--plan) ;;
    spec)     CMD+=(--spec) ;;
    *)        echo "Unknown mode: $MODE" >&2; exit 1 ;;
esac

# Options
if $QUICK; then CMD+=(--quick); fi
if $WEB; then CMD+=(--web --no-browser --web-port "$WEB_PORT"); fi
if [[ -n "$CRITERIA" ]]; then CMD+=(--eval-criteria "$CRITERIA"); fi
if [[ -n "$CONFIG" ]]; then CMD+=(--config "$CONFIG"); fi
# Append extra args (guard against unbound empty array with set -u)
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then CMD+=("${EXTRA_ARGS[@]}"); fi

# Prompt last
CMD+=("$PROMPT")

exec "${CMD[@]}"
