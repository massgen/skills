#!/usr/bin/env bash
# massgen_run.sh — Single launcher for MassGen skill invocations.
#
# Handles the full orchestration atomically: launch MassGen, extract log dir,
# start the web viewer, wait for completion, write a summary. This eliminates
# the multi-step background coordination that AI agents tend to mishandle.
#
# Usage:
#   bash <skill_dir>/scripts/massgen_run.sh --work-dir $WORK_DIR --prompt-file $WORK_DIR/prompt.md [options]
#
# Options:
#   --work-dir DIR          Working directory for output (required)
#   --prompt-file FILE      Path to prompt file (required)
#   --criteria-file FILE    Path to criteria JSON (optional)
#   --config FILE           Path to MassGen config YAML (optional)
#   --criteria-preset NAME  Criteria preset name (e.g., planning, evaluation, persona)
#   --output-file FILE      Path for result output (default: $WORK_DIR/result.md)
#   --viewer                Launch web viewer for live observation
#   --viewer-port PORT      Port for web viewer (default: 8000)
#   --no-cwd-context        Disable cwd-context (default: ro)
#   --extra-args "..."      Additional massgen CLI args (quoted string)
#
# Output:
#   $WORK_DIR/output.log       Full MassGen output
#   $WORK_DIR/run_summary.json Summary with log_dir, exit_code, duration, etc.
#   $WORK_DIR/result.md        Winner's answer (if --output-file not overridden)

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
WORK_DIR=""
PROMPT_FILE=""
CRITERIA_FILE=""
CRITERIA_PRESET=""
CONFIG_FILE=""
OUTPUT_FILE=""
VIEWER=false
VIEWER_PORT=8000
CWD_CONTEXT="ro"
EXTRA_ARGS=""

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --work-dir)      WORK_DIR="$2"; shift 2 ;;
        --prompt-file)   PROMPT_FILE="$2"; shift 2 ;;
        --criteria-file) CRITERIA_FILE="$2"; shift 2 ;;
        --criteria-preset) CRITERIA_PRESET="$2"; shift 2 ;;
        --config)        CONFIG_FILE="$2"; shift 2 ;;
        --output-file)   OUTPUT_FILE="$2"; shift 2 ;;
        --viewer)        VIEWER=true; shift ;;
        --viewer-port)   VIEWER_PORT="$2"; shift 2 ;;
        --no-cwd-context) CWD_CONTEXT=""; shift ;;
        --extra-args)    EXTRA_ARGS="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ── Validate ──────────────────────────────────────────────────────────────────
if [[ -z "$WORK_DIR" ]]; then
    echo "Error: --work-dir is required" >&2
    exit 1
fi
if [[ -z "$PROMPT_FILE" || ! -f "$PROMPT_FILE" ]]; then
    echo "Error: --prompt-file is required and must exist" >&2
    exit 1
fi

mkdir -p "$WORK_DIR"
OUTPUT_FILE="${OUTPUT_FILE:-$WORK_DIR/result.md}"
OUTPUT_LOG="$WORK_DIR/output.log"
SUMMARY_FILE="$WORK_DIR/run_summary.json"
VIEWER_PID=""
START_TIME=$(date +%s)

