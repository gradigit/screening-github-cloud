# Sandboxed GitHub Screener

Deep security screening for GitHub repos in disposable sandbox environments. **Clone, scan, execute, observe - then destroy the sandbox.**

This is an [Agent Skill](https://agentskills.io) - a portable set of instructions that any compatible AI coding agent can discover and use. Agent Skills follow an [open standard](https://github.com/agentskills/agentskills) supported by Claude Code, GitHub Copilot, Cursor, OpenAI Codex, Gemini CLI, and others.

## Installation & Usage

This skill runs inside a **disposable sandbox**. Do not install on your local machine.

### GitHub Codespaces (Recommended)

```bash
# 1. Create a fresh Codespace and SSH in
gh codespace create --repo YOUR-USERNAME/any-repo -m basicLinux32gb
gh codespace ssh

# 2. Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# 3. Install the screening skill
mkdir -p ~/.claude/skills
git clone https://github.com/gradigit/screening-github-cloud ~/.claude/skills/screening-github-cloud

# 4. Login to Claude
claude login

# 5. Screen a repo (the skill handles installing all security tools)
claude --dangerously-skip-permissions "screen https://github.com/owner/repo"

# 6. Review the report
glow SCREENING-REPORT.md

# 7. Exit and destroy
exit
gh codespace delete
```

### Docker / OrbStack

```bash
# 1. Create a fresh container
docker run -it --rm node:20 bash

# 2. Install Claude Code CLI and git
npm install -g @anthropic-ai/claude-code
apt-get update && apt-get install -y git

# 3. Install the screening skill
mkdir -p ~/.claude/skills
git clone https://github.com/gradigit/screening-github-cloud ~/.claude/skills/screening-github-cloud

# 4. Login and screen
claude login
claude --dangerously-skip-permissions "screen https://github.com/owner/repo"

# 5. Review report, then exit (container auto-deletes)
glow SCREENING-REPORT.md
exit
```

### Other Compatible Agents

Any agent that supports the [Agent Skills open standard](https://agentskills.io/specification) can use this skill. Clone the repo into the agent's skill discovery path.

### Trigger Phrases

The skill activates when you say things like:
- "screen this repo"
- "is this repo safe"
- "check before cloning"
- "should I clone this"
- "security screening"

## What It Does

The skill handles everything after installation, including installing security tools (Trivy, Gitleaks, actionlint, zizmor) and running the full screening workflow:

| Phase | Actions |
|-------|---------|
| **Static Analysis** | Scan for malicious patterns, secrets, obfuscation |
| **Tool Scanning** | Run Trivy (CVEs, secrets), Gitleaks, actionlint, zizmor |
| **Dynamic Analysis** | Execute `npm install`, observe behavior |
| **Dependency Audit** | Run `npm audit` / `pip-audit` |
| **Deep Dependency Investigation** | Install and inspect suspicious dependencies in isolation |

## Verdicts

| Verdict | Meaning |
|---------|---------|
| **SAFE** | No red flags. OK to clone to your main system. |
| **CAUTION** | Yellow flags present. Review findings first. |
| **DANGER** | Red flags detected. Do NOT clone or install. |

## Philosophy

**The sandbox is the protection, not network isolation.**

The skill runs in a fresh, disposable environment with nothing valuable. It can execute install scripts, observe runtime behavior, and do real dynamic analysis. After screening, the sandbox is destroyed.

## File Structure

```
screening-github-cloud/
├── SKILL.md        # Core skill instructions (for agents)
├── heuristics.md   # Detection patterns
├── examples.md     # Screening walkthroughs
├── CHANGELOG.md    # Version history
├── LICENSE         # MIT license
└── README.md       # This file (for humans)
```

## License

MIT - Use freely, modify, share. No warranty.

---

*Built following the [Agent Skills open standard](https://agentskills.io). Updated January 2026.*
