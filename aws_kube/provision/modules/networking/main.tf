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
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name                              = "eks-private-a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id

  cidr_block              = "10.20.16.0/20"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags = {
    Name                              = "eks-private-b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id

  cidr_block              = "10.20.32.0/20"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "eks-public-a"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id

  cidr_block              = "10.20.48.0/20"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "eks-public-b"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
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

# Do not use inline route blocks here. Routes are managed by aws_route
# resources (private_nat below and vpn_clients in the root module). Mixing
# inline routes with aws_route makes the route table authoritative and removes
# the VPN return route on refresh.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  lifecycle {
    # Keep the route table from adopting or removing routes managed by aws_route.
    ignore_changes = [route]
  }

  tags = {
    Name = "eks-private-routes"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.regional.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "eks-public-routes"
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

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
