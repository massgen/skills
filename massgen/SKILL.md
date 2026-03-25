---
name: massgen
description: "Invoke MassGen's multi-agent system for general-purpose tasks, evaluation, planning, or spec writing. Use whenever you want multiple AI agents to tackle a problem, need outside perspective on your work, a thoroughly refined plan, or a well-specified set of requirements. Perfect for: writing, code generation, research, design, analysis, pre-PR review, complex project planning, feature specification, architecture decisions, or any task where multi-agent iteration produces better results than working alone."
---

# MassGen

You are the main agent. MassGen is your team.

Each invocation of this skill is a **checkpoint delegation**: you define the task,
criteria, and context; the team iterates independently and converges on the
strongest result through checklist-gated voting; you get the deliverables back
and continue your work.

This is the same pattern as MassGen's checkpoint coordination mode — you are
the delegator, each MassGen run is a checkpoint, and the results flow back
to you for integration.

## When to Delegate

**General** (default) — delegate any task to the team:
- Writing, research, code generation, design, analysis
- Any task where multiple perspectives improve the result
- When you want diverse independent attempts converged into one

**Evaluate** — delegate critique of existing work:
- After iterating and stalling — need outside perspective
- Before submitting PRs or delivering artifacts
- When you want diverse critical feedback on implementation quality

**Plan** — delegate structured project planning:
- Complex features needing task decomposition
- When an existing plan has gaps or needs restructuring
- When you need a valid task DAG with verification criteria

**Spec** — delegate requirements specification:
- Features needing precise requirements before implementation
- When an existing spec has ambiguities or missing edge cases
- When you need EARS-formatted requirements with acceptance criteria

## Mode Selection

| Mode | Purpose | Input | Output | Default Criteria |
|------|---------|-------|--------|-----------------|
| general | Any task | Task + context | `result.md` + workspace files | Auto-generated |
| evaluate | Critique work | Artifacts to evaluate | `critique_packet.md`, `verdict.json`, `next_tasks.json` | `"evaluation"` |
| plan | Create/refine plan | Goal + constraints | `project_plan.json` (tasks, chunks, deps) | `"planning"` |
| spec | Create/refine spec | Problem + needs | `project_spec.json` (EARS requirements) | `"spec"` |

## First-Time Setup

The launcher script handles this automatically, but here's what happens:

1. **Install check**: MassGen must be installed (`uv tool install massgen`)
2. **Config check**: looks for `.massgen/config.yaml` or `~/.config/massgen/config.yaml`
3. **If no config exists**: the script launches the setup wizard (`--web-quickstart`)
   in the browser. The user picks their models, agent count, and API keys. The
   wizard writes `.massgen/config.yaml` and exits. All future runs use that config.

To override the auto-discovered config, pass `--config <path>` to the launcher.
For CLI-based config creation, see `references/config_setup.md`.

---

## Workflow

### Step 0: Create Working Directory

```bash
MODE="general"  # or "evaluate", "plan", "spec"
WORK_DIR=".massgen/$MODE/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"
```

### Step 1: Write Context File

Read `references/<mode>/workflow.md` (relative to this skill) for the
mode-specific context template. Write `$WORK_DIR/context.md` using that template.

**Key principle**: provide factual context that orients the team. Do NOT bias
them with your quality opinions — let them discover issues independently.

- **General**: task description, relevant context, quality expectations
- **Evaluate**: what was built, scope, git info, verification evidence
- **Plan**: goal, constraints, existing context, success criteria
- **Spec**: problem, user needs, system boundaries, constraints

### Step 2: Generate Criteria

| Mode | Default | Override |
|------|---------|---------|
| general | Auto-generated (omit criteria flags) | `--criteria-file $WORK_DIR/criteria.json` |
| evaluate | `--criteria-preset evaluation` | `--criteria-file $WORK_DIR/criteria.json` |
| plan | `--criteria-preset planning` | `--criteria-file $WORK_DIR/criteria.json` |
| spec | `--criteria-preset spec` | `--criteria-file $WORK_DIR/criteria.json` |

For custom criteria, read `references/criteria_guide.md` for the format, then:

```bash
cat > $WORK_DIR/criteria.json << 'EOF'
[
  {"text": "...", "category": "must"},
  {"text": "...", "category": "should"},
  {"text": "...", "category": "could"}
]
EOF
```

### Step 3: Construct the Prompt

1. Read `references/<mode>/prompt_template.md` (relative to this skill)
2. Read the context file from Step 1
3. Replace `{{CONTEXT_FILE_CONTENT}}` with the context contents
4. Replace `{{CUSTOM_FOCUS}}` with focus directive (or empty string)
5. Write the final prompt to `$WORK_DIR/prompt.md`

### Step 4: Delegate to Team

Use the launcher script to delegate. **The WebUI runs by default** — tell the
user they can watch the team's progress at `http://localhost:8000`.

