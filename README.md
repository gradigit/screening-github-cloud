# Cloud GitHub Auditor

Audit GitHub repositories for security vulnerabilities **entirely in the cloud** - no files ever touch your local machine.

## Why Cloud-Only?

When auditing untrusted repositories, you face risks:

- **Prompt injection** - Malicious README/comments trying to manipulate AI
- **Malicious code** - Scripts that run on clone or install
- **Supply chain attacks** - Typosquatted dependencies

This skill keeps everything sandboxed in Claude's web environment. Review the audit report *before* deciding whether to clone locally.

## Setup

1. **Fork or clone** this repo to your GitHub account
2. **Connect** your copy to a [Claude.ai](https://claude.ai) project
3. **Connect** the target repo you want to audit (read-only access is fine)
4. **Ask Claude**: `"Using auditing-github-cloud, audit [repo-name]"`

## What It Checks

| Category | Examples |
|----------|----------|
| **Secrets** | AWS, GitHub, OpenAI, Anthropic, Slack, GitLab, npm, PyPI tokens + generic high-entropy |
| **Malicious Code** | Obfuscation, data exfiltration, backdoors, reverse shells |
| **Supply Chain** | Typosquatting, slopsquatting (AI-hallucinated packages), suspicious packages |
| **GitHub Actions** | Script injection, dangerous triggers, unpinned actions, known compromised actions (CVE-2025-30066) |
| **Injection Vulns** | SQL, command, XSS, path traversal |
| **Prompt Injection** | Attempts to manipulate the audit itself |
| **License** | Missing, incompatible, or viral licenses |

*Updated January 2026 with latest threat patterns from [ReversingLabs](https://www.reversinglabs.com/), [GitGuardian](https://www.gitguardian.com/), and [GitHub Security Lab](https://securitylab.github.com/).*

## Output

Creates a GitHub issue with:

- **Verdict**: SAFE / CAUTION / DANGER
- **Risk Score**: 0-100
- **Findings**: Categorized by severity (Critical → Low)
- **Recommendations**: Prioritized action items

## Limitations

Cloud-only audits cannot:

- Execute code to test runtime behavior
- Check git history for removed secrets
- Verify if exposed secrets are still active
- Run `npm audit`, `pip-audit`, or similar tools

For deep analysis, use this as a first pass, then clone locally if the verdict is SAFE or CAUTION.

## File Structure

```
auditing-github-cloud/
├── SKILL.md        # Core instructions (loaded on activation)
├── heuristics.md   # Detection patterns (loaded on demand)
├── examples.md     # Audit walkthroughs (loaded on demand)
└── README.md       # This file (for humans)
```

## License

MIT - Use freely, modify, share. No warranty.

See [LICENSE](LICENSE) for full text.
