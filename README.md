# Cloud GitHub Screener

Pre-clone security screening for GitHub repos. **Decide if a repo is safe to download before it touches your system.**

## What This Is

A first-pass screening tool that runs entirely in Claude's cloud environment. Use it to answer: "Should I clone/install this repo?"

**This is NOT a comprehensive security audit.** After screening, you should still run local tools (`npm audit`, etc.) and review code yourself.

## Why Cloud-Only?

When evaluating untrusted repos, you face risks:

- **Malicious code** - Scripts that run on clone or install
- **Supply chain attacks** - Typosquatted dependencies
- **Prompt injection** - Malicious content trying to manipulate AI

This skill keeps everything sandboxed. Review the screening report *before* the repo touches your machine.

## Setup

1. **Fork** this repo to your GitHub account
2. **Connect** your fork to a [Claude.ai](https://claude.ai) project
3. **Connect** the target repo to screen (read-only is fine)
4. **Ask Claude**: `"Screen [repo-name] for security issues"`

## What It Checks

| Priority | Category | Examples |
|----------|----------|----------|
| 1 | **Malicious Code** | Postinstall scripts, obfuscation, data exfiltration, backdoors |
| 2 | **Supply Chain** | Typosquatting, slopsquatting, suspicious packages |
| 3 | **GitHub Actions** | Script injection, dangerous triggers, compromised actions |
| 4 | **Secrets** | Exposed credentials (indicates poor hygiene) |
| 5 | **License** | Missing or incompatible |

*Updated January 2026 with patterns from [ReversingLabs](https://www.reversinglabs.com/), [GitGuardian](https://www.gitguardian.com/), and [GitHub Security Lab](https://securitylab.github.com/).*

## Verdicts

| Verdict | Meaning |
|---------|---------|
| **SAFE** | No red flags. OK to clone, then run local tools. |
| **CAUTION** | Yellow flags present. Review before cloning. |
| **DANGER** | Red flags detected. Do NOT clone or install. |

## Limitations

Cloud screening cannot:
- Execute code to test runtime behavior
- Check git history for removed secrets
- Run `npm audit`, `pip-audit`, `cargo audit`

These require local execution *after* you decide to clone.

## File Structure

```
screening-github-cloud/
├── SKILL.md        # Core instructions
├── heuristics.md   # Detection patterns
├── examples.md     # Screening walkthroughs
└── README.md       # This file
```

## License

MIT - Use freely, modify, share. No warranty.
