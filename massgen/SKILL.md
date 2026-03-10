---
name: massgen
description: "Invoke MassGen's multi-agent system for general-purpose tasks, evaluation, planning, or spec writing. Use whenever you want multiple AI agents to tackle a problem, need outside perspective on your work, a thoroughly refined plan, or a well-specified set of requirements. Perfect for: writing, code generation, research, design, analysis, pre-PR review, complex project planning, feature specification, architecture decisions, or any task where multi-agent iteration produces better results than working alone."
---

# MassGen

Invoke MassGen for multi-agent iteration on any task — general-purpose work, evaluation, planning, or spec writing. Multiple AI agents independently work on the problem and converge on the strongest result through MassGen's checklist-gated voting system.

## When to Use

**General** (default) — get multi-agent results on any task:
- When you want multiple AI agents to independently tackle a problem
- When the task doesn't fit neatly into evaluate, plan, or spec
- Writing, research, code generation, design, analysis, or any open-ended task

**Evaluate** — get diverse, critical feedback on existing work:
- After iterating and stalling — need outside perspective
- Before submitting PRs or delivering artifacts
- When wanting diverse AI perspectives on implementation quality

**Plan** — create or refine a structured project plan:
- When starting a complex feature or project that needs task decomposition
- When an existing plan has gaps, is too vague, or needs restructuring
- When you need a valid task DAG with verification criteria

**Spec** — create or refine a requirements specification:
- When starting a feature that needs precise requirements before implementation
- When an existing spec has ambiguities, missing edge cases, or gaps
- When you need EARS-formatted requirements with acceptance criteria

## Mode Selection

| Mode | Purpose | Input | Output | Default Criteria Preset |
|------|---------|-------|--------|------------------------|
| general | Any task | Task description + context | Winner's deliverables in `result.md` + workspace files | Auto-generated |
| evaluate | Critique existing work | Artifacts to evaluate | `critique_packet.md`, `verdict.json`, `next_tasks.json` | `"evaluation"` |
| plan | Create or refine a plan | Goal + constraints (+ existing plan) | `project_plan.json` (tasks, chunks, deps, verification) | `"planning"` |
| spec | Create or refine a spec | Problem + needs (+ existing spec) | `project_spec.json` (EARS requirements, chunks, rationale) | `"spec"` |

## Scope

Before starting, determine what the MassGen invocation covers. Focused invocations
produce far better results than unscoped "do everything" runs.

**When invoking this skill, specify the scope:**

- **General**: the task to accomplish, relevant context, quality expectations
- **Evaluate**: which files/artifacts to evaluate, what to ignore, evaluation focus
- **Plan**: the goal/objective, constraints, what context to include
- **Spec**: the problem to specify, user needs, system boundaries

If the user doesn't specify scope, ask them.

## Important: Setup Requires Human Input

MassGen setup (API key configuration, provider selection, Docker choice) currently
requires human interaction. Before invoking this skill, ensure the environment is
already set up — either a `.massgen/config.yaml` exists or the user has provided
a config path. If no config exists, the Setup step below will need user input.

**Config fallback behavior**: If there is no interactive user available (e.g.,
running in a non-interactive agent environment), use whatever config was provided
or fall back to `.massgen/config.yaml`. Do not attempt setup without a user present.

## Prerequisites

### 1. Check if massgen is installed

```bash
uv run massgen --help 2>/dev/null || massgen --help 2>/dev/null
```

If not installed:
```bash
pip install massgen
# or
uv pip install massgen
```

### 2. Resolve configuration

Prefer the lowest-friction path first — do NOT ask unnecessary setup questions:

1. If the user provides a specific config path, use it with `--config <path>` in Step 4.
2. Otherwise, check for an existing project config at `.massgen/config.yaml`.
3. If that does not exist, check for a global default config at `~/.config/massgen/config.yaml`.
4. If either default exists, use it without asking extra setup questions.
5. If no config exists and a user is available, ask them which config to use or proceed to **Setup** below.
6. If no config exists and no user is available, stop — setup requires human input.

### 3. Setup (only if no config exists)

Prefer the browser quickstart first:

```bash
uv run massgen --web-quickstart
```

This opens a temporary setup flow in the browser, lets the user enter API keys,
choose Docker or local execution, configure agents, review the generated YAML,
pick project vs global save location, and then exits automatically when setup is
finished.

