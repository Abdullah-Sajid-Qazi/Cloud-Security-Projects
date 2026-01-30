# Workload Account – IAM Configuration Manual

## Purpose

This directory defines all IAM resources that live in the **Workload Account**.

The Workload Account hosts application and infrastructure resources and **does not allow direct human access**.  
All human access is granted indirectly via **cross-account role assumption** from the Security Account.

---

## Security Model

### Threats Addressed
- Over-privileged IAM users in workload accounts
- Long-lived credentials attached to human identities
- Lateral movement between AWS accounts
- Unauthorized administrative access

### Core Principle
> The Workload Account never trusts humans directly.

It only trusts **roles**, and only under strict conditions.

---

## Resources Managed Here

### 1. `SecurityAuditRole`

A read-only IAM role designed for:
- Security reviews
- Compliance validation
- Incident investigation (non-destructive)

#### Key Properties
- **No IAM users** exist in this account
- **MFA required** at role assumption time
- **STS only** (temporary credentials)
- **Least privilege** permissions

---

## Trust Policy Design

The role trust policy enforces:

- Explicit trust of the **Security Account only**
- `sts:AssumeRole` as the only allowed action
- MFA requirement enforced at the trust boundary

This ensures that:
- Stolen credentials alone are insufficient
- Authentication strength is verified before access
- Access is auditable via CloudTrail

---

## Permission Policy Design

The attached policy is intentionally **read-only**.

### Allowed Capabilities
- EC2 and VPC visibility (`Describe*`)
- IAM metadata inspection (`Get*`, `List*`)
- CloudTrail visibility
- CloudWatch visibility

### Explicitly Not Allowed
- IAM modifications
- Resource creation or deletion
- Data exfiltration
- Policy attachment or privilege escalation

This minimizes blast radius in the event of role misuse.

---

## Expected Behavior

When assumed successfully:
- Infrastructure visibility is available
- Write operations fail with `AccessDenied`
- Credentials expire automatically

When not assumed:
- No access to workload resources is possible

---

## Verification

After deployment:
1. Assume the role from the Security Account
2. Verify read-only access (e.g. EC2 listing)
3. Verify write operations are denied

This confirms correct least-privilege enforcement.

---

## Operational Notes

- This role is **not** intended for automation
- For programmatic access, a separate role with ExternalId should be created
- Administrative access must use a dedicated break-glass role (out of scope)

---

## Destruction

To remove all resources in this account:

```bash
terraform destroy
