# Project: CI/CD Security Pipeline

## Overview

This project implements a comprehensive security scanning pipeline that embeds security checks directly into the development workflow. Rather than treating security as a final gate before production, this approach shifts security left—catching vulnerabilities early when they're cheapest and easiest to fix.

The pipeline automatically scans for secrets, code vulnerabilities, dependency issues, infrastructure misconfigurations, and container weaknesses on every pull request and push to main.

## Philosophy: Security as an Enabler

Security tooling should empower developers, not frustrate them. This pipeline is designed with several core principles:

**Fast Feedback**: All scans complete in under 5 minutes, providing results while context is fresh. Developers see issues immediately in their PRs with clear, actionable guidance.

**High Signal-to-Noise**: Only high-confidence findings block the pipeline. We tune rules aggressively to minimize false positives—a 10% false positive rate is our threshold for disabling or refining a rule. If security checks cry wolf too often, developers will bypass them.

**Transparent Exception Process**: When a security tool flags something incorrectly or when there's a valid business reason to accept a risk, developers can document an exception in `policies/exceptions/exceptions.yml`. Every exception requires justification, an owner, and an expiration date. This creates an audit trail without creating friction.

**Progressive Enforcement**: Rather than enabling every possible check on day one (which would block all development), we start with high-severity, high-confidence rules and expand coverage over time as teams build trust in the system.

## Architecture

The pipeline uses **reusable GitHub Actions workflows** for modularity. Each security check is isolated in its own workflow that can be called from multiple places.

This project is a **portable, standalone implementation** that contains everything you need in one place:

```
CICD Security Pipeline/
├── .github/workflows/              # Ready-to-use GitHub Actions workflows
│   ├── secret-scan.yml            # Trigger workflow for secret detection
│   ├── secret-scan-reusable.yml   # Reusable Gitleaks scan logic
│   ├── sast.yml                   # Trigger workflow for static analysis
│   ├── sast-reusable.yml          # Reusable Semgrep scan logic
│   ├── dependency-scan.yml        # Trigger workflow for dependency scanning
│   ├── dependency-scan-reusable.yml
│   ├── container-scan.yml         # Container image scanning
│   ├── container-scan-reusable.yml
│   ├── iac-scan-reusable.yml      # Infrastructure as Code scanning
│   ├── global-iac-scan.yml        # IaC scan trigger
│   └── vpc-iac-scan.yml           # VPC-specific IaC scan
├── policies/                       # Security rules and configurations
│   ├── checkov-config/            # Checkov IaC scanning rules
│   ├── exceptions/                # Document false positives
│   └── semgrep-rules/             # Custom Semgrep security rules
├── scripts/                        # Helper scripts
│   └── pre-commit.sh              # Local pre-commit hooks
└── demo/                           # Vulnerable demo apps for testing
    ├── app.py                     # Flask app with security issues
    ├── insecure.tf                # Vulnerable Terraform configs
    ├── Dockerfile                 # Insecure container setup
    └── requirements.txt           # Python dependencies
```

This architecture allows you to:
- Copy the entire project to any repository and start using it immediately
- Customize workflows and policies for your specific needs
- Use reusable workflows to avoid duplicating security logic
- Scale security practices across multiple repositories

## Security Scanning Components

### 1. Secret Scanning (Gitleaks)

**What it catches**: AWS keys, API tokens, passwords, private keys, database credentials

**When it runs**: 
- Pre-commit hook (local developer machine)
- On every PR and push to main

**Enforcement**: Always blocks. Secrets in code are never acceptable—they should be in environment variables, AWS Secrets Manager, or Parameter Store.

