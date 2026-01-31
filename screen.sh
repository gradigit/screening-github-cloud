#!/usr/bin/env bash
set -euo pipefail

VERSION="5.0.1"
DISPLAY_NAME="screener"
MACHINE_TYPE="basicLinux32gb"
MARKER=".screening-tools-installed"
REPO_NAME="screening-reports"

# --- Helpers ---

die() { echo "ERROR: $1" >&2; exit 1; }

usage() {
  cat <<'USAGE'
screen.sh — One-command sandboxed GitHub repo screening

Usage:
  screen-repo <repo-url> [options]
  screen-repo --help

Options:
  --destroy   Delete Codespace after screening (full wipe)
  --fresh     Force new Codespace (ignore existing)
  --help      Show this help

Examples:
  screen-repo https://github.com/owner/repo
  screen-repo https://github.com/owner/repo --destroy
  screen-repo https://github.com/owner/repo --fresh

First Run:
  1. Creates a Codespace, installs Claude Code CLI
  2. Opens interactive SSH — you run: claude login
  3. Then run: claude "screen <url>"
  4. Exit when done. Codespace stops (persists for reuse).

Subsequent Runs (Claude already logged in):
  1. Reuses existing Codespace, opens interactive SSH
  2. Run: claude "screen <url>"
  3. Exit when done. Codespace stops.

Security Tradeoffs:
  REUSE (default):
    - Codespace stops after screening, restarts on next run
    - Tools + Claude login persist — fast subsequent screenings
    - Risk: a malicious repo could leave artifacts that affect next screening
    - Best for: routine screenings of repos you expect are probably safe

  DESTROY (--destroy flag):
    - Codespace deleted after screening — nothing persists
    - Next run: full reinstall + Claude re-login required
    - Risk: none — completely fresh environment every time
    - Best for: high-risk targets you suspect are genuinely malicious
USAGE
  exit 0
}

# --- Parse Args ---

TARGET_URL=""
DESTROY=false
FRESH=false

for arg in "$@"; do
  case "$arg" in
    --destroy) DESTROY=true ;;
    --fresh)   FRESH=true ;;
    --help|-h) usage ;;
    https://github.com/*)
      TARGET_URL="$arg" ;;
    *)
      die "Unknown argument: $arg" ;;
  esac
done

[[ -n "$TARGET_URL" ]] || die "Missing repo URL. Usage: screen-repo <github-url> [--destroy] [--fresh]"

# --- Check Prerequisites ---

command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) not found. Install: https://cli.github.com"
gh auth status >/dev/null 2>&1 || die "Not logged in to GitHub CLI. Run: gh auth login"

# --- Get GitHub Username + Ensure Reports Repo ---

GH_USER=$(gh api user --jq .login) || die "Failed to get GitHub username"

gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1 || {
  echo "Creating private repo: $GH_USER/$REPO_NAME"
  gh repo create "$REPO_NAME" --private --description "Screening reports from screen.sh"
}

# --- Find or Create Codespace ---

CODESPACE_NAME=""

if [[ "$FRESH" == false ]]; then
  # Look for existing Codespace with our display name
  CODESPACE_NAME=$(gh codespace list --json name,displayName --jq ".[] | select(.displayName==\"$DISPLAY_NAME\") | .name" 2>/dev/null | head -1)
fi

if [[ -n "$CODESPACE_NAME" ]]; then
  echo "Reusing Codespace: $CODESPACE_NAME"
else
  echo "Creating new Codespace from $GH_USER/$REPO_NAME..."
  CREATE_OUTPUT=$(gh codespace create --repo "$GH_USER/$REPO_NAME" -m "$MACHINE_TYPE" --display-name "$DISPLAY_NAME" 2>&1)
  # gh codespace create prints the codespace name on stdout
  CODESPACE_NAME=$(echo "$CREATE_OUTPUT" | tail -1)
  [[ -n "$CODESPACE_NAME" ]] || die "Failed to create Codespace. Output:\n$CREATE_OUTPUT"
  echo "Created Codespace: $CODESPACE_NAME"
fi

# --- Idempotent Provisioning ---
# Only installs Claude Code CLI + screening skill.
# Security tools (Trivy, Gitleaks, etc.) are installed by the skill itself during screening.

echo "Checking provisioning status..."
INSTALLED=$(gh codespace ssh -c "$CODESPACE_NAME" -- "test -f ~/$MARKER && echo yes || echo no" 2>/dev/null || echo "no")

if [[ "$INSTALLED" != "yes" ]]; then
  echo "Installing Claude Code CLI + screening skill..."
  gh codespace ssh -c "$CODESPACE_NAME" -- 'bash -s' <<'PROVISION'
set -e

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Screening skill
mkdir -p ~/.claude/skills
if [ ! -d ~/.claude/skills/screening-github-cloud ]; then
  git clone https://github.com/gradigit/screening-github-cloud ~/.claude/skills/screening-github-cloud
fi

# Alias claude to skip permissions (sandbox is the protection)
grep -q 'alias claude=' ~/.bashrc 2>/dev/null || {
  echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc
}

# Mark as installed
touch ~/.screening-tools-installed

echo ""
echo "========================================"
echo "  Claude Code + screening skill installed"
echo "========================================"
PROVISION
  echo "Provisioning complete."
else
  echo "Already provisioned."
fi

# --- Open Interactive SSH ---

echo ""
echo "========================================"
echo "  Opening SSH session to Codespace"
echo "========================================"
echo ""
echo "  Inside the Codespace, run:"
echo ""
echo "  claude \"screen $TARGET_URL\""
echo ""
echo "  First time? Run 'claude login' first."
echo "  Private repo? Run: unset GITHUB_TOKEN && gh auth login -s repo"
echo ""
echo "  Type 'exit' when done."
echo "========================================"
echo ""

gh codespace ssh -c "$CODESPACE_NAME"

# --- Show Report Link ---

# Extract owner/repo from target URL → expected report filename
TARGET_PATH="${TARGET_URL#https://github.com/}"
TARGET_PATH="${TARGET_PATH%.git}"
OWNER_REPO=$(echo "$TARGET_PATH" | tr '/' '-')
TODAY=$(date +%Y-%m-%d)
REPORT_FILE="reports/${TODAY}-${OWNER_REPO}.md"

REPORT_URL="https://github.com/$GH_USER/$REPO_NAME/blob/main/$REPORT_FILE"

# Check if report was actually pushed
if gh api "repos/$GH_USER/$REPO_NAME/contents/$REPORT_FILE" >/dev/null 2>&1; then
  echo ""
  echo "========================================"
  echo "  Report: $REPORT_URL"
  echo "========================================"
fi

# --- Stop or Destroy ---

if [[ "$DESTROY" == true ]]; then
  echo "Destroying Codespace: $CODESPACE_NAME"
  gh codespace delete -c "$CODESPACE_NAME" --force
  echo "Codespace deleted."
else
  echo "Stopping Codespace: $CODESPACE_NAME"
  gh codespace stop -c "$CODESPACE_NAME" 2>/dev/null || true
  echo "Codespace stopped (will be reused on next run)."
  echo "To delete: gh codespace delete -c $CODESPACE_NAME --force"
fi
