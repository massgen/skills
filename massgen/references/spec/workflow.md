# Spec Mode Workflow

Create or refine a requirements specification using MassGen's multi-agent system.
Spec agents produce EARS-formatted requirements with acceptance criteria, rationale,
and verification. Each round of iteration eliminates ambiguities, fills gaps, and
strengthens edge case coverage.

## Overview

Use spec mode in two scenarios:

1. **Create from scratch** — you have a problem and user needs but no specification.
   MassGen agents produce a structured `project_spec.json` with precise requirements.
2. **Refine existing** — you have a spec but it has ambiguities, missing edge cases,
   or gaps. Provide the existing spec as context and MassGen agents improve it.

## Clarification Phase

BEFORE launching MassGen, the calling agent should gather enough context
to write a good context file:

- **Identify the problem** — what problem does this spec address
- **Understand user needs** — who will use this, what workflows matter
- **Map system boundaries** — what's in scope, what interfaces exist
- **Understand constraints** — technical, organizational, regulatory, timeline
- **For refinement**: read the existing spec, identify what works and what's ambiguous
- **Use AskUserQuestion** for unclear requirements (in interactive environments)

Don't skip this phase. A vague context file produces a vague spec.

## Context File Template

Write `$WORK_DIR/context.md` with this structure:

```markdown
## Problem Statement
<what problem this spec addresses>

## User Needs / Personas
<who will use this, what they need, key workflows>

## Existing System (if any)
<current state, what works, what doesn't>

## Constraints
<technical, organizational, regulatory, timeline>

## What Already Exists (if refining)
<paste or reference the existing spec>
<note what works and what needs improvement — factual, not evaluative>

## Reference Systems
<similar systems for inspiration or comparison>

## Custom Format (optional)
<if the user has their own spec format, include it here so agents produce
output in that format instead of the default project_spec.json>
```

## Default Criteria

The `"spec"` preset is used automatically when no `--eval-criteria` flag
is provided. It includes 3 must + 1 should + 1 could criteria covering:

- Completeness and unambiguity (each requirement is single and testable)
- Concrete acceptance criteria (specific conditions, inputs, outputs)
- Explicit scope boundaries (in scope and deliberately out of scope)
- Prioritization and consistency (no contradictions, priority reflects importance)
- Edge cases and boundary conditions

Custom criteria via `--eval-criteria` override the preset entirely.

## Output Format

Agents produce structured files in their workspace:

### Primary: `project_spec.json`

Same schema as MassGen's `--spec` mode:

```json
{
  "feature": "Feature Name",
  "overview": "2-3 sentence description of what this feature accomplishes",
  "requirements": [
    {
      "id": "REQ-001",
      "chunk": "C01_core",
      "title": "Short descriptive title",
      "priority": "P0|P1|P2",
      "type": "functional|non-functional",
      "ears": "WHEN <trigger> THE SYSTEM SHALL <response>",
      "rationale": "Why this requirement exists",
      "verification": "How to verify this requirement is met",
      "depends_on": ["REQ-000"]
    }
  ]
}
```

### EARS Notation Reference

Use the **Easy Approach to Requirements Syntax** for each requirement's
`ears` field:

- **Event-driven**: WHEN <trigger> THE SYSTEM SHALL <response>
- **State-driven**: WHILE <state> THE SYSTEM SHALL <behavior>
- **Unwanted behavior**: IF <condition> THEN THE SYSTEM SHALL <response>
- **Optional**: WHERE <feature> THE SYSTEM SHALL <behavior>

Examples:
- WHEN user submits login form THE SYSTEM SHALL validate credentials and return a session token
- WHILE server load exceeds 80% THE SYSTEM SHALL reject new connections with 503 status
- IF database connection fails THEN THE SYSTEM SHALL retry with exponential backoff up to 3 times

### Field Descriptions

- **id**: Unique requirement identifier (REQ-001, REQ-002, etc.)
- **chunk**: Execution phase grouping (C01_core, C02_api, etc.)
- **title**: Short descriptive title for the requirement
- **priority**: P0 (critical), P1 (important), P2 (nice-to-have)
- **type**: "functional" (what it does) or "non-functional" (how well it does it)
- **ears**: EARS-formatted requirement statement
- **rationale**: Why this requirement exists — the "why" behind the "what"
- **verification**: Testable criteria to verify the requirement is met
- **depends_on**: List of requirement IDs this depends on

