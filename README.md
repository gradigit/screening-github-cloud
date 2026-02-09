# Sandboxed GitHub Screener

Deep security screening for GitHub repos in disposable sandbox environments. **Clone, scan, execute, observe - then destroy the sandbox.**

This is an [Agent Skill](https://agentskills.io) - a portable set of instructions that any compatible AI coding agent can discover and use. Agent Skills follow an [open standard](https://github.com/agentskills/agentskills) supported by Claude Code, GitHub Copilot, Cursor, OpenAI Codex, Gemini CLI, and others.

## One-Command Screening

The fastest way to screen a repo. One command handles everything: Codespace creation, tool installation, and screening.

```bash
# Download and run
curl -sO https://raw.githubusercontent.com/gradigit/screening-github-cloud/main/screen.sh
chmod +x screen.sh
./screen.sh https://github.com/suspicious/repo
```

**First run:** Creates Codespace, installs tools, opens interactive SSH. You run `claude login` then `claude --dangerously-skip-permissions "screen <url>"`.

**Subsequent runs:** Reuses Codespace, auto-starts screening (no interaction needed).

**Delete after screening:** `./screen.sh https://github.com/suspicious/repo --destroy`

**Force fresh Codespace:** `./screen.sh https://github.com/suspicious/repo --fresh`

See [Reuse vs Destroy](#reuse-vs-destroy-security-tradeoffs) for when to use each mode.

---

## Reuse vs Destroy: Security Tradeoffs

### REUSE (default)

- Codespace **stops** after screening, restarts on next run
- Tools + Claude login persist — fast subsequent screenings
- **Risk:** a malicious repo could leave artifacts that affect the next screening
- **Best for:** routine screenings of repos you expect are probably safe

### DESTROY (`--destroy` flag)

- Codespace **deleted** after screening — nothing persists
- Next run: full reinstall + Claude re-login required
- **Risk:** none — completely fresh environment every time
- **Best for:** high-risk targets you suspect are genuinely malicious

### Recommendation

Use default (reuse) for most screenings. Use `--destroy` when screening repos that look suspicious from the start. Use `--fresh` when you want a clean slate without deleting the old Codespace.

---

## Installation & Usage

This skill runs inside a **disposable sandbox**. Do not install on your local machine.

### GitHub Codespaces (Recommended)

```bash
# 1. Create a fresh Codespace and SSH in
gh codespace create --repo YOUR-USERNAME/any-repo -m basicLinux32gb
gh codespace ssh

# 2. Install Claude Code CLI and alias to skip permissions (sandbox is the protection)
npm install -g @anthropic-ai/claude-code
echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc && source ~/.bashrc

# 3. Install the screening skill
mkdir -p ~/.claude/skills
git clone https://github.com/gradigit/screening-github-cloud ~/.claude/skills/screening-github-cloud

# 4. Login to Claude
claude login

# 5. Screen a repo (the skill handles installing all security tools)
claude "screen https://github.com/owner/repo"

# 6. Review the report
glow reports/

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
echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc && source ~/.bashrc

# 3. Install the screening skill
mkdir -p ~/.claude/skills
git clone https://github.com/gradigit/screening-github-cloud ~/.claude/skills/screening-github-cloud

# 4. Login and screen
claude login
claude "screen https://github.com/owner/repo"

# 5. Review report, then exit (container auto-deletes)
glow reports/
exit
```

### Screening Private Repos

The default Codespace token is scoped to its own repo only. To screen a private repo, re-authenticate with `gh` inside the Codespace:

```bash
# After SSH-ing into the Codespace
unset GITHUB_TOKEN
gh auth login -s repo
```

This gives you a broader token that can access your private repos. Then screen as normal:

```bash
claude --dangerously-skip-permissions "screen https://github.com/owner/private-repo"
```

### Saving Reports to GitHub

Reports are committed to whatever repo the Codespace was created from, so you can browse them on GitHub:

```bash
# The skill automatically saves reports to the Codespace's repo
# under reports/YYYY-MM-DD-owner-repo.md
# Browse them on GitHub in the repo's reports/ directory
```

The skill handles this automatically at the end of screening.

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
| **Tool Scanning** | Run Trivy (CVEs, secrets), Gitleaks, Semgrep (code patterns), actionlint, zizmor |
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
├── screen.sh       # One-command screening launcher
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
