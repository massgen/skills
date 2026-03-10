# Evaluate Mode Workflow

Critique existing work artifacts using MassGen's multi-agent evaluation system.
Multiple AI evaluators independently inspect your deliverables and converge on
the strongest critique through checklist-gated voting.

## Overview

Use evaluate mode when you have existing artifacts (code, documents, designs)
and want diverse, critical feedback. The evaluators produce a structured
critique with machine-readable verdict, per-criterion scores, and actionable
improvement tasks.

## Context File Template

Write `$WORK_DIR/context.md` with this structure. The context file has two
jobs: (1) orient the evaluators so they don't waste time discovering basic
facts, and (2) stay out of the way so evaluators can find problems **you
don't know about**.

**What you provide** (evaluators cannot infer this):
- What was built and why (the task, not your assessment of quality)
- Scope — which files to look at, which to ignore
- Factual state — git info, file structure, test output
- Verification evidence already gathered (so evaluators don't re-run it)

**What you explicitly do NOT provide:**
- Your opinion on what's wrong — that biases the evaluators
- Detailed acceptance criteria checklists — the evaluation criteria handle this
- "Areas of concern" — the evaluators should discover concerns independently

```markdown
## Deliverables in Scope
<the specific files/artifacts to evaluate — list each file path and what it is>

## Out of Scope
<files/directories evaluators should NOT spend time on>

## Original Task
<what the user asked for — keep factual, not evaluative>

## What Was Done
<summary of implementation work completed — facts, not quality judgments>

## File Structure
<relevant directory tree / key files overview>

## Git Info
<git diff --stat, recent commits, branch info>
<for patches: include actual diff or key changed files>

## Verification Evidence
<test output, build results, lint output — raw facts the evaluators can reuse>

## Known Stuck Points (optional)
<ONLY if you have specific problems you've tried and failed to fix>
<describe what you tried and why it didn't work — evaluators will prescribe
a different strategy. do NOT list general concerns or quality worries here>
```

## Two Evaluation Modes

The context naturally splits into two evaluation approaches:

1. **Known stuck points**: You know what's wrong but can't fix it. List what
   you tried and why it failed. The evaluator diagnoses your failure mode and
   prescribes a different approach.

2. **Unknown unknowns** (the primary value): You don't know what's wrong.
   The evaluation criteria express what you *value* at a high level.
   The evaluator discovers specific problems you didn't know existed by
   applying those criteria against the actual deliverables. This is why the
   context file should NOT contain your quality opinions.

## Criteria Focus Areas

When writing custom criteria (instead of using the default evaluation preset),
you can weight toward a specific focus:

- **Security**: vulnerabilities, injection risks, auth issues, secrets exposure, OWASP top 10
- **Performance**: algorithmic complexity, resource usage, caching opportunities, N+1 queries
- **Architecture**: design patterns, separation of concerns, extensibility, coupling
- **Test coverage**: missing tests, edge cases, test quality, coverage gaps
- **Code quality**: readability, maintainability, naming, patterns, DRY violations

## Output Structure

The evaluator agents produce three files in the winner's workspace:

| File | Format | Purpose |
|---|---|---|
| `verdict.json` | JSON | Machine-readable verdict (`iterate`/`converged`) + per-criterion scores (E1..EN, 1-10) |
| `next_tasks.json` | JSON | Implementation handoff: `objective`, `primary_strategy`, `tasks[]` with `implementation_guidance` |
| `critique_packet.md` | Markdown | Full prose critique (see sections below) |

**`verdict.json` schema:**
```json
{
  "schema_version": "1",
  "verdict": "iterate",
  "scores": {
    "E1": 4,
    "E2": 7,
    "E3": 8
  }
}
```

**`next_tasks.json` schema** (when verdict is "iterate"):
```json
{
  "schema_version": "1",
  "objective": "...",
  "primary_strategy": "...",
  "why_this_strategy": "...",
  "deprioritize_or_remove": ["..."],
  "tasks": [
    {
      "id": "task_id",
      "description": "What to do",
      "implementation_guidance": "Step-by-step HOW with specific techniques",
      "priority": "high",
      "depends_on": [],
      "verification": "How to verify this task is done",
      "verification_method": "Concrete check to run",
      "metadata": {
        "impact": "transformative",
        "relates_to": ["E1", "E3"]
      }
    }
  ]
}
```

**`critique_packet.md` sections:**

| Section | Purpose |
|---|---|
| `criteria_interpretation` | What each requirement really demands |
| `criterion_findings` | Where the work falls short, with evidence |
| `cross_answer_synthesis` | Strongest dimensions, gaps, what improvement looks like |
| `unexplored_approaches` | 1-3 fresh ideas nobody tried yet |
| `preserve` | What must survive into the next revision |
| `improvement_spec` | Design spec with `concrete_steps` per criterion |
| `verification_plan` | Checks to rerun after implementation |
| `evidence_gaps` | Missing evidence that limited the critique |
| **Evaluation Summary** | Quick-reference: verdict, top improvements, preserve, next steps |

## Applying Feedback

Read `verdict.json` first:

- **`"converged"`**: The work meets the quality bar. Proceed to delivery.
- **`"iterate"`**: Ground the tasks in your native task system, then execute.

### Grounding (iterate verdict)

Before executing anything, enter your native task/plan mode and create
one tracked task per entry in `next_tasks.json`:

1. Enter task planning mode (e.g., TodoWrite in Claude Code)
2. Create a tracked task for each item in `tasks[]`, preserving:
   - `description` and `implementation_guidance` (the specific HOW)
   - `depends_on` ordering
   - `verification` and `verification_method` as explicit sub-tasks
3. Include a final verification task for each criterion that scored low

This prevents you from executing the first few tasks then drifting.
Every task — including verification — must be tracked and checked off.

### Executing

Work through tasks in dependency order. For each task:

- Follow `implementation_guidance` — it has specific techniques and steps
- Pay attention to `prior_attempt_awareness` — if evaluators identified
  failed approaches, do NOT retry them
- Consult `critique_packet.md` for the full `improvement_spec` with
  `concrete_steps` per criterion
- Mark the task complete only after its `verification_method` passes
- When all tasks are done, consider re-invoking the skill for another
  evaluation round to confirm convergence

## Full Example: Pre-PR Code Review

```bash
# Create eval directory
WORK_DIR=".massgen/evaluate/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

# Write context (scope: 2 specific deliverables, no quality opinions)
cat > $WORK_DIR/context.md << 'EOF'
## Deliverables in Scope
- `massgen/websocket_handler.py` — WebSocket server implementation
- `webui/src/hooks/useAgentStatus.ts` — client-side React hook

## Out of Scope
- Test files, CI config, package.json changes

## Original Task
Add WebSocket support for real-time agent status updates

## What Was Done
Implemented WebSocket server and client hook. Server broadcasts agent state
changes, client subscribes per session. Uses native WebSocket API.

## Git Info
Branch: feat/websocket-status (12 commits ahead of main)
Key files changed: websocket_handler.py, useAgentStatus.ts, types.ts

## Verification Evidence
pytest: 47 passed, 0 failed
vitest: 12 passed, 0 failed
EOF

# Write criteria
cat > $WORK_DIR/criteria.json << 'EOF'
[
  {"text": "Reconnection reliability: WebSocket auto-reconnects within 5s of disconnect with exponential backoff, no message loss during reconnect window.", "category": "must"},
  {"text": "Latency requirement: status updates arrive at the client within 500ms of agent state change under normal load.", "category": "must"},
  {"text": "Concurrency: system handles 3+ simultaneous agent sessions without message cross-contamination or dropped updates.", "category": "must"},
  {"text": "Error handling: connection failures, malformed messages, and server errors produce clear client-side feedback without crashing the UI.", "category": "should"},
  {"text": "Code quality: WebSocket handler and client hook have clean separation of concerns, no duplicated state management, and consistent error patterns.", "category": "should"}
]
EOF

# Build prompt (fill template from references/evaluate/prompt_template.md)
# ... (follow Step 3 in SKILL.md)

# Run in background
uv run massgen --automation --no-parse-at-references --cwd-context ro \
  --eval-criteria $WORK_DIR/criteria.json \
  --output-file $WORK_DIR/result.md \
  "$(cat $WORK_DIR/prompt.md)" \
  > $WORK_DIR/output.log 2>&1

# Extract LOG_DIR and open web viewer
LOG_DIR=$(grep -m1 '^LOG_DIR:' $WORK_DIR/output.log | cut -d' ' -f2)
uv run massgen viewer "$LOG_DIR" --web
```
