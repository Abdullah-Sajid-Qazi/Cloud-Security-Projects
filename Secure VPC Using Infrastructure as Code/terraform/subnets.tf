# Public subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.project_name}-public-${count.index + 1}"
    Tier      = "public"
    ManagedBy = "terraform"
  }
}

# Private application subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(["10.0.10.0/24", "10.0.20.0/24"], count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name      = "${var.project_name}-private-${count.index + 1}"
    Tier      = "application"
    ManagedBy = "terraform"
  }
}

# Data subnets (isolated)
resource "aws_subnet" "data" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(["10.0.100.0/24", "10.0.200.0/24"], count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name      = "${var.project_name}-data-${count.index + 1}"
    Tier      = "data"
    ManagedBy = "terraform"
  }
}