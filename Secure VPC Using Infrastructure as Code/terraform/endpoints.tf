resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private[0].id,
    aws_route_table.private[1].id,
    aws_route_table.data.id
  ]

  tags = {
    Name      = "${var.project_name}-s3-endpoint"
    ManagedBy = "terraform"
  }
}


resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]

  security_group_ids = [
    aws_security_group.app.id
  ]

  private_dns_enabled = true

  tags = {
    Name      = "${var.project_name}-logs-endpoint"
    ManagedBy = "terraform"
  }
}
