resource "aws_vpc" "main" {
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "vpc-1"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/28"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "subent-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.16/28"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "subent-2"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.32/28"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "subent-3"
  }
}

resource "aws_subnet" "subnet_4" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.48/28"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "subent-4"
  }
}

resource "aws_eip" "nat_1" {
  domain = "vpc"
}

resource "aws_eip" "nat_2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.subnet_3.id

  tags = {
    Name = "nat-public-1"
  }
}

resource "aws_nat_gateway" "public_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.subnet_4.id

  tags = {
    Name = "nat-pubic-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gateway-1"
  }
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_1.id
  }

  tags = {
    Name = "route-table-private-1"
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_2.id
  }

  tags = {
    Name = "route-table-private-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "route-table-public"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.private_2.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.subnet_4.id
  route_table_id = aws_route_table.public.id
}
