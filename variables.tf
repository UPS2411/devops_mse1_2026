variable "aws_region" {
  description = "AWS region to deploy into (e.g. ap-south-1 for Mumbai, ap-south-2 for Hyderabad)"
  type        = string
}
variable "instance_count" {
  description = "number of Ec2 instances"
  type        = number

}

variable "environment" {
  description = "Environment name. Must match the active Terraform workspace."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either \"dev\" or \"prod\"."
  }
}

variable "project_name" {
  description = "Project name used in default tags"
  type        = string
  default     = "text-storage"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
}

variable "enable_monitoring" {
  description = "Enable detailed (1-minute) CloudWatch monitoring on the EC2 instance"
  type        = bool
  default     = false
}

variable "enable_s3_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to the instance (use your own IP, e.g. 203.0.113.10/32)"
  type        = string
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name. Environment and account ID are appended automatically."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}$", var.bucket_prefix))
    error_message = "bucket_prefix must be lowercase letters, numbers and hyphens (2-31 characters)."
  }
}
#end of file