# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name      = "${var.project_name}-nat-eip-${count.index + 1}"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# NAT Gateways (one per AZ)
resource "aws_nat_gateway" "this" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name      = "${var.project_name}-nat-${count.index + 1}"
    Tier      = "egress"
    ManagedBy = "terraform"
  }

  depends_on = [aws_internet_gateway.this]
}