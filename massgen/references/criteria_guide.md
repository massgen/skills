# Quality Criteria Writing Guide

How to write effective quality criteria for MassGen's checklist-gated voting system.
Criteria are not just scoring rubrics — they shape what agents produce. Opinionated
criteria with anti-patterns and aspiration levels drive quality leaps; generic
dimension labels produce generic work.

Reference: https://www.anthropic.com/engineering/harness-design-long-running-apps

## Format

JSON object with aspiration and criteria array:

```json
{
  "aspiration": "A site a designer would screenshot for their portfolio",
  "criteria": [
    {
      "text": "Design coherence: Does the design feel authored or assembled? ...",
      "category": "primary",
      "anti_patterns": ["unmodified library defaults", "purple-gradient AI aesthetics"],
      "verify_by": "render full page and evaluate visual system top to bottom"
    },
    {
      "text": "Content depth: Every section teaches something specific ...",
      "category": "standard",
      "anti_patterns": ["Wikipedia-summary prose", "sections that exist for structure only"]
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `aspiration` | string | Yes | 1-2 phrase quality ceiling — what would make this remarkably good? |
| `text` | string | Yes | Opinionated quality definition — takes a position, not just a dimension |
| `category` | string | Yes | `primary` / `standard` / `stretch` |
| `anti_patterns` | list[str] | Yes | 2-4 specific failure modes that tank this score |
| `verify_by` | string | No | How to gather evidence when reading source alone is insufficient |

## Category System

- **`primary`** — THE criterion where default model behavior is weakest and improvement
  matters most. At most one per set. For creative tasks, usually originality or voice.
  For technical tasks, architecture or error handling. For design, visual distinctiveness.
  This is where you push hardest.

- **`standard`** — Must-pass criteria. Failing these means the answer has real problems.
  Covers correctness (structural, content, experiential), completeness, and baseline craft.

- **`stretch`** — Nice-to-have quality differentiators. Creative ambition, distinctive
  moments, polish beyond what's required.

**Key principle**: Models already produce structurally correct, functional output by
default. Criteria that only check for correctness or completeness will pass on the
first draft and add no iterative value. The PRIMARY criterion should target a dimension
where default model output is predictably mediocre.

## What Makes Criteria Opinionated

A good criterion does three things:

### 1. Takes a position on what "good" means

BAD (dimension label): "Uses vivid imagery."
GOOD (quality definition): "Uses imagery that surprises — that makes the reader see
something they have seen before in a way they have not. Stock metaphors (heart = love,
darkness = sadness) or AI-typical purple-prose descriptors score poorly."

BAD: "Visual design quality."
GOOD: "Design coherence: Does the design feel like it was authored by someone with a
point of view, or assembled from components? Evidence of custom decisions — intentional
spacing rhythms, a color system that creates mood, typography choices that reinforce
hierarchy — scores highly. Unmodified component library defaults score poorly."

### 2. Names specific anti-patterns

Not abstract badness — the specific ways THIS task type typically goes wrong:

| Domain | Anti-pattern examples |
|--------|---------------------|
| Code | god functions, swallowed exceptions, any-typed escape hatches |
| Writing | topic-sentence-then-three-examples structure, hedging qualifiers |
| Design | unmodified library defaults, centered-everything layouts, purple gradients |
| Data | cherry-picked examples, conclusions stated before evidence examined |

### 3. Marks one criterion PRIMARY

The dimension where the model needs the most push. Not the most important dimension
overall — the one where default output is weakest.

## What Correctness Means

Correctness covers three dimensions:

- **Structural**: right form, can be used (file opens, code runs)
- **Content**: says/computes right things (accurate, complete)
- **Experiential**: behaves correctly in primary use environment (renders properly,
  interactions work, no visual defects)

Correctness is separate from craft. A correct output can still be mediocre.

## The `verify_by` Field

Required whenever the criterion involves experiential correctness or craft that cannot
be assessed by reading the source alone.

| Output type | verify_by guidance |
|---|---|
| Rendered (slides, pages, images) | Render ALL pages to images, inspect for text overflow, clipped elements, blank areas |
| Interactive (web apps, forms) | Test all navigation, form submissions, button actions, state changes |
| Motion/animation | Capture and review full playback — list expected motion behavior |
| Audio/video | Listen to/watch complete output — assess clarity, pacing, accuracy |
| Executable code | Run with representative inputs, check outputs against expected results |

Do NOT name specific desktop applications. Describe the observable property to verify.

## Examples

### Website about gophers

```json
{
  "aspiration": "A site a nature blogger would bookmark and share",
  "criteria": [
    {
      "text": "Content depth within brevity: Every section teaches something specific about gophers — tunnel architecture, cheek pouch mechanics, ecosystem impact — not generic animal-encyclopedia filler.",
      "category": "standard",
      "anti_patterns": [
        "Wikipedia-summary prose that conveys no specific knowledge",
        "Sections that exist for structure but contain no memorable facts",
        "Content that could apply to any burrowing mammal with 'gopher' swapped in"
      ]
    },
    {
      "text": "Design coherence: The visual language reinforces the subject matter. Color palette, typography, and spacing feel intentional — not just functional.",
      "category": "primary",
      "anti_patterns": [
        "White-card-on-light-gray layouts with no visual identity",
        "Default system fonts with no hierarchy",
        "Hero section carries the design while lower sections revert to template-tier"
      ],
      "verify_by": "render full page to images, evaluate whether the visual system feels cohesive top to bottom"
    },
    {
      "text": "Rendering and interaction correctness: Navigation lands on the right section, interactive elements respond, layout holds at mobile and desktop widths.",
      "category": "standard",
      "anti_patterns": [
        "Anchor links that don't scroll correctly",
        "Buttons that do nothing on click",
        "Content that overflows at mobile width"
      ],
      "verify_by": "serve locally, click every nav link and interactive element, capture screenshots at 1440px and 390px"
    },
    {
      "text": "Scope discipline: The site feels intentionally short — a deliberate editorial choice, not a truncated longer site.",
      "category": "standard",
      "anti_patterns": [
        "7+ sections that read like a long-form article broken into cards",
        "Content that repeats the same facts in different sections"
      ]
    }
  ]
}
```

### Love poem

```json
{
  "aspiration": "A poem a literary journal editor would pause on",
  "criteria": [
    {
      "text": "Earned emotion: The poem makes the reader feel something through specific imagery and situation, not through stating feelings. Every emotional beat grounded in something concrete.",
      "category": "primary",
      "anti_patterns": [
        "Abstract declarations of feeling ('my heart aches')",
        "Greeting-card resolution that wraps up neatly",
        "Emotional escalation without corresponding specificity"
      ]
    },
    {
      "text": "Surprise and originality: At least one moment the reader could not have predicted — an image, turn, or juxtaposition that reframes what came before.",
      "category": "standard",
      "anti_patterns": [
        "Heart/fire/ocean/stars as primary metaphors for love",
        "List-of-beautiful-things structure",
        "Ending that restates the opening sentiment"
      ]
    },
    {
      "text": "Sound and music: The poem rewards being read aloud — attention to consonants, vowels, rhythm in service of meaning.",
      "category": "standard",
      "anti_patterns": [
        "Lines that scan as prose with arbitrary break points",
        "No audible pattern of any kind",
        "Forced end-rhyme that distorts natural phrasing"
      ]
    },
    {
      "text": "Memorable line: At least one line a reader would remember hours later and might quote.",
      "category": "standard",
      "anti_patterns": [
        "Every line at the same intensity — no peaks",
        "Lines memorable only for being clever, not for being true"
      ]
    }
  ]
}
```

## When to Use Presets vs Custom Criteria

**Use presets when:**
- General-purpose evaluation, planning, or spec writing
- `--checklist-criteria-preset evaluation|planning|spec|persona|decomposition`

**Write custom criteria when:**
- Domain-specific quality axes matter
- The user specified particular concerns or focus areas
- You know which dimension the model will be weakest on

Custom criteria via `--eval-criteria` always override presets.

**Use auto-generation when:**
- `evaluation_criteria_generator.enabled: true` in config
- MassGen spawns a pre-collaboration subagent to generate task-specific criteria
- Best for tasks where you want opinionated criteria but don't want to write them manually
