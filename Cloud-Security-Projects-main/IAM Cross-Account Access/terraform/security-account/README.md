# Security Account – IAM Configuration Manual

## Purpose

This directory defines IAM permissions in the **Security Account** that allow a human identity to assume roles in other AWS accounts.

The Security Account acts as the **central access hub** for humans.

---

## Security Model

### Threats Addressed
- Credential sprawl across accounts
- Shared or reused IAM users
- Lack of MFA enforcement
- Poor auditability of access

### Core Principle
> Humans authenticate once, centrally, with MFA — then assume roles.

The Security Account does **not** grant direct access to workload resources.

---

## Resources Managed Here

### 1. AssumeRole Permission Policy

This policy allows a specific IAM user to:
- Call `sts:AssumeRole`
- Only for the explicitly defined role in the Workload Account

#### Important Characteristics
- No wildcards
- No administrative permissions
- No direct service access

This limits the user’s blast radius to role assumption only.

---

## IAM User Requirements

The IAM user receiving this policy must:

- Exist only in the **Security Account**
- Have **MFA enabled**
- Authenticate via console or approved mechanism
- Not have long-lived access keys (preferred)

This ensures strong authentication before any cross-account access.

---

## Why MFA Is Required Here

MFA is evaluated by the **target role’s trust policy**, not this policy.

This design ensures:
- Authentication strength is enforced at the trust boundary
- MFA cannot be bypassed via permissions alone
- The same MFA requirement applies across all accounts

---

## Expected Behavior

When properly configured:
- User can log into the Security Account with MFA
- User can successfully assume the audit role
- User cannot access any AWS service directly in the Security Account

If permissions are misused:
- AssumeRole attempts fail
- Access is denied without partial access leakage

---

## Operational Notes

- This policy should only be attached to **human access identities**
- Automation should use separate roles and credentials
- Access keys for this user are discouraged

---

## Verification

After deployment:
1. Log in as the IAM user with MFA
2. Attempt role assumption
3. Confirm access is granted only via assumed role
4. Confirm direct service access is denied

---

## Destruction

To remove all permissions from the Security Account:

```bash
terraform destroy
