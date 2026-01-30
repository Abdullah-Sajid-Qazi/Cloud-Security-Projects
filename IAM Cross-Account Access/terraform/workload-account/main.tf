resource "aws_iam_role" "security_audit_role" {
  name               = "SecurityAuditRole"
  assume_role_policy = file("../../policies/trust-policy-workload.json")
}

resource "aws_iam_policy" "security_audit_policy" {
  name   = "SecurityAuditReadOnlyPolicy"
  policy = file("../../policies/security-audit-policy.json")
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.security_audit_role.name
  policy_arn = aws_iam_policy.security_audit_policy.arn
}