Only fall back to headless quickstart when:
- the browser flow is unavailable
- the user explicitly asks for a non-browser flow
- you are operating in an environment where opening the browser is not practical

For headless fallback, first inspect supported backends if needed:

```bash
uv run massgen --list-backends
```

Then use one of these:

```bash
# Single provider (three agents on one backend)
uv run massgen --quickstart --headless \
  --config-backend <backend_type> \
  --config-model <model> \
  --config-docker

# Mixed providers (one explicit agent per backend)
uv run massgen --quickstart --headless \
  --quickstart-agent backend=claude,model=claude-opus-4-6 \
  --quickstart-agent backend=openai,model=gpt-5.4 \
  --quickstart-agent backend=gemini,model=gemini-3-flash-preview \
  --config-docker
```

Omit `--config-docker` if the user wants local execution.

If authentication is missing:
- for login-based backends (`claude_code`, `codex`, `copilot`), help the user run the provider login flow
- for API key backends, help the user populate either `./.env` or `~/.massgen/.env`

If quickstart still needs manual provider/model selection, ask only the minimum necessary follow-up question.

To see all supported backends, models, capabilities, and auth requirements:
```bash
uv run massgen --list-backends
```

## Workflow

### Step 0: Create Working Directory

Create a timestamped subdirectory so parallel invocations don't conflict:

```bash
MODE="general"  # or "evaluate", "plan", or "spec"
WORK_DIR=".massgen/$MODE/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"
```

All artifacts (context, criteria, prompt, output, logs) go in this directory.

### Step 1: Clarify & Write Context File

Read `references/<mode>/workflow.md` (relative to this skill) for the context
file template specific to your mode.

Write `$WORK_DIR/context.md` using the template from the workflow file.

**Key principle for all modes**: provide factual context that orients the MassGen
agents. Do NOT bias them with your opinions about quality — let them discover
issues independently. That's the whole point of multi-agent evaluation.

- **General**: describe the task, relevant context, quality expectations
- **Evaluate**: describe what was built, scope, git info, verification evidence
- **Plan**: describe the goal, constraints, existing context, success criteria
- **Spec**: describe the problem, user needs, system boundaries, constraints

### Step 2: Generate Criteria

Each mode has a default criteria preset that is applied automatically when no
`--eval-criteria` flag is provided:

| Mode | Preset | Criteria Count |
|------|--------|---------------|
| general | Auto-generated | Based on task content |
| evaluate | `"evaluation"` | Generated per-task |
| plan | `"planning"` | 5 must + 3 should |
| spec | `"spec"` | 3 must + 1 should + 1 could |

**To use the default preset**: omit the `--eval-criteria` flag entirely. MassGen
will use the preset matching the prompt content.

For general mode, criteria are auto-generated from the task content — omit
`--eval-criteria` unless you have specific quality axes to enforce.

**To use custom criteria**: read `references/criteria_guide.md` for the format
and writing guide, then write criteria JSON to `$WORK_DIR/criteria.json`.

If there's a specific focus area, weight your criteria toward that focus.
In Claude Code: use AskUserQuestion to ask the user for focus preference.
In Codex or non-interactive: default to general coverage.

```bash
cat > $WORK_DIR/criteria.json << 'EOF'
[
  {"text": "...", "category": "must"},
  {"text": "...", "category": "must"},
  {"text": "...", "category": "should"},
  {"text": "...", "category": "could"}
]
EOF
```

### Step 3: Construct the Prompt

1. Read the prompt template from `references/<mode>/prompt_template.md` (relative to this skill)
2. Read the context file you wrote in Step 1
3. Replace `{{CONTEXT_FILE_CONTENT}}` with the context file contents
4. Replace `{{CUSTOM_FOCUS}}` with the focus directive (or empty string if none)
5. Write the final prompt to `$WORK_DIR/prompt.md`

### Step 4: Run MassGen (in background) and Open Viewer

Launch MassGen in the background and open the web viewer so the user
can observe progress in their browser.

**4a. Start MassGen in background, capturing the log directory:**

Run this command in the background using your agent's native mechanism
(e.g., `run_in_background` in Claude Code):

