# Cloud GitHub Screener

Pre-clone security screening for GitHub repos. **Decide if a repo is safe to download before it touches your local system.**

## What This Is

A first-pass screening tool that runs in sandboxed cloud environments:
- **GitHub Codespaces** (recommended) - Full screening with local tools
- **Claude.ai web** - Pattern-based screening only

Use it to answer: "Should I clone/install this repo?"

**This is NOT a comprehensive security audit.** But it catches the obvious red flags before you expose your system.

## Why Sandboxed?

When evaluating untrusted repos, you face risks:

- **Malicious code** - Scripts that run on clone or install
- **Supply chain attacks** - Typosquatted dependencies
- **Prompt injection** - Malicious content trying to manipulate AI

This skill keeps everything sandboxed. The suspicious repo runs on GitHub's servers (Codespaces) or is analyzed without cloning (Claude.ai web). Review the screening report *before* the repo touches your machine.

## Setup

### Option 1: GitHub Codespaces (Recommended)

```bash
# From your local terminal:

# 1. Create a sandboxed codespace
gh codespace create --repo YOUR-USERNAME/any-repo -m basicLinux32gb

# 2. SSH into it
gh codespace ssh

# 3. Install Claude Code CLI (if not present)
npm install -g @anthropic-ai/claude-code

# 4. Ask Claude to screen a repo
claude "Screen https://github.com/suspicious/repo for security issues"

# 5. View the report
glow SCREENING-REPORT.md

# 6. When done, exit and delete
exit
gh codespace delete
```

**Advantages:** Can clone the repo, run `npm audit`, check git history - full screening.

### Option 2: Claude.ai Web

1. Fork this repo
2. Connect to a [Claude.ai](https://claude.ai) project
3. Connect the target repo (read-only)
4. Ask: `"Screen [repo-name] for security issues"`

**Limitations:** Cannot run tools or check git history.

## What It Checks

| Priority | Category | Examples |
|----------|----------|----------|
| 1 | **Malicious Code** | Postinstall scripts, obfuscation, data exfiltration, backdoors |
| 2 | **Supply Chain** | Typosquatting, slopsquatting, suspicious packages |
| 3 | **GitHub Actions** | Script injection, dangerous triggers, compromised actions |
| 4 | **Secrets** | Exposed credentials (indicates poor hygiene) |
| 5 | **License** | Missing or incompatible |

**Codespaces bonus:** Also runs `npm audit`/`pip-audit` and searches git history.

*Updated January 2026 with patterns from [ReversingLabs](https://www.reversinglabs.com/), [GitGuardian](https://www.gitguardian.com/), and [GitHub Security Lab](https://securitylab.github.com/).*

## Verdicts

| Verdict | Meaning |
|---------|---------|
| **SAFE** | No red flags. OK to clone locally. |
| **CAUTION** | Yellow flags present. Review findings first. |
| **DANGER** | Red flags detected. Do NOT clone or install. |

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
