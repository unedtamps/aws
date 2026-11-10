locals {
  client_network = cidrhost(var.client_cidr, 0)
  client_netmask = cidrnetmask(var.client_cidr)

  tags = {
    Name      = "${var.cluster_name}-vpn"
    Project   = "aws-kube-lab"
    ManagedBy = "OpenTofu"
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-${var.architecture}"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "vpn" {
  name_prefix = "${var.cluster_name}-vpn-"
  description = "OpenVPN server and forwarded client traffic"
  vpc_id      = var.vpc_id

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "openvpn" {
  for_each = toset(var.admin_cidrs)

  security_group_id = aws_security_group.vpn.id
  description       = "OpenVPN UDP from admin networks"
  cidr_ipv4         = each.value
  ip_protocol       = "udp"
  from_port         = 1194
  to_port           = 1194
}

resource "aws_vpc_security_group_ingress_rule" "kubernetes_api" {
  security_group_id = aws_security_group.vpn.id
  description       = "Forwarded Kubernetes API traffic from VPN clients"
  cidr_ipv4         = var.client_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "dns_udp" {
  security_group_id = aws_security_group.vpn.id
  description       = "Forwarded DNS traffic to the VPC resolver"
  cidr_ipv4         = var.client_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
}

resource "aws_vpc_security_group_ingress_rule" "dns_tcp" {
  security_group_id = aws_security_group.vpn.id
  description       = "Forwarded DNS-over-TCP traffic to the VPC resolver"
  cidr_ipv4         = var.client_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.vpn.id
  description       = "Allow VPN server egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_iam_policy_document" "vpn_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpn" {
  name               = "${var.cluster_name}-vpn"
  assume_role_policy = data.aws_iam_policy_document.vpn_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "vpn_ssm" {
  role       = aws_iam_role.vpn.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "vpn" {
  name = "${var.cluster_name}-vpn"
  role = aws_iam_role.vpn.name

  tags = local.tags
}

resource "aws_eip" "vpn" {
  domain = "vpc"

  tags = local.tags
}

resource "aws_instance" "vpn" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.vpn.id]
  iam_instance_profile        = aws_iam_instance_profile.vpn.name
  associate_public_ip_address = true
  source_dest_check           = false
  user_data_replace_on_change = true

  # The instance must not boot before its role can talk to SSM, otherwise the
  # agent's first registration attempt fails and registration is delayed.
  depends_on = [aws_iam_role_policy_attachment.vpn_ssm]

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    cluster_name   = var.cluster_name
    client_network = local.client_network
    client_netmask = local.client_netmask
    vpn_public_ip  = aws_eip.vpn.public_ip
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = local.tags
}

resource "aws_eip_association" "vpn" {
  instance_id   = aws_instance.vpn.id
  allocation_id = aws_eip.vpn.id
}
