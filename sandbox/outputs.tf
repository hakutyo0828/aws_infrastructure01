output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}

output "instance_id" {
  value       = aws_instance.ec2.id
  description = "EC2 instance ID"
}

output "instance_public_ip" {
  value       = aws_instance.ec2.public_ip
  description = "EC2 instance public IP"
}

output "instance_public_dns" {
  value       = aws_instance.ec2.public_dns
  description = "EC2 instance public DNS"
}

