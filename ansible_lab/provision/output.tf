output "ips" {
  value = {
    for i, instance in aws_instance.ec2_ans : instance.tags.Name => instance.public_ip
  }
}

