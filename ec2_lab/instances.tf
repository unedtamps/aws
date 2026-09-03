resource "aws_instance" "app_1" {
  ami                    = var.instance_ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile
  monitoring             = false

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    Name = "instance-1"
  }
}

resource "aws_instance" "app_2" {
  ami                    = var.instance_ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_2.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile
  monitoring             = false

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    Name = "instance-2"
  }
}
