---
name: massgen
description: "Invoke MassGen's multi-agent system. Use when the user wants multiple AI agents on a task: writing, code, review, planning, specs, research, design, or any task where parallel iteration beats working alone."
---

# MassGen Skill

Delegate tasks to your MassGen team.

## Before You Launch

Check that a config exists:

```bash
ls .massgen/config.yaml 2>/dev/null || ls ~/.config/massgen/config.yaml 2>/dev/null
```

If **no config exists**, set one up:
- **Default (browser)**: run `uv run massgen --web-quickstart` — user picks
  models and keys in the browser
- **Headless**: read `references/config_setup.md` — you discover available
  backends via `--list-backends`, check the user's API keys, discuss
  preferences, and generate config with `--quickstart --headless`

If config exists — launch immediately. No need to ask questions first.

## Important: Only Add What's Asked

Do NOT add extra flags unless the user explicitly requests them:
- No `--personas` unless the user asks for diverse approaches
- No `--plan-depth deep` unless the user wants detailed decomposition
- No `--quick` unless the user wants speed over quality

The defaults are good. Let MassGen handle the rest.

## Quick Dispatch

### 1. Detect Mode

| User Intent | CLI Flags |
|-------------|-----------|
| General task (write, build, research, design) | *(default)* |
| Review/critique existing work | `--checklist-criteria-preset evaluation` |
| Plan a feature or project | `--plan` |
| Plan and auto-execute | `--plan-and-execute` |
| Write requirements/spec | `--spec` |
| Execute an existing plan | `--execute-plan <path_or_latest>` |
| Execute against an existing spec | `--execute-spec <path_or_latest>` |

### 2. Write Criteria

**Always write evaluation criteria** tailored to the task. Save to a temp
file and pass via `--eval-criteria`. Aim for 4-7 criteria.

**Required JSON format** — each criterion needs a `text` field and `category`:

```json
[
  {"text": "Aspect: what to look for.", "category": "must"},
  {"text": "Aspect: what to assess.", "category": "should"},
  {"text": "Aspect: bonus quality.", "category": "could"}
]
```

Or wrapped: `{"criteria": [...]}`. See `references/criteria_guide.md` for
full guidance on writing effective criteria.

For evaluate/plan/spec modes, you can use `--checklist-criteria-preset`
instead of writing custom criteria (presets: `evaluation`, `planning`, `spec`,
`persona`, `decomposition`, `prompt`, `analysis`).

### 3. Build Prompt

**General**: User's task with relevant context.

**Evaluate**: What to evaluate. Auto-gather git diff, changed files, test
output. Keep it factual — what was built, not your quality opinion. Let
agents discover issues independently.

**Plan**: Goal + constraints.

**Spec**: Problem statement + user needs + constraints.

### 4. Choose CWD Context

| Scenario | Flag |
|----------|------|
| Task references the codebase | `--cwd-context ro` |
| Agents should write directly to the project | `--cwd-context rw` |
| Isolated task, no codebase needed (default) | *(omit flag)* |

### 5. Run

Always use the wrapper script:

```bash
bash "$SKILL_DIR/scripts/massgen_run.sh" \
  --mode general --cwd-context off \
  --criteria /tmp/massgen_criteria.json \
  "Create an SVG of a butterfly mixed with a panda"
```

The wrapper includes `--web --no-browser` by default. The run starts
immediately — the user can open http://localhost:8000/ anytime to monitor
progress. **Tell the user about this URL.**

Run in the background. MassGen prints these for tracking:
- `LOG_DIR: <path>` — full run data
- `STATUS: <path>/status.json` — live status
- `ANSWER: <path>` — winning agent's answer.txt

Expect 15-45 minutes for multi-round runs.

### 6. Read Results

Read the `ANSWER:` path from the output. The winning agent's workspace is
always in the `workspace/` directory next to `answer.txt`.

Workspace paths in `answer.txt` are best-effort normalized to reference the
adjacent `workspace/` directory. However, always navigate to the `workspace/`
next to `answer.txt` as the ground truth — not paths mentioned in the text.

For **plan** mode, `project_plan.json` is in the workspace.
For **spec** mode, `project_spec.json` is in the workspace.

## Optional Flags (only when requested)

| Flag | Purpose |
|------|---------|
| `--quick` | One-shot, no voting/refinement |
| `--plan-depth <level>` | Decomposition depth: `dynamic` (default), `shallow`, `medium`, `deep` |
| `--plan-thoroughness thorough` | Deeper strategic reasoning (default: `standard`) |
| `--personas <style>` | Agent diversity: `perspective`, `implementation`, `methodology`, or `off` |
| `--cwd-context ro` | Give agents read access to codebase |
| `--cwd-context rw` | Give agents write access to codebase |
| `--web --no-browser` | Enable WebUI for watching progress (on by default in wrapper) |

## Config

MassGen auto-discovers config from `.massgen/config.yaml` or
`~/.config/massgen/config.yaml`. See setup instructions above.

## References

Only consult when the quick dispatch isn't enough:

| File | When |
|------|------|
| `references/criteria_guide.md` | Criteria format, tiers, examples |
| `references/config_setup.md` | Headless config creation |
| `references/advanced_workflows.md` | Checkpoint loops, living documents, structured eval, plan-evaluate integration |
