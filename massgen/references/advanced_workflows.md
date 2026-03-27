# Advanced Workflows

Optional reference for complex multi-delegation patterns. The quick dispatch
in SKILL.md covers most use cases — consult this when you need iterative
delegation, living document management, or structured evaluation output.

## Checkpoint Loop

For complex or creative projects, use iterative delegation — each invocation
is a checkpoint where you delegate to the team.

```
Delegate (plan) → Execute → Delegate (evaluate) → Fix or Re-plan → ...
```

### When to Use

- The task has exploratory components (visual design, creative writing, UX)
- The project is complex enough that the initial plan is partly speculative
- Quality expectations are high
- Prior iterations show diminishing returns

### Protocol

1. **Delegate (plan)**: invoke with `--plan`. Team classifies tasks as
   `deterministic` or `exploratory` and creates prototypes
2. **Execute**: implement chunk by chunk
3. **Delegate (evaluate)**: at review gates or after exploratory chunks,
   invoke with `--checklist-criteria-preset evaluation`
4. **Decide**: read the evaluation results:
   - If fixes are needed → execute them, continue
   - If the approach has hit its ceiling → re-delegate in plan mode with findings
5. **Repeat** until evaluation indicates convergence

### Termination

- Max 3 plan mutations per chunk — escalate to user if still not converging
- If the user provides direction, follow it regardless of status

## Living Document Protocol (Plan & Spec)

When using plan or spec mode for a long-running project:

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

If the plan proves wrong or incomplete, re-invoke the skill with the
workspace copy as context to get multi-agent refinement. This creates
a new plan directory with a fresh `frozen/` snapshot.

## Grounding Protocol

After receiving structured results (plan, spec, or evaluation tasks),
ground them in your native task system before executing.

1. **Enter task planning mode** (TodoWrite or equivalent)
2. **Create one tracked task per item** from the results
3. **Preserve dependency order** — don't flatten the DAG
4. **Include verification as explicit tasks**
5. **Mark status** as you work: pending → in_progress → completed

This prevents drift — executing the first few tasks then forgetting
verification steps, skipping later tasks, or losing dependencies.

## Structured Evaluation Output

For machine-readable evaluation results (useful in checkpoint loops), use
the evaluate prompt template in `references/evaluate/prompt_template.md`.
This tells agents to produce:

| File | Purpose |
|------|---------|
| `verdict.json` | Machine-readable verdict (iterate/converged) + per-criterion scores |
| `next_tasks.json` | Implementation handoff with fix_tasks, evolution_tasks, approach_assessment |
| `critique_packet.md` | Full prose critique with improvement spec |

### When to Use

- You need the checkpoint loop (automated iterate/converge decisions)
- You want machine-readable task handoff from evaluation
- You're building automation around evaluation results

For simple reviews (e.g., `/massgen Review this PR`), the default quick
dispatch with `--checklist-criteria-preset evaluation` is sufficient — the
prose answer covers what you need.