```bash
# SKILL_DIR is the directory containing this SKILL.md
bash "$SKILL_DIR/scripts/massgen_run.sh" \
  --work-dir "$WORK_DIR" \
  --prompt-file "$WORK_DIR/prompt.md"
```

**Run in the background** using your agent's native mechanism (e.g.,
`run_in_background` in Claude Code).

Add mode-specific flags as needed:

```bash
# With custom criteria
  --criteria-file "$WORK_DIR/criteria.json"

# With preset criteria (plan/spec modes)
  --criteria-preset planning

# With custom config
  --config "$CONFIG_PATH"

# Headless (no WebUI)
  --no-webui

# Different WebUI port
  --webui-port 9000

# Additional massgen flags
  --extra-args "..."
```

**After the background task completes**, read the summary:

```bash
cat $WORK_DIR/run_summary.json
```

**Timing**: expect 15-45 minutes. Do not assume something is stuck — MassGen
runs multiple agents through several rounds of iteration.

### Step 5: Parse Checkpoint Results

The output depends on the mode. The winner's workspace path is in
`$WORK_DIR/result.md` (look for "Workspace cwd") or in `status.json`
in the log directory (`workspace_paths`).

- **General**: winner's answer in `result.md`, deliverable files in workspace
- **Evaluate**: `verdict.json`, `next_tasks.json`, `critique_packet.md`
- **Plan**: `project_plan.json` with chunks, dependencies, verification
- **Spec**: `project_spec.json` with EARS requirements and acceptance criteria

See `references/<mode>/workflow.md` for detailed output structure per mode.

### Step 6: Resume — Ground in Your Task System

**This is the most critical step for evaluate, plan, and spec modes.** The team
produced structured results — now you resume as the main agent and internalize
them into tracked tasks.

For **general mode**, grounding is optional — apply when the output contains
task lists or action items, but many general delegations produce artifacts
(code, documents, designs) rather than tasks.

**Why this matters**: without grounding, you'll execute the first few tasks
then drift — forgetting verification steps, skipping later tasks, losing
dependencies. Grounding forces you to commit to the full scope.

1. **Enter your task planning mode** (TodoWrite, or equivalent)
2. **Create one tracked task per item** from the checkpoint results:
   - **Evaluate**: each task from `next_tasks.json` → tracked task
   - **Plan**: each task from `project_plan.json` → tracked task
   - **Spec**: each requirement from `project_spec.json` → tracked task
3. **Preserve dependency order** — don't flatten the DAG
4. **Include verification as explicit tasks** — verification that isn't tracked doesn't happen
5. **Mark status** as you work: pending → in_progress → completed

### Step 7: Execute and Iterate

Execute the grounded tasks in order. When you hit a point that warrants
another delegation — a review gate, a complex sub-problem, or diminishing
returns — delegate again (go back to Step 0).

**Mode-specific guidance:**

- **General**: read `result.md`, copy deliverable files from workspace
- **Evaluate**: read `verdict.json` — if `"iterate"`, check `approach_assessment`
  in `next_tasks.json`:
  - `ceiling_not_reached` → execute `fix_tasks`, then `evolution_tasks` as stretch
  - `ceiling_approaching` → execute `fix_tasks`, then `evolution_tasks`
  - `ceiling_reached` → consider re-delegating in plan mode with evaluation findings
  - If `"converged"`, proceed to delivery
- **Plan / Spec**: store result as living document (see below), execute chunk by chunk

## Living Document Protocol (Plan & Spec)

### Store

```
.massgen/plans/plan_<timestamp>/
├── workspace/          # Mutable working copy
│   ├── plan.json       # or spec.json
│   └── research/       # Auxiliary files
├── frozen/             # Immutable snapshot at creation
│   ├── plan.json
│   └── research/
└── plan_metadata.json
```

### Read on Restart

**First action in every new session**: read `workspace/plan.json` (or
`workspace/spec.json`). This is the source of truth.

### Update Continuously

As tasks complete, update the workspace copy. Mark status, add notes,
record discoveries. The workspace copy is a living document.

### Check Drift

Compare `workspace/` against `frozen/` periodically. High divergence
means re-evaluate whether the plan is still valid.

### Refine via Delegation

If the plan proves wrong or incomplete, re-invoke this skill with the
workspace copy as context to get multi-agent refinement. This creates
a new plan directory with a fresh `frozen/` snapshot.

## Checkpoint Loop

For complex or creative projects, use iterative delegation — each
iteration is another checkpoint where you delegate to the team.

```
Delegate (plan) → Execute → Delegate (evaluate) → Fix or Re-plan → ...
```

### When to Use

- The task has exploratory components (visual design, creative writing, UX)
- The project is complex enough that the initial plan is partly speculative
- Quality expectations are high
- Prior iterations show diminishing returns

### Protocol

1. **Delegate (plan)**: invoke plan mode. Team classifies tasks as
   `deterministic` or `exploratory` and creates prototypes
