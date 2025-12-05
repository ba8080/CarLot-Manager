output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "instance_ips" {
  description = "Public IPs of all K8s nodes (master + workers)"
  value       = aws_instance.k8s_node[*].public_ip
}

output "master_ip" {
  description = "Public IP of the master node"
  value       = aws_instance.k8s_node[0].public_ip
}

output "worker_ips" {
  description = "Public IPs of worker nodes"
  value       = slice(aws_instance.k8s_node[*].public_ip, 1, length(aws_instance.k8s_node))
}

output "master_private_ip" {
  description = "Private IP of the master node"
  value       = aws_instance.k8s_node[0].private_ip
}

output "ssh_private_key" {
  description = "Private SSH key for accessing instances"
  value       = tls_private_key.pk.private_key_pem
  sensitive   = true
}