# ── Cleanup on exit ──────────────────────────────────────────────────────────
cleanup() {
    if [[ -n "$VIEWER_PID" ]]; then
        kill "$VIEWER_PID" 2>/dev/null || true
        wait "$VIEWER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ── Build MassGen command ────────────────────────────────────────────────────
CMD=(uv run massgen --automation --no-parse-at-references)

if [[ -n "$CWD_CONTEXT" ]]; then
    CMD+=(--cwd-context "$CWD_CONTEXT")
fi
if [[ -n "$CRITERIA_FILE" && -f "$CRITERIA_FILE" ]]; then
    CMD+=(--eval-criteria "$CRITERIA_FILE")
fi
if [[ -n "$CRITERIA_PRESET" ]]; then
    CMD+=(--checklist-criteria-preset "$CRITERIA_PRESET")
fi
if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
    CMD+=(--config "$CONFIG_FILE")
fi
CMD+=(--output-file "$OUTPUT_FILE")

# Add extra args (word-split intentionally)
if [[ -n "$EXTRA_ARGS" ]]; then
    # shellcheck disable=SC2206
    CMD+=($EXTRA_ARGS)
fi

# Prompt goes last
PROMPT_CONTENT=$(cat "$PROMPT_FILE")
CMD+=("$PROMPT_CONTENT")

# ── Launch MassGen ───────────────────────────────────────────────────────────
echo "Starting MassGen..."
"${CMD[@]}" > "$OUTPUT_LOG" 2>&1 &
MASSGEN_PID=$!

# ── Wait for LOG_DIR and launch viewer ───────────────────────────────────────
LOG_DIR=""

# Wait up to 30 seconds for LOG_DIR to appear
for i in $(seq 1 60); do
    if [[ -f "$OUTPUT_LOG" ]]; then
        LOG_DIR=$(grep -m1 '^LOG_DIR:' "$OUTPUT_LOG" 2>/dev/null | cut -d' ' -f2 || true)
        if [[ -n "$LOG_DIR" ]]; then
            break
        fi
    fi
    sleep 0.5
done

# Resolve relative LOG_DIR to absolute (MassGen outputs relative paths)
if [[ -n "$LOG_DIR" && ! "$LOG_DIR" = /* ]]; then
    if [[ -d "$LOG_DIR" ]]; then
        LOG_DIR="$(cd "$LOG_DIR" && pwd)"
    else
        LOG_DIR="$(pwd)/$LOG_DIR"
    fi
fi

if [[ -n "$LOG_DIR" ]]; then
    echo "Log directory: $LOG_DIR"
fi

if $VIEWER && [[ -n "$LOG_DIR" ]]; then
    echo "Starting web viewer on port $VIEWER_PORT..."
    uv run massgen viewer "$LOG_DIR" --web --port "$VIEWER_PORT" --no-browser > /dev/null 2>&1 &
    VIEWER_PID=$!
    echo "Viewer running at http://localhost:$VIEWER_PORT"
elif $VIEWER; then
    echo "Warning: Could not extract LOG_DIR after 30s, skipping viewer" >&2
fi

# ── Wait for MassGen to finish ───────────────────────────────────────────────
echo "Waiting for MassGen to complete (PID: $MASSGEN_PID)..."
wait "$MASSGEN_PID" || true
EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# ── Extract LOG_DIR if we didn't get it earlier ──────────────────────────────
if [[ -z "$LOG_DIR" && -f "$OUTPUT_LOG" ]]; then
    LOG_DIR=$(grep -m1 '^LOG_DIR:' "$OUTPUT_LOG" 2>/dev/null | cut -d' ' -f2 || true)
    # Resolve relative path
    if [[ -n "$LOG_DIR" && ! "$LOG_DIR" = /* ]]; then
        if [[ -d "$LOG_DIR" ]]; then
            LOG_DIR="$(cd "$LOG_DIR" && pwd)"
        else
            LOG_DIR="$(pwd)/$LOG_DIR"
        fi
    fi
fi

# ── Write summary ────────────────────────────────────────────────────────────
VIEWER_PORT_JSON=$($VIEWER && echo "$VIEWER_PORT" || echo "null")
cat > "$SUMMARY_FILE" << ENDJSON
{
  "exit_code": $EXIT_CODE,
  "duration_seconds": $DURATION,
  "log_dir": "${LOG_DIR:-null}",
  "output_file": "$OUTPUT_FILE",
  "output_log": "$OUTPUT_LOG",
  "work_dir": "$WORK_DIR",
  "viewer_port": $VIEWER_PORT_JSON,
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
ENDJSON

echo ""
echo "═══════════════════════════════════════════"
echo "  MassGen complete"
echo "  Exit code: $EXIT_CODE"
echo "  Duration:  ${DURATION}s"
echo "  Log dir:   ${LOG_DIR:-unknown}"
echo "  Result:    $OUTPUT_FILE"
echo "  Summary:   $SUMMARY_FILE"
echo "═══════════════════════════════════════════"

exit $EXIT_CODE
