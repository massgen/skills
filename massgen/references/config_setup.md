# Config Setup (Headless)

The default setup path is the browser-based WebUI (`--web-quickstart`).
Use this reference for the **headless alternative** — when the agent creates
the config programmatically by discussing options with the user.

## Headless Setup Flow

### 1. Check for existing config

```bash
ls .massgen/config.yaml 2>/dev/null || ls ~/.config/massgen/config.yaml 2>/dev/null
```

If either exists, skip setup — config is ready.

### 2. Discover available backends and models

```bash
uv run massgen --list-backends
```

This is the **single source of truth** for what's available. It prints:
- Backend names and providers
- **Auth column**: required env var per backend (e.g., `ANTHROPIC_API_KEY`)
- **Models**: valid model names per backend
- **Capabilities**: what each backend supports

Do NOT hardcode model names — always read from this output.

### 3. Check which API keys the user has

```bash
env | grep -E "_API_KEY=" | cut -d= -f1
```

Cross-reference with the Auth column from `--list-backends` to determine
which backends are available. Tell the user what's available.

If no relevant keys are set, ask the user to set at least one.

### 4. Discuss with the user

Based on available backends, ask:
- **How many agents?** Default 3. More = more diversity but slower/costlier.
- **Which models?** Mixing providers gives better diversity. Pick from the
  models listed by `--list-backends` for each available backend.
- **Any preferences?** Cheapest, fastest, highest quality, single provider, etc.

### 5. Generate the config

```bash
# Auto-detect (uses available API keys, picks sensible defaults)
uv run massgen --quickstart --headless

# Explicit agents (use model names from --list-backends output)
uv run massgen --quickstart --headless \
  --quickstart-agent backend=<BACKEND>,model=<MODEL> \
  --quickstart-agent backend=<BACKEND>,model=<MODEL> \
  --quickstart-agent backend=<BACKEND>,model=<MODEL>
```

This writes `.massgen/config.yaml`. Repeat `--quickstart-agent` for each
agent. Without explicit agents, auto-detect picks defaults.

### 6. Validate

```bash
uv run massgen --validate .massgen/config.yaml
```

If validation passes, config is ready. Proceed with the task.

## Config Locations

| Location | Precedence |
|----------|-----------|
| `--config <path>` | Explicit override |
| `.massgen/config.yaml` | Project-level default |
| `~/.config/massgen/config.yaml` | Global fallback |
