#!/bin/bash

echo "Running secret scan (gitleaks)..."

if ! command -v gitleaks &> /dev/null; then
  echo "gitleaks not found. Install it before committing."
  exit 1
fi

gitleaks detect \
  --staged \
  --redact \
  --no-git \
  --exit-code 1

if [ $? -ne 0 ]; then
  echo "❌ Secrets detected. Commit blocked."
  exit 1
fi

echo "✅ No secrets detected."
