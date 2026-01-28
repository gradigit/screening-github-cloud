# Sandboxed GitHub Screener

Pre-clone security screening for GitHub repos. **Decide if a repo is safe to download before it touches your main system.**

## What This Is

A first-pass screening tool that runs in sandboxed environments:
- **GitHub Codespaces** - Cloud sandbox (nothing touches your machine)
- **Docker / OrbStack** - Local sandbox (isolated container)

Use it to answer: "Should I clone/install this repo?"

**This is NOT a comprehensive security audit.** But it catches the obvious red flags before you expose your system.

## Why Sandboxed?

When evaluating untrusted repos, you face risks:

- **Malicious code** - Scripts that run on clone or install
- **Supply chain attacks** - Typosquatted dependencies
- **Prompt injection** - Malicious content trying to manipulate AI

This skill keeps everything sandboxed. The suspicious repo runs in an isolated environment. Review the screening report *before* the repo touches your main system.

## Setup

### Option 1: GitHub Codespaces (Cloud Sandbox)

**Best for:** Maximum isolation - suspicious code never touches your machine.

```bash
# From your local terminal:

# 1. Create a sandboxed codespace
gh codespace create --repo YOUR-USERNAME/any-repo -m basicLinux32gb

# 2. SSH into it
gh codespace ssh

# 3. Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# 4. Run screening
claude "Screen https://github.com/suspicious/repo for security issues"

# 5. View the report
glow SCREENING-REPORT.md

# 6. When done, exit and delete
exit
gh codespace delete
```

**Cost:** 60 free hours/month on 2-core machine.

### Option 2: Docker / OrbStack (Local Sandbox)

**Best for:** Privacy (no cloud), faster iteration, no hour limits.

```bash
# 1. Create and enter a sandboxed container
docker run -it --rm \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  node:20 bash

# 2. Inside container - install tools
npm install -g @anthropic-ai/claude-code
apt-get update && apt-get install -y git glow

# 3. Run screening
claude "Screen https://github.com/suspicious/repo for security issues"

# 4. View report
glow SCREENING-REPORT.md

# 5. Exit (container auto-deletes due to --rm)
exit
```

**OrbStack users:** Same commands - OrbStack runs Docker containers but faster on Mac.

## What It Checks

| Priority | Category | Examples |
|----------|----------|----------|
| 1 | **Malicious Code** | Postinstall scripts, obfuscation, data exfiltration, backdoors |
| 2 | **Supply Chain** | Typosquatting, slopsquatting, suspicious packages |
| 3 | **GitHub Actions** | Script injection, dangerous triggers, compromised actions |
| 4 | **Secrets** | Exposed credentials (indicates poor hygiene) |
| 5 | **License** | Missing or incompatible |

**Both options also run:** `npm audit`/`pip-audit`, git history search for secrets.

*Updated January 2026 with patterns from [ReversingLabs](https://www.reversinglabs.com/), [GitGuardian](https://www.gitguardian.com/), and [GitHub Security Lab](https://securitylab.github.com/).*

## Verdicts

| Verdict | Meaning |
|---------|---------|
| **SAFE** | No red flags. OK to clone to your main system. |
| **CAUTION** | Yellow flags present. Review findings first. |
| **DANGER** | Red flags detected. Do NOT clone or install. |

## Comparison

| Feature | Codespaces | Docker/OrbStack |
|---------|------------|-----------------|
| Isolation | Cloud (maximum) | Local container |
| Privacy | GitHub sees activity | Fully local |
| Cost | 60 hrs/month free | Free (unlimited) |
| Setup | Easier | Requires Docker |
| Speed | Network latency | Faster |

## File Structure

```
screening-github-cloud/
├── SKILL.md        # Core instructions (for Claude)
├── heuristics.md   # Detection patterns
├── examples.md     # Screening walkthroughs
└── README.md       # This file (for humans)
```

## License

MIT - Use freely, modify, share. No warranty.
