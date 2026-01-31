#!/usr/bin/env bash
set -euo pipefail

VERSION="5.0.0"
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
  ./screen.sh <repo-url> [options]
  ./screen.sh --help

Options:
  --destroy   Delete Codespace after screening (full wipe)
  --fresh     Force new Codespace (ignore existing)
  --help      Show this help

Examples:
  ./screen.sh https://github.com/owner/repo
  ./screen.sh https://github.com/owner/repo --destroy
  ./screen.sh https://github.com/owner/repo --fresh

First Run:
  1. Creates a Codespace, installs Claude Code + security tools
  2. Opens interactive SSH — you run: claude login
  3. Then run: claude --dangerously-skip-permissions "screen <url>"
  4. Exit when done. Codespace stops (persists for reuse).

Subsequent Runs (Claude already logged in):
  1. Reuses existing Codespace
  2. Claude starts screening automatically (no interaction needed)
  3. After screening, Codespace stops

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

[[ -n "$TARGET_URL" ]] || die "Missing repo URL. Usage: ./screen.sh <github-url> [--destroy] [--fresh]"

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

echo "Checking provisioning status..."
INSTALLED=$(gh codespace ssh -c "$CODESPACE_NAME" -- "test -f ~/$MARKER && echo yes || echo no" 2>/dev/null || echo "no")

if [[ "$INSTALLED" != "yes" ]]; then
  echo "Installing tools (first time setup)..."
  gh codespace ssh -c "$CODESPACE_NAME" -- 'bash -s' <<'PROVISION'
set -e

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Screening skill
mkdir -p ~/.claude/skills
if [ ! -d ~/.claude/skills/screening-github-cloud ]; then
  git clone https://github.com/gradigit/screening-github-cloud ~/.claude/skills/screening-github-cloud
fi

# Glow (markdown renderer)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt-get update && sudo apt-get install -y glow

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

# Gitleaks
GITLEAKS_VERSION=8.18.0
curl -sSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" | sudo tar -xz -C /usr/local/bin gitleaks

# Optional: actionlint (needs go)
go install github.com/rhysd/actionlint/cmd/actionlint@latest 2>/dev/null || echo "actionlint: go not available, skipping"

# Optional: zizmor (needs pip)
pip install zizmor 2>/dev/null || echo "zizmor: pip not available, skipping"

# Alias claude to skip permissions (sandbox is the protection)
grep -q 'alias claude=' ~/.bashrc 2>/dev/null || {
  echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc
}

# Mark as installed
touch ~/.screening-tools-installed

echo ""
echo "========================================"
echo "  Tools installed successfully!"
echo "========================================"
PROVISION
  echo "Provisioning complete."
else
  echo "Tools already installed."
fi

# --- Try Auto-Run Claude ---

echo ""
echo "Attempting to start screening automatically..."

SCREEN_CMD="claude --dangerously-skip-permissions \"screen $TARGET_URL\""

if gh codespace ssh -c "$CODESPACE_NAME" -- "bash -lc '$SCREEN_CMD'" 2>/dev/null; then
  echo ""
  echo "Screening complete."
else
  AUTO_EXIT=$?
  echo ""
  echo "Auto-run failed (exit $AUTO_EXIT) — Claude may not be logged in yet."
  echo ""
  echo "========================================"
  echo "  Opening interactive SSH session"
  echo "========================================"
  echo ""
  echo "  Run these commands inside the Codespace:"
  echo ""
  echo "  1. claude login"
  echo "  2. claude --dangerously-skip-permissions \"screen $TARGET_URL\""
  echo "  3. exit"
  echo ""
  echo "  For private repos: unset GITHUB_TOKEN && gh auth login -s repo"
  echo ""
  echo "========================================"
  echo ""
  gh codespace ssh -c "$CODESPACE_NAME"
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
