output "ips" {
  value = {
    for i, eip in aws_eip.name : aws_instance.ec2_ans[i].tags.Name => eip.public_ip
  }
}

output "private_ips" {
  value = {
    for instance in aws_instance.ec2_ans : instance.tags.Name => instance.private_ip
  }
}
