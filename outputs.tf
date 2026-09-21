output "workspace" {
  description = "Active Terraform workspace"
  value       = terraform.workspace
}

output "instance_count" {
  description = "Number of EC2 instances"
  value       = var.instance_count
}

output "region" {
  description = "AWS region deployed to"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "availability_zone" {
  description = "Availability zone chosen by the data block"
  value       = aws_subnet.public.availability_zone
}

output "ami_id" {
  description = "AMI ID resolved by the data block"
  value       = data.aws_ami.al2023.id
}

# output "ec2_instance_id" {
#   description = "EC2 instance ID"
#   value       = aws_instance.web.id
# }
##...
# output "ec2_public_ip" {
#   description = "EC2 public IP"
#   value       = aws_instance.web.public_ip
# }

# output "website_url" {
#   description = "Website URL"
#   value       = "http://${aws_instance.web.public_ip}"
# }

output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "ec2_public_ips" {
  description = "EC2 public IPs"
  value       = aws_instance.web[*].public_ip
}

output "website_urls" {
  description = "Website URLs"
  value = [
    for instance in aws_instance.web :
    "http://${instance.public_ip}"
  ]
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.text_bucket.bucket
}