### Auxiliary (optional)

Organized into purpose-driven subdirectories:

- `research/` — domain analysis, user research, competitive analysis, prior art
- `design/` — system design notes, data models, API contracts, integration points
- `decisions/` — architectural decision records (ADRs), trade-off analyses
- `requirements/` — user stories, acceptance criteria, persona descriptions

Chunks are ordered as a valid DAG (C01_core, C02_api, etc.).

Auxiliary files support the spec but are NOT the spec — `project_spec.json`
is always the source of truth.

**Custom format override**: If the context file specifies a custom spec format,
agents produce that format instead of `project_spec.json`.

## Output Parsing

Read `project_spec.json` from the winner's workspace. The workspace path is
shown in `$WORK_DIR/result.md` (look for "Workspace cwd" or check `status.json`
in the log directory for `workspace_paths`).

Structured EARS requirements keep refinement focused on precision and
completeness rather than prose sprawl.

## Grounding the Spec in Your Task System

**Before you start implementing, enter your native task/plan mode and
create a tracked task for every requirement in `project_spec.json`.**

This is not optional. Without this step, agents implement the obvious
requirements then drift — missing edge cases, skipping non-functional
requirements, or forgetting to verify acceptance criteria.

1. **Enter task planning mode** (e.g., TodoWrite in Claude Code, native
   task tracking in Codex, or your environment's equivalent)
2. **Create two tracked items per requirement**:
   - **Implement**: `REQ-001: <title>` — with the `ears` statement as
     the definition of what to build
   - **Verify**: `VERIFY REQ-001: <verification>` — the acceptance
     criteria that prove the requirement is met
3. **Preserve chunk ordering** — implement C01 requirements before C02
4. **Preserve `depends_on`** — don't start REQ-005 before its
   dependencies are verified
5. **Execute in order**: implement → verify → mark complete, checking
   off each requirement only after its verification criteria pass

The spec on disk (`workspace/spec.json`) is the source of truth for WHAT
to build. Your native task system is the execution tracker for WHERE you
are. Keep both in sync.

## Using the Spec (Lifecycle)

Leverages existing `PlanStorage` infrastructure (`massgen/plan_storage.py`):

### 1. Store

Create a plan directory in `.massgen/plans/plan_<timestamp>/`:

```
.massgen/plans/plan_<timestamp>/
├── workspace/              # Mutable working copy
│   ├── spec.json           # Renamed from project_spec.json
│   ├── research/           # Auxiliary files from MassGen output
│   ├── design/
│   └── decisions/
├── frozen/                 # Immutable snapshot (identical to workspace/ at creation)
│   ├── spec.json
│   ├── research/
│   ├── design/
│   └── decisions/
└── plan_metadata.json      # artifact_type: "spec", status, chunk_order, context_paths
```

Copy `project_spec.json` → `workspace/spec.json`. Copy any auxiliary
directories. Create `frozen/` as an identical snapshot.

### 2. Read on Restart

**FIRST ACTION** in every new session: read `workspace/spec.json`.
This is the canonical definition of what the system should do.

### 3. Stay Anchored

When implementing, trace each piece of work back to a requirement ID.
The spec defines what "done" means.

### 4. Update Continuously

As requirements are implemented, note status in `workspace/spec.json`.
If requirements change, update the spec FIRST — don't just change the code.

### 5. Check Drift

Compare `workspace/spec.json` against `frozen/spec.json`. Drift means the
implementation is diverging from the original intent — evaluate whether
that's intentional.

### 6. Refine When Gaps Appear

If implementation reveals missing requirements or ambiguities, re-invoke
the skill with the workspace spec as "What Already Exists". Creates a
new plan directory with a fresh `frozen/` snapshot.

### 7. Validate Against

Use the spec's `verification` fields as the definition of "done" for each
requirement. Don't consider a requirement complete unless its verification
criteria pass.
