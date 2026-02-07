#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Pre-Commit Security Hook
# Runs secret scanning locally before commits reach the repo.
# Install: cp "CICD Security Pipeline/scripts/pre-commit.sh" \
#             .git/hooks/pre-commit
#          chmod +x .git/hooks/pre-commit
# ═══════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "═══════════════════════════════════════════"
echo "  Running Pre-Commit Security Check..."
echo "═══════════════════════════════════════════"
echo ""

# ─── SECRET SCANNING (gitleaks) ───
echo "🔑 Secret Scanning (gitleaks)..."

if command -v gitleaks &> /dev/null; then
  if ! gitleaks detect --staged --redact --no-git --exit-code 1 2>/dev/null; then
    echo -e "${RED}❌ Secrets detected! Commit blocked.${NC}"
    echo "   Run 'gitleaks detect --staged --verbose' for details."
    echo ""
    echo "═══════════════════════════════════════════"
    echo -e "${RED}  COMMIT BLOCKED — Remove secrets above.${NC}"
    echo "═══════════════════════════════════════════"
    exit 1
  else
    echo -e "${GREEN}✅ No secrets detected.${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  gitleaks not installed. Skipping secret scan.${NC}"
  echo "   Install: https://github.com/gitleaks/gitleaks#installing"
  echo ""
  echo "═══════════════════════════════════════════"
  echo -e "${YELLOW}  WARNING: Secret scan skipped.${NC}"
  echo "═══════════════════════════════════════════"
  exit 0
fi

echo ""
echo "═══════════════════════════════════════════"
echo -e "${GREEN}  ✓ Secret check passed — Committing.${NC}"
echo "═══════════════════════════════════════════"
exit 0
