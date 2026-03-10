# Plan Mode Workflow

Create or refine a structured project plan using MassGen's multi-agent system.
Planning agents decompose the goal into a task DAG with chunks, dependencies,
verification criteria, and technology choices. Each round of iteration improves
task quality rather than adding prose.

## Overview

Use plan mode in two scenarios:

1. **Create from scratch** — you have a goal/objective but no plan. MassGen
   agents produce a structured `project_plan.json` with actionable tasks.
2. **Refine existing** — you have a plan but it has gaps, is too vague, or
   needs restructuring. Provide the existing plan as context and MassGen
   agents improve it.

## Clarification Phase

BEFORE launching MassGen, the calling agent should gather enough context
to write a good context file:

- **Identify the goal** clearly — what needs to be achieved, not how
- **Understand constraints** — timeline, resources, technology stack, budget
- **Gather existing context** — codebase overview, prior decisions, dependencies
- **For refinement**: read the existing plan, identify what works and what doesn't
- **Use AskUserQuestion** for unclear goals (in interactive environments)

Don't skip this phase. A vague context file produces a vague plan.

## Context File Template

Write `$WORK_DIR/context.md` with this structure:

```markdown
## Goal
<what needs to be planned — the objective, not how to achieve it>

## Constraints
<timeline, team size, technology restrictions, budget>

## Existing Context
<codebase overview, architecture, dependencies, stakeholder needs>

## What Already Exists (if refining)
<paste or reference the existing plan>
<note what works and what needs improvement — factual, not evaluative>

## Success Criteria
<what makes this plan good enough to execute>

## Custom Format (optional)
<if the user has their own plan format, include it here so agents produce
output in that format instead of the default project_plan.json>
```

## Default Criteria

The `"planning"` preset is used automatically when no `--eval-criteria` flag
is provided. It includes 5 must + 3 should criteria covering:

- Scope capture without drift
- Task graph validity and consistency
- Actionability (WHAT + HOW, not just WHAT)
- Verification guidance matched to task type
- Technology choices explicit and justified
- Interface contracts between connected tasks
- Assumptions and trade-offs documented
- Thoughtful sequencing and risk management

Custom criteria via `--eval-criteria` override the preset entirely.

## Output Format

Agents produce structured files in their workspace:

### Primary: `project_plan.json`

Same schema as MassGen's `--plan` mode:

```json
{
  "tasks": [
    {
      "id": "F001",
      "chunk": "C01_foundation",
      "description": "Feature Name - what it accomplishes, expected outcome",
      "status": "pending",
      "depends_on": ["F000"],
      "priority": "high|medium|low",
      "metadata": {
        "verification": "How to verify this task is complete",
        "verification_method": "Output-first verification approach",
        "verification_group": "optional_group_name"
      }
    }
  ]
}
```

### Auxiliary (optional)

Organized into purpose-driven subdirectories:

- `research/` — background research, prior art, feasibility analysis, codebase exploration notes
- `framework/` — architecture decisions, technology choices with rationale, design patterns selected
- `risks/` — risk register, mitigation strategies, dependency analysis
- `requirements/` — user stories, acceptance criteria, requirements docs

Chunks are ordered as a valid DAG (C01_foundation, C02_backend, etc.).

Auxiliary files support the plan but are NOT the plan — `project_plan.json`
is always the source of truth.

**Custom format override**: If the context file specifies a custom plan format,
agents produce that format instead of `project_plan.json`.

## Output Parsing

Read `project_plan.json` from the winner's workspace. The workspace path is
shown in `$WORK_DIR/result.md` (look for "Workspace cwd" or check `status.json`
in the log directory for `workspace_paths`).

The structured JSON keeps refinement tight — each MassGen iteration improves
task quality (descriptions, verification, sequencing) rather than adding prose.

## Grounding the Plan in Your Task System

**Before you start executing, enter your native task/plan mode and
enumerate every task from `project_plan.json` as a tracked item.**

This is not optional. Without this step, agents execute the first few
tasks then lose track — skipping verification, forgetting later chunks,
or drifting from the plan's dependency ordering.

1. **Enter task planning mode** (e.g., TodoWrite in Claude Code, native
   task tracking in Codex, or your environment's equivalent)
2. **Create one tracked task per entry** in `project_plan.json`:
   - Use the task's `id` and `description`
   - Preserve `chunk` grouping — tasks in C01 before C02
   - Preserve `depends_on` ordering
   - Copy `metadata.verification` as an explicit verification sub-task
3. **Add a verification task for each chunk** — after all tasks in a
   chunk are complete, run the chunk's verification group
4. **Execute in order**: pending → in_progress → completed, checking off
   each task as its verification passes

The plan on disk (`workspace/plan.json`) is the source of truth for WHAT
to do. Your native task system is the execution tracker for WHERE you are.
Keep both in sync.

## Using the Plan (Lifecycle)

Leverages existing `PlanStorage` infrastructure (`massgen/plan_storage.py`):

### 1. Store

Create a plan directory in `.massgen/plans/plan_<timestamp>/`:

```
.massgen/plans/plan_<timestamp>/
├── workspace/              # Mutable working copy
│   ├── plan.json           # Renamed from project_plan.json
│   ├── research/           # Auxiliary files from MassGen output
│   ├── framework/
│   └── risks/
├── frozen/                 # Immutable snapshot (identical to workspace/ at creation)
│   ├── plan.json
│   ├── research/
│   ├── framework/
│   └── risks/
└── plan_metadata.json      # artifact_type: "plan", status, chunk_order, context_paths
```

Copy `project_plan.json` → `workspace/plan.json`. Copy any auxiliary
directories. Create `frozen/` as an identical snapshot.

### 2. Read on Restart

**FIRST ACTION** in every new session: read `workspace/plan.json`.
This is the source of truth for what's done and what's next.

### 3. Update Continuously

As tasks complete, update `"status": "completed"` in `workspace/plan.json`.
Add discovery notes to auxiliary files. The workspace copy is a living document.

### 4. Check Drift

Periodically compare `workspace/plan.json` against `frozen/plan.json`.
The existing `PlanSession.compute_plan_diff()` returns a `divergence_score`
(0.0 = no changes, 1.0 = complete rewrite). High drift means re-evaluate
whether the plan is still valid.

### 5. Refine When Stuck

If the plan proves wrong or incomplete, re-invoke the skill with the
workspace plan as "What Already Exists" to get multi-agent refinement.
This creates a new plan directory with a fresh `frozen/` snapshot.

### 6. Don't Drift Silently

If you deviate from the plan, update `workspace/plan.json` first.
An outdated plan is worse than no plan.
