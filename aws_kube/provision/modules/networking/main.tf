resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-igw"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id

  cidr_block              = "10.20.0.0/20"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    Name                              = "eks-private-a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id

  cidr_block              = "10.20.16.0/20"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = false

  tags = {
    Name                              = "eks-private-b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_nat_gateway" "regional" {
  vpc_id            = aws_vpc.main.id
  availability_mode = "regional"
  connectivity_type = "public"

  # Regional NAT gateways do not use subnet_id or allocation_id.
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "eks-regional-nat"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.regional.id
  }

  tags = {
    Name = "eks-private-routes"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
