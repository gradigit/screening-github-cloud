# Sandboxed GitHub Screener

Deep security screening for GitHub repos in disposable sandbox environments. **Clone, scan, execute, observe - then destroy the sandbox.**

## What This Is

A comprehensive screening tool that runs in fresh, disposable environments:
- **GitHub Codespaces** - Cloud VM (nothing touches your machine)
- **Docker / OrbStack** - Local container (isolated, fast)

Use it to answer: "Is this repo safe to clone and install?"

## Why Sandboxed?

Traditional security scanning is static - it reads files but can't see what code actually *does*. This tool uses disposable sandboxes to:

- **Execute install scripts** - See what `npm install` actually runs
- **Monitor behavior** - Watch for suspicious network calls, file access
- **Run security tools** - Trivy, Gitleaks, actionlint, zizmor
- **Observe in safety** - Malicious code runs in an isolated, disposable environment

**After screening, you destroy the sandbox.** Nothing persists.

## Quick Start

### Option 1: GitHub Codespaces (Cloud)

```bash
# 1. Create fresh codespace and SSH in
gh codespace create --repo YOUR-USERNAME/any-repo -m basicLinux32gb
gh codespace ssh

# 2. Install Claude Code
npm install -g @anthropic-ai/claude-code
sudo apt-get update && sudo apt-get install -y glow

# 3. Screen a repo
claude login
claude "Screen https://github.com/suspicious/repo"

# 4. View report, then destroy
glow SCREENING-REPORT.md
exit
gh codespace delete
```

### Option 2: Docker / OrbStack (Local)

```bash
# 1. Create fresh container
docker run -it --rm node:20 bash

# 2. Install tools and screen
npm install -g @anthropic-ai/claude-code
apt-get update && apt-get install -y git glow
claude login
claude "Screen https://github.com/suspicious/repo"

# 3. View report, then exit (container auto-deletes)
glow SCREENING-REPORT.md
exit
```

## What It Does

| Phase | Actions |
|-------|---------|
| **Static Analysis** | Scan for malicious patterns, secrets, obfuscation |
| **Tool Scanning** | Run Trivy (CVEs, secrets), Gitleaks, actionlint, zizmor |
| **Dynamic Analysis** | Execute `npm install`, observe behavior |
| **Dependency Audit** | Run `npm audit` / `pip-audit` |

### Security Tools Used

| Tool | Purpose |
|------|---------|
| **Trivy** | CVEs, secrets, misconfigs, licenses |
| **Gitleaks** | Fast secret scanning with git history |
| **actionlint** | GitHub Actions syntax/compatibility |
| **zizmor** | GitHub Actions security vulnerabilities |

## Verdicts

| Verdict | Meaning |
|---------|---------|
| **SAFE** | No red flags. OK to clone to your main system. |
| **CAUTION** | Yellow flags present. Review findings first. |
| **DANGER** | Red flags detected. Do NOT clone or install. |

## Risk Model

**The sandbox is the protection.** You're running in a fresh, disposable environment with nothing valuable:

| Asset | In Sandbox? | Risk |
|-------|-------------|------|
| Personal files | No | None |
| SSH keys | No | None |
| Browser cookies | No | None |
| Claude session | Yes | Minimal* |

*Claude Max = unlimited usage, fixed price. Token can be revoked with `claude logout`. Worst case: attacker gets temporary API access to a service you're not charged per-use for.

## Comparison

| Feature | Codespaces | Docker/OrbStack |
|---------|------------|-----------------|
| Isolation | Cloud VM | Local container |
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

## Best Practices

1. **Always use fresh sandbox** - Don't reuse between screenings
2. **Destroy after use** - `gh codespace delete` or `exit` with `--rm`
3. **Review the report** - Understand what was found before cloning
4. **Run `claude logout`** - Invalidate session token after screening

## License

MIT - Use freely, modify, share. No warranty.

---

*Updated January 2026. Uses patterns from [ReversingLabs](https://www.reversinglabs.com/), [GitGuardian](https://www.gitguardian.com/), [Aqua Trivy](https://trivy.dev/), and [GitHub Security Lab](https://securitylab.github.com/).*
