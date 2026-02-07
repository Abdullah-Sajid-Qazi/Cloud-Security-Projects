# ALB inbound HTTPS from Internet
resource "aws_security_group_rule" "alb_in_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# ALB outbound to App tier
resource "aws_security_group_rule" "alb_out_app" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

# App inbound from ALB
resource "aws_security_group_rule" "app_in_alb" {
  type              = "ingress"
  security_group_id = aws_security_group.app.id

  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

# App outbound (general egress via NAT)
resource "aws_security_group_rule" "app_out_all" {
  type              = "egress"
  security_group_id = aws_security_group.app.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# DB inbound from App tier
resource "aws_security_group_rule" "db_in_app" {
  type              = "ingress"
  security_group_id = aws_security_group.db.id

  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}