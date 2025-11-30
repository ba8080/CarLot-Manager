output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "instance_ips" {
  value = aws_instance.k8s_node[*].public_ip
}

output "master_private_ip" {
  value = aws_instance.k8s_node[0].private_ip
}

output "ssh_private_key" {
  value     = tls_private_key.pk.private_key_pem
  sensitive = true
}
