resource "aws_iam_policy" "allow_assume_role" {
  name   = "AllowAssumeSecurityAuditRole"
  policy = file("../../policies/assume-role-policy-security.json")
}

resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = var.security_user_name
  policy_arn = aws_iam_policy.allow_assume_role.arn
}
