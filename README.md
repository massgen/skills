# 🧠 massgen/skills

[MassGen](https://github.com/massgen/massgen) is a multi-agent system that coordinates multiple AI agents to solve complex tasks through parallel processing, iterative refinement, and consensus voting.

These are the official **Agent Skills** for MassGen — install them to invoke MassGen directly from your AI coding agent. Built on the open [Agent Skills](https://agentskills.io/home) standard. Write once, use everywhere.

📖 [Documentation](https://docs.massgen.ai/en/latest/user_guide/skills.html) · 🚀 [MassGen](https://github.com/massgen/massgen) · 💬 [Discord](https://discord.massgen.ai)

---

## ⚡ Install

```bash
npx skills add massgen/skills --all
```

That's it. Works with Claude Code, Cursor, Codex, Windsurf, GitHub Copilot, Gemini CLI, Goose, Amp, and [40+ other agents](https://skills.sh).

To install to a specific agent only:

```bash
npx skills add massgen/skills -a claude-code
npx skills add massgen/skills -a codex
npx skills add massgen/skills -a cursor
npx skills add massgen/skills -a copilot
npx skills add massgen/skills -a gemini-cli
npx skills add massgen/skills -a windsurf
```

See [Vercel's skills docs](https://vercel.com/docs/agent-resources/skills) for more on the `npx skills` CLI.

<details>
<summary>Manual install (any agent)</summary>

```bash
git clone https://github.com/massgen/skills.git /tmp/massgen-skills
cp -r /tmp/massgen-skills/massgen ~/.claude/skills/massgen   # or ~/.codex/skills/, ~/.agents/skills/, etc.
```

</details>

---

## 📋 What's Included

The **MassGen skill** gives your agent four modes:

| Mode | Purpose | Output |
|------|---------|--------|
| 🎯 **General** (default) | Any task — writing, code, research, design | Winner's deliverables + workspace files |
| 🔍 **Evaluate** | Critique existing work | `critique_packet.md`, `verdict.json`, `next_tasks.json` |
| 📐 **Plan** | Create structured project plans | `project_plan.json` with task DAG |
| 📝 **Spec** | Create requirements specifications | `project_spec.json` with EARS requirements |

---

## ⚠️ Prerequisites

1. **MassGen installed**: `pip install massgen`
2. **AI provider authenticated**: API key (e.g., `OPENAI_API_KEY`) or login-based auth (e.g., `claude` or `codex` login)
3. **Config file**: Run `massgen --quickstart` to create `.massgen/config.yaml`

> **Note:** MassGen setup requires human input for API key configuration and provider selection. Ensure your environment is set up before the skill is invoked.

---

## 🔄 Updating

```bash
npx skills update
```

This repo is automatically synced from the main [MassGen repository](https://github.com/massgen/massgen) on every merge to `main`.

---

## 📄 License

Apache 2.0 — see [LICENSE](LICENSE) for details.
