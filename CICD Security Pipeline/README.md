# CI/CD Security Pipeline

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

In this repository, active workflows live at the **repository root** (`.github/workflows/` at the top level), which is where GitHub Actions requires them to be. The CICD Security Pipeline project contains a complete copy of these workflows as a reference implementation.

```
Repository Root:
├── .github/workflows/              # Active workflows (GitHub runs these)
│   ├── secret-scan.yml            # Trigger workflow
│   ├── secret-scan-reusable.yml   # Reusable Gitleaks scan
│   ├── sast.yml                   # Trigger workflow
│   ├── sast-reusable.yml          # Reusable Semgrep scan
│   ├── dependency-scan.yml
│   ├── dependency-scan-reusable.yml
│   └── (etc)
│
└── CICD Security Pipeline/         # This project (portable reference)
    ├── workflow-templates/         # Complete workflow examples to copy
    │   ├── secret-scan.yml
    │   ├── secret-scan-reusable.yml
    │   ├── sast.yml
    │   ├── sast-reusable.yml
    │   └── (etc)
    ├── policies/                   # Security rules and configs
    ├── scripts/                    # Pre-commit hooks
    └── demo/                       # Vulnerable apps for testing
```

This architecture allows us to:
- Run the same security checks across multiple projects in the mono-repo
- Update security tooling in one place
- Keep the CICD project as a portable, standalone reference implementation
- Scale security practices across the organization

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

### Setup for a New Repository

To implement this security pipeline in your own repository:

1. **Copy workflows to your repository root**:
```bash
cp "CICD Security Pipeline/workflow-templates/"*.yml <your-repo>/.github/workflows/
```

2. **Copy security policies and configurations**:
```bash
cp -r "CICD Security Pipeline/policies/" <your-repo>/policies/
```

3. **Copy helper scripts**:
```bash
cp -r "CICD Security Pipeline/scripts/" <your-repo>/scripts/
```

4. **Install pre-commit hook** (optional but recommended):
```bash
cp <your-repo>/scripts/pre-commit.sh <your-repo>/.git/hooks/pre-commit
chmod +x <your-repo>/.git/hooks/pre-commit
```

5. **Customize thresholds**: Edit `policies/checkov-config/.checkov.yml` and workflow files to match your risk tolerance.

6. **Test with a PR**: Make a code change and open a pull request. All security scans will run automatically.

### Using This Repository

In this mono-repo, the workflows are already active at the repository root (`.github/workflows/`). They scan all projects including the demo vulnerable applications.

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