2. **Execute**: implement chunk by chunk
3. **Delegate (evaluate)**: at review gates or after exploratory chunks,
   invoke evaluate mode
4. **Decide**: read `approach_assessment`:
   - `ceiling_not_reached` → execute fix_tasks, continue
   - `ceiling_approaching` → execute fix + evolution tasks, continue
   - `ceiling_reached` → re-delegate in plan mode with evaluation discoveries
5. **Evolve**: if re-planning, pass `approach_assessment` and `breakthroughs`
   as context. The new plan amplifies what worked
6. **Repeat** until evaluation returns "converged"

### Termination

- Max 3 plan mutations per chunk — escalate to user if still not converging
- If evaluation returns "converged", the loop is complete
- If the user provides direction, follow it regardless of ceiling status

## Mode Overviews

### General

Delegate any task to the team. Agents independently produce solutions and
converge through voting. No fixed output schema — output depends on the task.
See `references/general/workflow.md`.

### Evaluate

Delegate critique of existing work. Evaluators produce structured critique
with machine-readable verdict, scores, and actionable tasks. The key outputs
are `verdict.json` (iterate vs converged), `next_tasks.json` (implementation
handoff), and `critique_packet.md` (full prose critique with approach assessment).
See `references/evaluate/workflow.md`.

### Plan

Delegate project planning. Planners decompose the goal into a task DAG with
chunks, dependencies, verification criteria, and technology choices. Each
round improves task quality. See `references/plan/workflow.md`.

### Spec

Delegate requirements specification. Spec agents produce EARS-formatted
requirements with acceptance criteria, rationale, and verification. Each
round eliminates ambiguities and fills gaps. See `references/spec/workflow.md`.

## Examples

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

# Build prompt from references/general/prompt_template.md, then:
bash "$SKILL_DIR/scripts/massgen_run.sh" \
  --work-dir "$WORK_DIR" \
  --prompt-file "$WORK_DIR/prompt.md"
```

### Evaluate: Pre-PR Review

```bash
WORK_DIR=".massgen/evaluate/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

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

cat > $WORK_DIR/criteria.json << 'EOF'
[
  {"text": "Auth security: JWT validation covers expiration, signature, and audience.", "category": "must"},
  {"text": "Error handling: invalid/expired tokens produce clear error responses.", "category": "must"},
  {"text": "Code quality: clean separation between auth logic and business logic.", "category": "should"}
]
EOF

# Build prompt from template, then:
bash "$SKILL_DIR/scripts/massgen_run.sh" \
  --work-dir "$WORK_DIR" \
  --prompt-file "$WORK_DIR/prompt.md" \
  --criteria-file "$WORK_DIR/criteria.json"
```

### Plan: Feature Planning

```bash
WORK_DIR=".massgen/plan/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

cat > $WORK_DIR/context.md << 'EOF'
## Goal
Add real-time collaboration to the document editor — multiple users
editing the same document simultaneously with cursor presence.

## Constraints
- Must work with existing PostgreSQL database
- Timeline: 2 weeks, team of 2

## Existing Context
Express.js backend, React frontend, WebSocket used for notifications.

## Success Criteria
Two users edit the same document with <500ms sync latency and no data loss.
EOF

# Build prompt from references/plan/prompt_template.md, then:
bash "$SKILL_DIR/scripts/massgen_run.sh" \
  --work-dir "$WORK_DIR" \
  --prompt-file "$WORK_DIR/prompt.md" \
  --criteria-preset planning
```

### Spec: Feature Specification

```bash
WORK_DIR=".massgen/spec/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"

cat > $WORK_DIR/context.md << 'EOF'
## Problem Statement
Users cannot recover deleted items — deletion is permanent and irreversible.

## User Needs
- End users: accidentally delete items, need easy recovery
- Admins: purge items for compliance after retention period

## Constraints
- PostgreSQL, soft-delete pattern preferred
- 30-day retention before permanent purge
- Must not break existing API consumers
EOF

# Build prompt from references/spec/prompt_template.md, then:
bash "$SKILL_DIR/scripts/massgen_run.sh" \
  --work-dir "$WORK_DIR" \
  --prompt-file "$WORK_DIR/prompt.md" \
  --criteria-preset spec
```

## Reference Files

- `references/config_setup.md` — CLI-based config creation (headless quickstart, list backends)
- `references/general/workflow.md` — general mode context template and output handling
- `references/general/prompt_template.md` — general prompt template with placeholders
- `references/criteria_guide.md` — how to write quality criteria (format, tiers, examples)
- `references/evaluate/workflow.md` — evaluate mode context, output structure, examples
- `references/evaluate/prompt_template.md` — evaluation prompt template
- `references/plan/workflow.md` — plan mode context, output format, lifecycle
- `references/plan/prompt_template.md` — planning prompt template
- `references/spec/workflow.md` — spec mode context, output format, lifecycle
- `references/spec/prompt_template.md` — spec prompt template