```bash
uv run massgen --automation \
  --no-parse-at-references \
  --cwd-context ro \
  --eval-criteria $WORK_DIR/criteria.json \
  --output-file $WORK_DIR/result.md \
  "$(cat $WORK_DIR/prompt.md)" \
  > $WORK_DIR/output.log 2>&1
```

If using default criteria (no custom criteria file), omit the `--eval-criteria` flag.

**4b. Extract the log directory and launch the web viewer:**

The automation output's first line is `LOG_DIR: <path>`. Once MassGen
has started (usually within 2 seconds), extract the log directory from
the output and launch the viewer:

```bash
LOG_DIR=$(grep -m1 '^LOG_DIR:' $WORK_DIR/output.log | cut -d' ' -f2)
```

Then launch the web viewer (also in the background):

```bash
uv run massgen viewer "$LOG_DIR" --web
```

The viewer automatically opens `http://localhost:8000` in the user's
browser, showing live agent rounds, voting, and convergence as they
happen.

**Flags explained:**
- `--automation`: clean parseable output, no TUI
- `--no-parse-at-references`: prevents MassGen from interpreting `@path` in the prompt text
- `--cwd-context ro`: gives agents read-only access to the current working directory
- `--eval-criteria`: passes your task-specific criteria JSON (overrides presets)
- `--output-file`: writes the winning agent's answer to a parseable file

If you resolved a custom config path in Step 2, include `--config <path>`.
Otherwise rely on the default project/global config discovery.

**Timing:** expect 2-10 minutes for standard tasks, 10-30 minutes for complex ones.

### Step 5: Parse the Output

The output depends on the mode. The winner's workspace path is shown in
`$WORK_DIR/result.md` (look for "Workspace cwd" or check `status.json` in
the log directory for `workspace_paths`).

**General mode**: the winner's answer is in `$WORK_DIR/result.md`. Any files
the agents created are in the winner's workspace (path shown in result.md).
Copy or reference the workspace files as needed.

**Evaluate mode**: three files — `verdict.json`, `next_tasks.json`, `critique_packet.md`.
Read `verdict.json` first to determine iterate vs converged.
See `references/evaluate/workflow.md` for full output structure.

**Plan mode**: `project_plan.json` — structured task list with chunks,
dependencies, and verification. May include auxiliary files in `research/`,
`framework/`, `risks/` subdirectories.
See `references/plan/workflow.md` for full output structure.

**Spec mode**: `project_spec.json` — EARS requirements with chunks,
rationale, and verification. May include auxiliary files in `research/`,
`design/`, `decisions/` subdirectories.
See `references/spec/workflow.md` for full output structure.

### Step 6: Ground in Your Native Task System

**This is the most critical step for evaluate, plan, and spec modes.** MassGen
produced a structured result — now you must internalize it by entering your
native task/plan mode and enumerating every task or requirement as a tracked
item. Without this, the plan is just text that fades from context as you work.

For **general mode**, grounding is optional — it applies when the output
contains a structured task list or action items, but many general tasks
produce artifacts (code, documents, designs) rather than task lists.

**Why this matters**: agents that skip this step tend to execute the first
few tasks, then drift — forgetting verification steps, skipping later
tasks, or losing track of dependencies. Grounding forces you to commit
to the full scope before executing anything.

**For all modes:**

1. **Enter your task planning mode** (e.g., TodoWrite in Claude Code,
   task tracking in Codex, or whatever native tracking your environment
   provides)
2. **Create one tracked task per item** from the MassGen output:
   - **Evaluate**: each task from `next_tasks.json` becomes a tracked task,
     preserving `implementation_guidance`, `depends_on`, and `verification`
   - **Plan**: each task from `project_plan.json` becomes a tracked task,
     preserving chunk ordering, dependencies, and verification criteria
   - **Spec**: each requirement from `project_spec.json` becomes a tracked
     task (implement + verify), preserving priority, dependencies, and
     acceptance criteria
3. **Preserve the dependency order** — don't flatten the DAG. Tasks in
   chunk C01 must complete before C02 tasks begin
4. **Include verification as explicit tasks** — don't just track "implement
   X", also track "verify X meets [criteria]". Verification that isn't
   tracked doesn't happen
5. **Mark each task's status** as you work: pending → in_progress → completed

