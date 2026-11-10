# VPN module (OpenVPN on EC2)

Self-managed OpenVPN server for private EKS API access.

## What it creates

- One EC2 instance in a public subnet with an Elastic IP.
- Security group:
  - `1194/udp` from `admin_cidrs`
  - `443/tcp` and `53/udp,tcp` from `client_cidr` (forwarded traffic)
  - no public SSH; use SSM Session Manager
- IAM instance profile with `AmazonSSMManagedInstanceCore`.
- OpenVPN PKI generated at first boot (`easy-rsa`), one `admin` client.
- Split tunnel: clients only receive `10.20.0.0/16` and DNS `10.20.0.2`.
- No NAT: client IPs are preserved, so the EKS control plane security group
  can allow `443` from `client_cidr` only.

## Client certificate

The module creates `/root/clients/admin.ovpn` on the instance. Retrieve it
through SSM:

```bash
aws ssm start-session --target <vpn-instance-id>
sudo cat /root/clients/admin.ovpn
```

Additional users:

```bash
sudo /usr/local/sbin/make-ovpn <name>
sudo cat /root/clients/<name>.ovpn
```

Revoke:

```bash
sudo /usr/local/sbin/revoke-ovpn <name>
```

## Notes

- The module itself does **not** change the EKS endpoint. The root module adds
  the control-plane security group and the private route table entry.
- Keep `cluster_endpoint_public_access = true` until the VPN path is verified;
  then set it to `false`.
- The VPC resolver (`10.20.0.2`) must be pushed to clients so the private EKS
  endpoint hostname resolves to the control plane ENIs.
- Client keys are generated with `nopass`, which is acceptable for the lab.
  Use a passphrase for anything beyond a lab.
