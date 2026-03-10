# Quality Criteria Writing Guide

How to write effective quality criteria for MassGen's checklist-gated voting system.
This guide applies to all modes (evaluate, plan, spec). Criteria express what you
value — the quality dimensions that matter for the deliverable being produced.

## Format

JSON array of objects:

```json
[
  {"text": "[Aspect name]: [concrete things to look for].", "category": "must"},
  {"text": "[Aspect name]: [what to assess].", "category": "should", "verify_by": "render output and inspect for [specific defects]"},
  {"text": "[Aspect name]: [what to look for].", "category": "could"}
]
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `text` | string | Yes | The criterion — names a quality axis and lists what to look for |
| `category` | string | Yes | `must` / `should` / `could` |
| `verify_by` | string | No | How to gather evidence when reading source alone is insufficient |

## Tier System

- **`must`** — Hard requirements. Failing these means the answer is **wrong** — across
  all dimensions of correctness (structural, content, and experiential). A first-year
  professional in the domain would not ship output that fails this.
  Example: "Output is a working 30-second video, not a still image or broken render"

- **`should`** — Quality dimensions where the output must demonstrate **deliberate,
  thoughtful execution** — not just functional completeness. A SHOULD criterion asks
  "did the creator make intentional choices here, or just do the obvious thing?"
  Functional baselines ("has mobile support", "images load") belong in MUST if they're
  requirements, not SHOULD. SHOULD criteria target the quality of execution: how well
  something is done, not whether it exists.
  Example: "Typography creates clear visual hierarchy with intentional size, weight,
  and spacing choices — not just default browser styles"

- **`could`** — Creative ambition and distinctive quality that makes the output
  memorable. COULD criteria ask "does this show a point of view?" — not just competent
  execution but something a viewer would specifically remember or comment on.
  Example: "The site has a distinctive interactive moment that reinforces the brand
  identity — not a generic animation library demo but something designed for this
  specific product"

**Calibration test**: First ask whether this is a correctness criterion — does failing
it mean the output is *wrong* (broken, inaccurate, or misbehaving in its actual
environment)? If yes → MUST. Only after ruling that out: is this about the *quality of
execution* — how thoughtfully something is done? → SHOULD. Is this about *distinctive
creative ambition*? → COULD. If a criterion can be satisfied by a simple checkbox
action (add X, include Y, support Z) → MUST, not SHOULD.

## What Correctness Means

Correctness is not just "the file exists and opens." A correct output is one that works
as the user actually experiences it:

- **Structural correctness**: the output has the right form and can be used at all
  (file opens, code runs, API responds)
- **Content correctness**: the output says or computes the right things — accurate,
  complete, no factual errors or wrong results
- **Experiential correctness**: the output behaves correctly in its primary use
  environment — text renders without overflow, visuals display as intended,
  interactions work, audio/video plays back properly

An output that passes structural checks but fails experiential ones is a *wrong* output,
not a mediocre one.

## Writing Good Criteria

1. **Be task-specific.** Each criterion must be specific to THIS task, not generic.
2. **Name a quality axis, then list what to look for.** Don't prescribe implementation.
3. **Make criteria scoreable** — an evaluator should be able to rate it on a 1-10 scale.
4. **Aim for 4-7 criteria.** At least 3 must be "must" or "should". 1-3 may be "could".
5. **Cover distinct dimensions.** Don't cluster criteria around the same aspect. Think
   about the major independent quality axes (correctness, completeness, error handling,
   usability, craft) and ensure each gets at least one criterion.
6. **Include a craft criterion (should).** One criterion MUST assess whether the output
   shows intentional, cohesive choices. Without this, agents produce correct but
   forgettable output.
7. **For rendered/experienced artifacts** (websites, slides, video, audio, interactive
   apps): include a dedicated `must` criterion whose sole focus is rendering/playback
   correctness — no defects when opened and experienced normally. Don't merge this
   into a craft criterion.
8. **Per-part quality.** When the output has multiple distinct parts, include at least
   one criterion that assesses whether EACH part independently meets a quality bar.
   Whole-output criteria allow one strong area to mask mediocrity elsewhere.

## The `verify_by` Field

Required whenever the criterion involves experiential correctness or craft that cannot
be assessed by reading the source alone. Describe WHAT EVIDENCE to gather and WHAT TO
CHECK — not which specific application or GUI to use.

State the full scope (all pages, all slides, full playback — not a sample) and list
the specific defects or properties to look for.

| Output type | verify_by guidance |
|---|---|
| Rendered (slides, pages, images) | Render ALL pages/slides to images and inspect each for specific defects (text overflow, clipped elements, unreadable fonts, blank content areas) |
| Interactive (web apps, forms) | Test all navigation links, form submissions, button actions, and interactive state changes — list what each interaction should do |
| Motion/animation | Capture and review full animation playback — list expected motion behavior and timing |
| Audio/video | Listen to or watch the complete output — list what to assess (clarity, pacing, content accuracy) |
| Executable code | Run with representative inputs and check outputs against expected results |

Do NOT name specific desktop applications ("open in PowerPoint"). Do NOT describe
GUI-specific actions ("hover to see cursor change"). Instead describe the observable
property to verify.

Omit `verify_by` only when the criterion can be fully assessed by reading the output
text or inspecting the source file structure.

## Default Presets

MassGen includes built-in criteria presets that are applied automatically when no
`--eval-criteria` flag is provided. These presets live in `evaluation_criteria_generator.py`.

### `"planning"` preset (5 must + 3 should)

1. **Scope capture** (must): captures the user's requested outcome and constraints without scope drift
2. **Task graph validity** (must): executable and internally consistent — dependencies valid, ordering coherent
3. **Actionability** (must): tasks describe WHAT to produce AND HOW — method, key decisions, constraints. Each task actionable without inferring direction
4. **Verification guidance** (must): each task has verification matched to its type (deterministic or qualitative, NOT forced numeric thresholds on qualitative work)
5. **Technology choices** (must): frameworks, libraries, tools named and justified — not left for the executor to guess
6. **Interface contracts** (should): where tasks connect, data shapes/file conventions/API signatures specified
7. **Assumptions documented** (should): boundaries and trade-offs documented with rationale, ambiguities resolved with explicit defaults
8. **Sequencing and risk** (should): thoughtful chunking and prioritization, high-risk tasks first, quality gates placed for maximum impact

### `"spec"` preset (3 must + 1 should + 1 could)

1. **Completeness and unambiguity** (must): each requirement describes a single, testable behavior — implementable without guessing intent
2. **Acceptance criteria** (must): specific conditions, inputs, expected outputs, or observable behaviors that prove the requirement is met
3. **Scope boundaries** (must): what is in scope and what is deliberately out of scope are both stated
4. **Prioritization and consistency** (should): no contradictions, priority reflects dependencies and importance
5. **Edge cases** (could): anticipates error states, boundary conditions relevant to the domain

### `"evaluation"` preset

Generated dynamically per task by MassGen's criteria generation subagent. Used when
no `--eval-criteria` flag is provided in evaluate mode.

### When to Use Presets vs Custom Criteria

**Use the preset when:**
- General-purpose evaluation, planning, or spec writing
- No domain-specific quality concerns beyond the preset dimensions
- You want to get started quickly without writing criteria

**Write custom criteria when:**
- Domain-specific quality axes matter (e.g., security focus, visual design quality)
- The user specified particular concerns or focus areas
- You're refining an existing plan/spec with known gaps
- The preset dimensions don't cover what matters most for this task

Custom criteria via `--eval-criteria` always override the default preset.

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| "Visual design quality." (abstract) | "Visual design: typography is legible at mobile resolution (16px+ body text, sufficient contrast), layout has clear visual hierarchy, color palette is consistent across all pages." |
| "Code quality." (abstract) | "Code quality: functions have single responsibility, error paths are handled (no swallowed exceptions), public API has type annotations." |
| Prescriptive requirements ("at least 4 pages covering X, Y, Z") | Evaluation dimensions ("Breadth and depth of topic coverage: all major aspects are addressed with meaningful depth") |
| Implementation plans ("Each member featured with birth year, role") | Quality axes ("Individual member coverage: each member has accurate biographical detail, distinct contributions") |
| Whole-output only ("shows intentional design") | Per-part ("Per-section quality: each significant section independently demonstrates craft — evaluate the weakest section, not the average") |
| All criteria check structural validity only | Cover all dimensions: what it says/computes, how it behaves when used, and whether it shows intentional craft |
| 12 criteria covering everything | 5-7 criteria covering what matters most |
| All same category | Mix of must (2-3), should (2-3), could (0-2) |

## Example: API Client Library

```json
[
  {
    "text": "API coverage: all documented endpoints have working method signatures with correct parameters.",
    "category": "must"
  },
  {
    "text": "Error handling: client is resilient to network failures, rate limits, and malformed responses.",
    "category": "must"
  },
  {
    "text": "Developer ergonomics: naming is clear, the public API is discoverable, and usage is self-evident.",
    "category": "should"
  },
  {
    "text": "Test coverage: each endpoint method has at least one happy-path and one error-path test.",
    "category": "should"
  },
  {
    "text": "Documentation quality: README has quickstart example that works copy-paste, plus method-level docstrings.",
    "category": "could"
  }
]
```

## Example: SVG Illustration

```json
[
  {
    "text": "Subject accuracy: pelican's beak shape, throat pouch, and plumage detail are recognizable and anatomically correct.",
    "category": "must"
  },
  {
    "text": "Bicycle accuracy: wheels, frame, handlebars, and pedals are all present and structurally plausible.",
    "category": "must"
  },
  {
    "text": "Convincingness of the riding pose: pelican's body position, grip, and balance look physically coherent on the bicycle.",
    "category": "should"
  },
  {
    "text": "Visual appeal: scenery, color palette, and composition make the image engaging beyond just accurate.",
    "category": "should",
    "verify_by": "Render SVG to PNG and inspect full image for visual coherence, color balance, and compositional appeal."
  },
  {
    "text": "Rendering correctness: SVG opens without errors, all elements visible, no clipped paths or overlapping artifacts.",
    "category": "must",
    "verify_by": "Render SVG to PNG at default viewport and inspect for any rendering defects, missing elements, or blank areas."
  }
]
```