**Then execute in order**, updating status as you go. When you complete a
task, check it off and move to the next one. This creates an execution
trace that keeps you honest about what's done and what remains.

### Step 7: Execute and Iterate

**General**: read `result.md` for the winning answer. Copy deliverable
files from the winner's workspace if applicable.

**Evaluate**: read `verdict.json` — if `"iterate"`, work through the
tasks you just grounded from `next_tasks.json`. If `"converged"`,
proceed to delivery.

**Plan / Spec**: store the result as a living document (see below),
then execute the grounded tasks chunk by chunk.

## Living Document Protocol (Plan & Spec Modes)

This is the most important section for plan/spec modes — it defines how
the output is used after MassGen produces it.

### Store

Adopt the MassGen output into `.massgen/plans/` using the existing
`PlanStorage` infrastructure:

```
.massgen/plans/plan_<timestamp>/
├── workspace/          # Mutable working copy
│   ├── plan.json       # (renamed from project_plan.json) or spec.json
│   └── research/       # Auxiliary files from MassGen output
├── frozen/             # Immutable snapshot (identical to workspace/ at creation)
│   ├── plan.json       # or spec.json
│   └── research/
└── plan_metadata.json  # artifact_type, status, chunk_order, context_paths
```

Copy `project_plan.json` → `workspace/plan.json` (or `project_spec.json` →
`workspace/spec.json`). Copy any auxiliary directories. Create `frozen/` as
an identical snapshot.

### Read on Restart

**FIRST ACTION** in every new session: read `workspace/plan.json` (or
`workspace/spec.json`). This is the source of truth for what's done and
what's next.

### Update Continuously

As tasks complete (plan) or requirements are implemented (spec), update
the workspace copy. Mark status, add notes, record discoveries.
The workspace copy is a living document.

### Check Drift

Periodically compare `workspace/` against `frozen/`. The existing
`PlanSession.compute_plan_diff()` returns a `divergence_score`
(0.0 = no drift, 1.0 = complete rewrite). High drift means re-evaluate
whether the plan/spec is still valid.

### Refine When Stuck

If the plan/spec proves wrong or incomplete, re-invoke this skill with
the workspace copy as "What Already Exists" to get multi-agent refinement.
This creates a new plan directory with a fresh `frozen/` snapshot.

### Don't Drift Silently

If you deviate from the plan/spec, update the workspace copy first.
An outdated plan is worse than no plan.

## Mode Overviews

### General

Run any task through MassGen's multi-agent system. Agents independently
produce solutions and converge through checklist-gated voting. Use this
for tasks that don't fit neatly into evaluate, plan, or spec — writing,
code generation, research, analysis, design, or anything where multiple
perspectives improve the result.

See `references/general/workflow.md` for the context template and
output handling.

### Evaluate

Critique existing work artifacts. Evaluator agents inspect your code,
documents, or deliverables and produce a structured critique with
machine-readable verdict, per-criterion scores, and actionable
improvement tasks. The checklist-gated voting system ensures agents
converge on the strongest critique.

See `references/evaluate/workflow.md` for the full context template,
output structure, and examples.

### Plan

Create or refine a structured project plan. Planning agents decompose
the goal into a task DAG with chunks, dependencies, verification
criteria, and technology choices. Each round of MassGen iteration
improves task quality — descriptions get more actionable, verification
gets more specific, sequencing gets tighter.

See `references/plan/workflow.md` for the full context template,
output format, and lifecycle.

### Spec

Create or refine a requirements specification. Spec agents produce
EARS-formatted requirements with acceptance criteria, rationale,
and verification. Iteration focuses on precision — each round
eliminates ambiguities, fills gaps, and strengthens edge case coverage.

See `references/spec/workflow.md` for the full context template,
output format, and lifecycle.

## Condensed Examples

### General: Multi-Agent Task Execution

```bash
WORK_DIR=".massgen/general/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

cat > $WORK_DIR/context.md << 'EOF'
## Task
Build a responsive landing page for a developer tool that converts
CSV files to JSON. Single page with hero, features, and CTA sections.

## Context
- Target audience: developers and data engineers
- Tech stack: HTML, CSS, vanilla JS (no frameworks)
- Must work on mobile and desktop

## Quality Expectations
- Visually polished, not template-looking
- Fast load time, no external dependencies
EOF

# Build prompt from references/general/prompt_template.md, then run
# No --eval-criteria — criteria auto-generated from task
uv run massgen --automation --no-parse-at-references --cwd-context ro \
  --output-file $WORK_DIR/result.md \
  "$(cat $WORK_DIR/prompt.md)" > $WORK_DIR/output.log 2>&1
```

