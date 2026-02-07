# Data route table (isolated)
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = "${var.project_name}-data-rt"
    Tier      = "data"
    ManagedBy = "terraform"
  }
}

# Associate data route table with data subnets
resource "aws_route_table_association" "data" {
  count          = 2
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}