**Tool**: [Gitleaks](https://github.com/gitleaks/gitleaks)

### 2. Static Application Security Testing (Semgrep)

**What it catches**: 
- SQL injection vulnerabilities
- Command injection
- Server-side template injection (SSTI)
- Hardcoded credentials in code logic
- Insecure deserialization (pickle, YAML)
- Flask debug mode enabled

**When it runs**: On every PR and push to main

**Enforcement**: Blocks on ERROR severity findings. WARNING severity findings are reported but don't block the pipeline—these are typically code quality issues or potential vulnerabilities that require human judgment.

**Configuration**: Uses OWASP Top 10 ruleset plus custom rules in `policies/semgrep-rules/custom-rules.yml`

**Tool**: [Semgrep](https://semgrep.dev/)

### 3. Dependency Scanning (OWASP Dependency-Check)

**What it catches**: Known CVEs in Python packages, JavaScript libraries, and other dependencies

**When it runs**: 
- On every push to main
- Weekly on a schedule (Monday 6 AM UTC)
- On-demand via workflow dispatch

**Enforcement**: Blocks on CVSS 9.0+ (Critical) vulnerabilities with known exploits. Medium and High severity findings are reported but don't block—these are often theoretical vulnerabilities or issues in code paths we don't use.

**Scheduled scanning**: Weekly scans catch newly-disclosed CVEs even when no code changes. This ensures we're alerted to new vulnerabilities in existing dependencies.

**Tool**: [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)

### 4. Infrastructure as Code Scanning (Checkov)

**What it catches**:
- S3 buckets without encryption
- S3 buckets without versioning or logging
- Security groups open to 0.0.0.0/0 on SSH/RDP
- RDS databases without encryption
- EC2 instances without IMDSv2
- Missing security controls in Terraform

**When it runs**: On every PR that modifies `.tf` files

**Enforcement**: Blocks on critical misconfigurations (public S3, open SSH, missing encryption). Allows informational findings to pass—for example, we don't require CMK encryption for every S3 bucket when SSE-S3 is sufficient for most use cases.

**Configuration**: Hard-fail checks and exceptions defined in `policies/checkov-config/.checkov.yml`

**Tool**: [Checkov](https://www.checkov.io/)

### 5. Container Image Scanning (Trivy)

**What it catches**:
- OS package vulnerabilities (CVEs in Ubuntu, Alpine, etc.)
- Outdated base images
- Security misconfigurations (running as root, exposed ports)

**When it runs**: On PRs that modify Dockerfiles or application code in the demo directory

**Enforcement**: Blocks on CRITICAL severity OS vulnerabilities. We ignore unfixed vulnerabilities (no patch available) to avoid blocking development on issues we can't resolve.

**Tool**: [Trivy](https://github.com/aquasecurity/trivy)

## Enforcement Strategy: Block vs. Warn

The pipeline uses a **risk-based approach** to decide when to block deployments:

### Always Block
- Secrets committed to the repository (API keys, passwords)
- SQL injection or command injection vulnerabilities
- Critical CVEs (CVSS 9.0+) with known exploits
- S3 buckets configured for public access
- Security groups open to 0.0.0.0/0 on sensitive ports (22, 3389)
- Missing encryption on data stores (RDS, S3)

### Warn but Allow
- Medium severity dependency vulnerabilities (CVSS 4.0-6.9)
- Code quality issues (complexity, duplication)
- Informational security findings
- Documented false positives with valid exceptions

### Context Matters

The block/warn threshold isn't absolute—it depends on:

**Application sensitivity**: Customer-facing applications with PII have stricter thresholds than internal tools.

**Regulatory requirements**: In healthcare (HIPAA) or finance (PCI-DSS), we'd block on Medium severity findings and require formal change approval processes.

**Team maturity**: New teams start with more lenient thresholds and increase strictness as security practices mature.

**Emergency situations**: We have an exception process for critical production issues, requiring security team approval and a follow-up ticket to address the bypass.

## Handling False Positives

False positives are the enemy of security automation. If developers see too many incorrect findings, they lose trust in the tools and start ignoring all alerts—real ones included.

### Our Approach

**1. Tune Rules Aggressively**

We start with high-confidence rules only. If a rule generates more than 10% false positives, we either:
- Adjust the rule to be more precise
- Downgrade it from ERROR to WARNING
- Disable it entirely and document why

**2. Easy Exception Process**

Developers can suppress false positives by adding them to `policies/exceptions/exceptions.yml`:

```yaml
exceptions:
  - id: EXC-001
    tool: semgrep
    rule: python.flask.security.xss.audit.template-string
    file: admin_tool.py
    reason: Admin interface - input is sanitized before rendering
    approved_by: Security Team
    created: "2026-02-07"
    expires: "2026-08-07"
    ticket: JIRA-1234
```

Every exception requires:
- A unique ID for tracking
- Clear justification
- An expiration date (no permanent exceptions)
- An approver (security team or tech lead)
- Optional: link to tracking ticket for remediation

**3. Quarterly Review**

Security and engineering teams review all active exceptions quarterly. Expired exceptions are either renewed with fresh justification or the underlying code is fixed. This prevents exception creep.

**4. Metrics Dashboard**

We track false positive rates per tool and per rule. High false-positive rules are candidates for tuning or removal. We also track mean-time-to-exception-approval to ensure the process doesn't become a bottleneck.

## Compliance and Regulated Environments

In regulated industries (healthcare, finance, government), this pipeline would include additional controls:

### Enhanced Audit Logging
- Every scan result stored with cryptographic integrity
- Who approved exceptions, when, and why
- Complete change history for compliance reporting

### Stricter Enforcement
- Block on Medium severity findings (CVSS 4.0+), not just Critical
- No time-bound exceptions—all vulnerabilities must be remediated
- Mandatory code review by security team for infrastructure changes
- Digital signatures on deployments

### Additional Scanning
- DAST (dynamic testing) in staging environments
- Penetration testing before production deployments
- License compliance scanning (no GPL in proprietary code)
- Supply chain security (verify package signatures)

### Evidence Collection
- SOC 2 / ISO 27001 auditors need proof of security testing
- Automated reports showing scan coverage and remediation times
- Attestations that all security checks passed before production

### Approved Tool Lists
- Government/FedRAMP requires tools from approved vendor lists
- May need to replace open-source tools with commercial equivalents
- Additional certifications for scanning tools themselves

## Developer Experience

Security tools can be frustrating. We've optimized for developer happiness:

### Clear, Actionable Findings

❌ **Bad**: "Security check failed"

✅ **Good**: "Line 42: SQL injection vulnerability detected. Use parameterized queries instead of string concatenation. See: https://semgrep.dev/docs/sql-injection"

Every finding includes:
- Exact file and line number
- Plain-English explanation of the risk
- Specific remediation steps
- Link to documentation

### Pre-Commit Hooks

The `scripts/pre-commit.sh` hook catches secrets locally before they reach GitHub. This saves developers from the embarrassment of having their commits blocked by CI, and prevents secrets from ever entering the Git history (even blocked commits stay in history).

Installation:
```bash
# From repository root
cp "CICD Security Pipeline/scripts/pre-commit.sh" .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Fast Feedback

All scans complete in under 5 minutes. We run scans in parallel where possible and cache dependencies to minimize wait time.

### Escape Hatches

Sometimes developers need to bypass security checks for legitimate reasons (hotfix, demo, known false positive). The exception process provides a documented, auditable way to do this without "just disabling the check."

## Getting Started

### Prerequisites
- GitHub repository with Actions enabled
- Python, Terraform, or Docker projects to scan

### Setup Instructions

This project is designed to be portable and easy to deploy to any repository. Here are three ways to use it:

#### Option 1: Copy the Entire Project to Your Repository Root

The simplest approach is to copy this entire `CICD Security Pipeline` directory to your repository:

```bash
# From your repository root
cp -r /path/to/CICD\ Security\ Pipeline/ ./
```

Then move the workflows to where GitHub expects them:

```bash
# Move workflows to repository root (GitHub requires .github/workflows at root level)
mkdir -p .github
mv "CICD Security Pipeline/.github/workflows" .github/
```

#### Option 2: Selective Copy (Workflows Only)

If you only want the workflows:

```bash
# Create .github/workflows directory at your repository root
mkdir -p .github/workflows

# Copy all workflow files
cp "CICD Security Pipeline/.github/workflows/"*.yml .github/workflows/

# Copy policies and configurations (needed for the workflows to function)
cp -r "CICD Security Pipeline/policies/" ./policies/

# Optionally copy scripts for pre-commit hooks
cp -r "CICD Security Pipeline/scripts/" ./scripts/
```

#### Option 3: Use This Repository Directly

If you're working within this repository, the workflows are ready to use immediately. They will:
- Scan all code in pull requests
- Run scheduled scans on the main branch
- Test the demo vulnerable applications

### Post-Setup Steps

1. **Install pre-commit hook** (optional but recommended):
```bash
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

2. **Customize thresholds**: Edit `policies/checkov-config/.checkov.yml` and workflow files to match your risk tolerance and compliance requirements.

3. **Test with a PR**: Make a code change and open a pull request. All security scans will run automatically.

4. **Review findings**: Check the Actions tab in GitHub to see scan results.

### Important Notes

- **GitHub requires workflows at repository root**: GitHub Actions only runs workflows from `.github/workflows/` at the repository root, not from subdirectories. That's why you need to move or copy the workflows to the root level.
- **Relative paths in workflows**: The workflow files reference policies using relative paths (e.g., `policies/exceptions/exceptions.yml`). If you change the folder structure, update these paths accordingly.
- **Reusable workflows**: The `-reusable.yml` files contain the actual scanning logic and are called by the trigger workflows (`*-scan.yml`). Keep both types of files together.

### What Happens on a Pull Request

1. **Secret Scan**: Gitleaks checks for exposed credentials
2. **SAST**: Semgrep analyzes code for vulnerabilities
3. **IaC Scan**: Checkov validates Terraform (if .tf files changed)
4. **Container Scan**: Trivy scans Docker images (if Dockerfile changed)

If all checks pass ✅, the PR can be merged.

If any check fails ❌, the PR is blocked with detailed findings shown in the Actions tab.

## Demo Examples

The `demo/` directory contains intentionally vulnerable code to test the pipeline:

- **app.py**: Python Flask app with SQL injection, command injection, SSTI, and hardcoded secrets
- **insecure.tf**: Terraform with public S3 buckets, open security groups, missing encryption
- **Dockerfile**: Container with outdated base image, running as root, unpinned dependencies

Try making a PR that touches these files to see the security pipeline in action.

## Continuous Improvement

This pipeline is a starting point, not a destination. As your team matures, consider:

- **DAST scanning**: Add dynamic testing in staging (OWASP ZAP, Burp Suite)
- **Penetration testing**: Scheduled pentests by security team or external consultants
- **Fuzzing**: Automated fuzzing for input validation bugs
- **Runtime security**: Add AWS GuardDuty, Falco, or other runtime protection
- **Secrets management**: Enforce AWS Secrets Manager with IAM policies
- **Software Bill of Materials (SBOM)**: Generate and track SBOMs for supply chain security

## Metrics to Track

- **Mean time to remediation**: How long from finding to fix?
- **False positive rate**: Are we annoying developers unnecessarily?
- **Security debt**: How many findings are in the backlog?
- **Exception aging**: Are exceptions being renewed forever or actually fixed?
- **Scan coverage**: What percentage of code is being scanned?

Good metrics drive good behavior. Bad metrics drive gaming the system.

## Contributing

When adding new security rules:
1. Test against existing codebase to measure false positive rate
2. Start as WARNING severity, not ERROR
3. Document the rule's purpose in comments
4. Add an example of vulnerable code and secure code
5. Monitor feedback from developers for the first month

When requesting an exception:
1. Add it to `policies/exceptions/exceptions.yml`
2. Include clear justification and expiration date
3. Get approval from security team or tech lead
4. Create a ticket to track remediation (if applicable)

## License

This is a demonstration project for educational purposes.

## Resources

- [OWASP DevSecOps Guidelines](https://owasp.org/www-project-devsecops-guideline/)
- [Semgrep Registry](https://semgrep.dev/r)
- [Checkov Policies](https://www.checkov.io/5.Policy%20Index/all.html)
- [GitHub Advanced Security](https://docs.github.com/en/code-security)

---

**Remember**: Security tooling is only as good as its adoption. Fast, accurate, and developer-friendly checks get used. Slow, noisy, and obstructive checks get bypassed.

