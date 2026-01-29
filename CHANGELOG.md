# Changelog

All notable changes to this skill are documented here.

## [4.3.1] - 2026-01-29

### Fixed
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
