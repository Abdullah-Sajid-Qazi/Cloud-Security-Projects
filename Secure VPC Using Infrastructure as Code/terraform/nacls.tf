resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = "${var.project_name}-public-nacl"
    Tier      = "public"
    ManagedBy = "terraform"
  }
}

# Inbound HTTPS
resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Inbound ephemeral (return traffic)
resource "aws_network_acl_rule" "public_in_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound all
resource "aws_network_acl_rule" "public_out_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}


resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = "${var.project_name}-private-nacl"
    Tier      = "application"
    ManagedBy = "terraform"
  }
}

# Inbound app traffic from VPC
resource "aws_network_acl_rule" "private_in_app" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 8080
  to_port        = 8080
}

# Inbound ephemeral
resource "aws_network_acl_rule" "private_in_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound all (NAT handles control)
resource "aws_network_acl_rule" "private_out_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}


resource "aws_network_acl" "data" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = "${var.project_name}-data-nacl"
    Tier      = "data"
    ManagedBy = "terraform"
  }
}

# Inbound DB traffic from VPC
resource "aws_network_acl_rule" "data_in_db" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 5432
  to_port        = 5432
}

# Inbound ephemeral
resource "aws_network_acl_rule" "data_in_ephemeral" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 1024
  to_port        = 65535
}

# Outbound ephemeral only
resource "aws_network_acl_rule" "data_out_ephemeral" {
  network_acl_id = aws_network_acl.data.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 1024
  to_port        = 65535
}

# Public subnets
resource "aws_network_acl_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  network_acl_id = aws_network_acl.public.id
}

# Private subnets
resource "aws_network_acl_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  network_acl_id = aws_network_acl.private.id
}

# Data subnets
resource "aws_network_acl_association" "data" {
  count          = 2
  subnet_id      = aws_subnet.data[count.index].id
  network_acl_id = aws_network_acl.data.id
}