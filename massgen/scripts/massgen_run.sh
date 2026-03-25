#!/usr/bin/env bash
# massgen_run.sh — Launch a MassGen checkpoint delegation.
#
# Handles the full delegation atomically: launch MassGen with the WebUI,
# wait for completion, write a summary. The WebUI runs by default so users
# can watch the team's progress in real time.
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
#   --no-webui              Disable WebUI (run headless)
#   --webui-port PORT       Port for WebUI (default: 8000)
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
WEBUI=true
WEBUI_PORT=8000
CWD_CONTEXT="ro"
EXTRA_ARGS=""

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --work-dir)        WORK_DIR="$2"; shift 2 ;;
        --prompt-file)     PROMPT_FILE="$2"; shift 2 ;;
        --criteria-file)   CRITERIA_FILE="$2"; shift 2 ;;
        --criteria-preset) CRITERIA_PRESET="$2"; shift 2 ;;
        --config)          CONFIG_FILE="$2"; shift 2 ;;
        --output-file)     OUTPUT_FILE="$2"; shift 2 ;;
        --no-webui)        WEBUI=false; shift ;;
        --webui-port)      WEBUI_PORT="$2"; shift 2 ;;
        --no-cwd-context)  CWD_CONTEXT=""; shift ;;
        --extra-args)      EXTRA_ARGS="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ── Validate args ─────────────────────────────────────────────────────────────
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
MASSGEN_PID=""
START_TIME=$(date +%s)

# ── Pre-flight: check MassGen installed ──────────────────────────────────────
if ! command -v massgen &>/dev/null && ! uv run massgen --help &>/dev/null 2>&1; then
    echo "Error: MassGen is not installed." >&2
    echo "Install with: uv tool install massgen" >&2
    exit 1
fi

# ── Pre-flight: resolve config ───────────────────────────────────────────────
if [[ -z "$CONFIG_FILE" ]]; then
    # Auto-discover config
    if [[ -f ".massgen/config.yaml" ]]; then
        CONFIG_FILE=".massgen/config.yaml"
        echo "Using config: $CONFIG_FILE"
    elif [[ -f "$HOME/.config/massgen/config.yaml" ]]; then
        CONFIG_FILE="$HOME/.config/massgen/config.yaml"
        echo "Using config: $CONFIG_FILE"
    else
        echo "No MassGen config found. Launching setup wizard..."
        echo "Complete setup in your browser, then this script will continue."
        uv run massgen --web-quickstart --web-port "$WEBUI_PORT"
        # web-quickstart writes .massgen/config.yaml and exits
        if [[ -f ".massgen/config.yaml" ]]; then
            CONFIG_FILE=".massgen/config.yaml"
            echo "Config created: $CONFIG_FILE"
        else
            echo "Error: Setup was cancelled or failed. No config created." >&2
            exit 1
        fi
    fi
fi

# ── Cleanup on exit ──────────────────────────────────────────────────────────
cleanup() {
    if [[ -n "$MASSGEN_PID" ]]; then
        kill "$MASSGEN_PID" 2>/dev/null || true
        wait "$MASSGEN_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

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

# WebUI: runs as part of the MassGen process (real-time WebSocket streaming)
if $WEBUI; then
    CMD+=(--web --web-port "$WEBUI_PORT" --no-browser)
fi

# Add extra args (word-split intentionally)
if [[ -n "$EXTRA_ARGS" ]]; then
    # shellcheck disable=SC2206
    CMD+=($EXTRA_ARGS)
fi

# Prompt goes last
PROMPT_CONTENT=$(cat "$PROMPT_FILE")
CMD+=("$PROMPT_CONTENT")

# ── Launch MassGen ───────────────────────────────────────────────────────────
echo "Delegating to MassGen team..."
"${CMD[@]}" > "$OUTPUT_LOG" 2>&1 &
MASSGEN_PID=$!

if $WEBUI; then
    echo "WebUI: http://localhost:$WEBUI_PORT"
fi

# ── Wait for LOG_DIR ─────────────────────────────────────────────────────────
LOG_DIR=""

for i in $(seq 1 60); do
    if [[ -f "$OUTPUT_LOG" ]]; then
        LOG_DIR=$(grep -m1 '^LOG_DIR:' "$OUTPUT_LOG" 2>/dev/null | cut -d' ' -f2 || true)
        if [[ -n "$LOG_DIR" ]]; then
            break
        fi
    fi
    sleep 0.5
done

if [[ -n "$LOG_DIR" ]]; then
    echo "Log directory: $LOG_DIR"
fi

# ── Wait for completion ──────────────────────────────────────────────────────
echo "Waiting for checkpoint to complete (PID: $MASSGEN_PID)..."
wait "$MASSGEN_PID" || true
EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# ── Extract LOG_DIR if we didn't get it earlier ──────────────────────────────
if [[ -z "$LOG_DIR" && -f "$OUTPUT_LOG" ]]; then
    LOG_DIR=$(grep -m1 '^LOG_DIR:' "$OUTPUT_LOG" 2>/dev/null | cut -d' ' -f2 || true)
fi

# ── Write summary ────────────────────────────────────────────────────────────
WEBUI_PORT_JSON=$($WEBUI && echo "$WEBUI_PORT" || echo "null")
cat > "$SUMMARY_FILE" << ENDJSON
{
  "exit_code": $EXIT_CODE,
  "duration_seconds": $DURATION,
  "log_dir": "${LOG_DIR:-null}",
  "output_file": "$OUTPUT_FILE",
  "output_log": "$OUTPUT_LOG",
  "work_dir": "$WORK_DIR",
  "webui_port": $WEBUI_PORT_JSON,
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
ENDJSON

echo ""
echo "═══════════════════════════════════════════"
echo "  Checkpoint complete"
echo "  Exit code: $EXIT_CODE"
echo "  Duration:  ${DURATION}s"
echo "  Log dir:   ${LOG_DIR:-unknown}"
echo "  Result:    $OUTPUT_FILE"
echo "  Summary:   $SUMMARY_FILE"
echo "═══════════════════════════════════════════"

exit $EXIT_CODE
