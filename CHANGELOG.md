# Changelog

All notable changes to this skill are documented here.

## [5.2.0] - 2026-02-09

### Added
- **Semgrep** static analysis as 5th scanning tool
  - Detects injection vulnerabilities, eval/exec misuse, hardcoded secrets in code context
  - Uses `p/security-audit` and `p/owasp-top-ten` rulesets
  - `--no-git-ignore` flag ensures gitignored files are scanned (malicious code can hide there)
  - Fills gap between Trivy (dependency CVEs) and manual grep (simple patterns)
- Semgrep install, run commands, and output parsing guidance
- Semgrep section in report template and all examples
- Semgrep severity mapping (ERROR → HIGH-CRITICAL, WARNING → MEDIUM, INFO → LOW)
- `workflow_run` checkout vulnerability pattern in heuristics.md (CWE-913, from Semgrep code-security rules)
- Semgrep fallback patterns for when tool is unavailable

### Changed
- Workflow step 5 now includes Semgrep alongside Trivy and Gitleaks
- Tool Versions table includes Semgrep 1.x
- All example and template version references updated to v5.2.0
- Version bump to 5.2.0

## [5.1.0] - 2026-02-07

### Added
- Explicit step 14 in workflow: output full GitHub report URL as final screening output
- CRITICAL instruction: report URL must be bare (no backticks, quotes, or markdown) and on its own line for Cmd+click support in terminals like Ghostty

### Changed
- Workflow now has 15 steps (was 14)
- "Saving Reports" section expanded with formatting requirements for clickable URLs
- Version bump to 5.1.0

## [5.0.0] - 2026-01-31

### Added
- **screen.sh** — one-command screening launcher script
  - `./screen.sh <url>` handles Codespace creation, tool installation, and screening
  - `--destroy` flag: delete Codespace after screening (full wipe)
  - `--fresh` flag: force new Codespace (ignore existing)
  - `--help` with usage and security tradeoff explanation
  - Idempotent provisioning via `~/.screening-tools-installed` marker
  - Auto-run: reuses Codespace and starts Claude screening automatically on subsequent runs
  - Fallback: opens interactive SSH if Claude not logged in yet
  - Codespace lookup via `--display-name screener`
- README: "One-Command Screening" section at top
- README: "Reuse vs Destroy: Security Tradeoffs" section

### Changed
- README: file structure updated to include screen.sh
- Version bump to 5.0.0

### Deprecated
- **screening-launcher** skill — replaced entirely by screen.sh

## [4.3.2] - 2026-01-29

### Fixed
- Report saving uses `mv` instead of `cp` — no more duplicate `SCREENING-REPORT.md` left in repo root
- `gh auth login` missing `-s repo` scope — private repo screening failed because default scopes don't include private repo access

## [4.3.0] - 2026-01-29

### Added
- **Screening Private Repos** section - `gh auth login` workflow for private repo access
- **Saving Reports** section - commit reports to Codespace's repo for GitHub browsing
- Workflow steps 2 (private repo auth) and 13 (save report) added
- Docker/OrbStack `gh` installation instructions for private repo screening
- README: private repo instructions, report saving instructions
- README: describes skill as Agent Skill with link to [agentskills.io](https://agentskills.io)

### Changed
- Workflow now has 14 steps (was 12)
- README rewritten with installation & usage focus
- Version bump to 4.3.0

## [4.2.0] - 2026-01-29

### Added
- **Deep Dependency Investigation** section
  - Install suspicious dependencies in isolation
  - Observe behavior during installation
  - Inspect installed package source code
  - Compare published package vs source repo (supply chain injection detection)
  - Python package investigation workflow
  - Documentation template for investigated dependencies
- New workflow step 10: Deep dive suspicious dependencies
- Deep Dependency Investigation section in report output format

### Changed
- Workflow now has 12 steps (was 11)
- Version bump to 4.2.0

## [4.1.0] - 2026-01-29

### Added
- `author` field in metadata (gradigit)
- `tags` for discoverability (7 tags)
- `triggers` for activation patterns (7 triggers)
- Risk score calculation methodology section
- Tool versions table with tested versions
- Example 6: Tool Installation Failure Recovery
- Copyright holder to LICENSE file

### Changed
- Workflow section now explicitly references TaskCreate
- Self-evolution section enhanced with 5 evolution triggers
- Version references updated throughout examples

### Audit Result
- Grade: A
- All warnings resolved
- All suggestions implemented

## [4.0.0] - 2026-01-29

### Added
- Dynamic analysis workflow (execute and observe)
- Security scanning tools: Trivy, Gitleaks, actionlint, zizmor
- Process monitoring during npm/pip install
- Network activity observation
- File system change detection
- Comprehensive risk model section

### Changed
- Philosophy: "The sandbox is the protection, not network isolation"
- Network stays connected throughout screening
- Fresh sandbox every time, destroy after use

### Removed
- Network disconnect steps (unnecessary with proper sandboxing)
- Paranoid execution restrictions

## [3.1.0] - 2026-01-28

### Changed
- Replaced Claude.ai web with Docker/OrbStack local sandbox option
- Claude.ai web caused GitHub API rate limiting issues

## [3.0.0] - 2026-01-28

### Added
- GitHub Codespaces support (cloud sandbox)
- Environment detection commands
- Comparison table: Codespaces vs Docker

## [2.1.0] - 2026-01-27

### Added
- Environment detection for Codespaces/Docker

## [2.0.0] - 2026-01-27

### Changed
- Reframed from "audit" to "screening" (accurate naming)
- Added task list workflow for systematic screening

## [1.1.0] - 2026-01-26

### Added
- Slopsquatting detection (AI-hallucinated packages)
- CVE-2025-30066 (tj-actions/changed-files compromise)
- Expanded token patterns (OpenAI, Anthropic, GitLab, npm, PyPI)

## [1.0.0] - 2026-01-25

### Added
- Initial release
- Static analysis patterns for malicious code
- Supply chain detection (typosquatting)
- GitHub Actions security checks
- Secret detection patterns
- Prompt injection defense
