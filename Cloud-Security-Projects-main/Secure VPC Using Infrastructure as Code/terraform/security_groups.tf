# ALB Security Group (no rules yet)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name      = "${var.project_name}-alb-sg"
    Tier      = "public"
    ManagedBy = "terraform"
  }
}

# App Security Group (no rules yet)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Application tier security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name      = "${var.project_name}-app-sg"
    Tier      = "application"
    ManagedBy = "terraform"
  }
}

# Database Security Group (no rules yet)
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Database security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name      = "${var.project_name}-db-sg"
    Tier      = "data"
    ManagedBy = "terraform"
  }
}