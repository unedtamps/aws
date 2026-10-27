terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "vpc_ans" {
  region     = var.aws_region
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "vpc-ans"
  }
}

resource "aws_internet_gateway" "igw_ans" {
  vpc_id = aws_vpc.vpc_ans.id
}


resource "aws_route_table" "rt_ans" {
  vpc_id = aws_vpc.vpc_ans.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_ans.id
  }
}
resource "aws_route_table_association" "rta_ans" {
  subnet_id      = aws_subnet.subnet_ans.id
  route_table_id = aws_route_table.rt_ans.id

}

resource "aws_subnet" "subnet_ans" {
  vpc_id     = aws_vpc.vpc_ans.id
  cidr_block = "10.0.2.0/28"
  tags = {
    Name = "subnet-ans"
  }
}

resource "aws_key_pair" "key_ans" {
  key_name   = var.key_name
  public_key = file("./key/ansible-key.pub")
}

resource "aws_security_group" "sg_http_ans" {
  vpc_id = aws_vpc.vpc_ans.id
  name   = "http-sg"
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "http-sg"
  }

}

resource "aws_security_group" "sg_ans" {
  vpc_id      = aws_vpc.vpc_ans.id
  name        = "ansible-sg"
  description = "Allow SSH"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "HTTP From Lb"
    from_port       = 8000
    to_port         = 8020
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_http_ans.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ansible-sg"
  }
}

resource "aws_instance" "ec2_ans" {
  count         = var.instance_count
  ami           = var.instance_ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet_ans.id
  key_name      = aws_key_pair.key_ans.key_name
  tags = {
    Name = var.instance_names[count.index]
  }
  vpc_security_group_ids = count.index == 0 ? [aws_security_group.sg_ans.id, aws_security_group.sg_http_ans.id] : [aws_security_group.sg_ans.id]
}

resource "aws_eip" "name" {
  count    = var.instance_count
  instance = aws_instance.ec2_ans[count.index].id
}