### Evaluate: Pre-PR Review

```bash
WORK_DIR=".massgen/evaluate/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

# Write context (scope: specific deliverables, no quality opinions)
cat > $WORK_DIR/context.md << 'EOF'
## Deliverables in Scope
- `src/api/handler.ts` — API request handler
- `src/hooks/useAuth.ts` — authentication hook

## Out of Scope
- Test files, CI config

## Original Task
Add JWT authentication to the API layer

## What Was Done
Implemented JWT validation in handler and auth hook for React components.

## Verification Evidence
pytest: 24 passed, 0 failed
EOF

# Write criteria (or omit --eval-criteria to use default preset)
cat > $WORK_DIR/criteria.json << 'EOF'
[
  {"text": "Auth security: JWT validation covers expiration, signature, and audience checks.", "category": "must"},
  {"text": "Error handling: invalid/expired tokens produce clear error responses.", "category": "must"},
  {"text": "Code quality: clean separation between auth logic and business logic.", "category": "should"}
]
EOF

# Build prompt from template, then run
uv run massgen --automation --no-parse-at-references --cwd-context ro \
  --eval-criteria $WORK_DIR/criteria.json \
  --output-file $WORK_DIR/result.md \
  "$(cat $WORK_DIR/prompt.md)" > $WORK_DIR/output.log 2>&1
```

### Plan: New Feature Planning

```bash
WORK_DIR=".massgen/plan/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

cat > $WORK_DIR/context.md << 'EOF'
## Goal
Add real-time collaboration to the document editor — multiple users
editing the same document simultaneously with cursor presence.

## Constraints
- Must work with existing PostgreSQL database
- Timeline: 2 weeks
- Team: 2 engineers

## Existing Context
Express.js backend, React frontend, WebSocket already used for notifications.

## Success Criteria
Two users can edit the same document with <500ms sync latency and no data loss.
EOF

# Uses default "planning" preset — no --eval-criteria needed
# Build prompt from references/plan/prompt_template.md, then run
uv run massgen --automation --no-parse-at-references --cwd-context ro \
  --output-file $WORK_DIR/result.md \
  "$(cat $WORK_DIR/prompt.md)" > $WORK_DIR/output.log 2>&1
```

### Spec: Feature Specification

```bash
WORK_DIR=".massgen/spec/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

cat > $WORK_DIR/context.md << 'EOF'
## Problem Statement
Users cannot recover deleted items — deletion is permanent and irreversible.

## User Needs / Personas
- End users: accidentally delete items, need easy recovery
- Admins: need to purge items for compliance after retention period

## Constraints
- PostgreSQL database, soft-delete pattern preferred
- 30-day retention before permanent purge
- Must not break existing API consumers
EOF

# Uses default "spec" preset — no --eval-criteria needed
# Build prompt from references/spec/prompt_template.md, then run
uv run massgen --automation --no-parse-at-references --cwd-context ro \
  --output-file $WORK_DIR/result.md \
  "$(cat $WORK_DIR/prompt.md)" > $WORK_DIR/output.log 2>&1
```

## Reference Files

- `references/general/workflow.md` — general mode context template and output handling
- `references/general/prompt_template.md` — general prompt template with placeholders
- `references/criteria_guide.md` — how to write quality criteria (format, tiers, examples)
- `references/evaluate/workflow.md` — evaluate mode context template, output structure, examples
- `references/evaluate/prompt_template.md` — evaluation prompt template with placeholders
- `references/plan/workflow.md` — plan mode context template, output format, lifecycle
- `references/plan/prompt_template.md` — planning prompt template with placeholders
- `references/spec/workflow.md` — spec mode context template, output format, lifecycle
- `references/spec/prompt_template.md` — spec prompt template with placeholders
- `massgen/subagent_types/round_evaluator/SUBAGENT.md` — source methodology for evaluation
- `massgen/skills/massgen-develops-massgen/SKILL.md` — reference pattern for `--automation`
