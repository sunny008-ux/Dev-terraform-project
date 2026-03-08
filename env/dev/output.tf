# Master node outputs
output "master_public_ip" {
  description = "Public IP of Kubernetes master node"
  value       = module.ec2_instance_1.public_ip
}

output "master_private_ip" {
  description = "Private IP of Kubernetes master node"
  value       = module.ec2_instance_1.private_ip
}

# Worker 1 outputs
output "worker1_public_ip" {
  description = "Public IP of worker node 1"
  value       = module.ec2_instance_2.public_ip
}

output "worker1_private_ip" {
  description = "Private IP of worker node 1"
  value       = module.ec2_instance_2.private_ip
}

# Worker 2 outputs
output "worker2_public_ip" {
  description = "Public IP of worker node 2"
  value       = module.ec2_instance_3.public_ip
}

output "worker2_private_ip" {
  description = "Private IP of worker node 2"
  value       = module.ec2_instance_3.private_ip
}