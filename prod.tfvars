# PROD: more powerful and more protected...
aws_region     = "ap-south-2" # Hyderabad (switch to "ap-south-1" for Mumbai)
environment    = "prod"
instance_count = 2

instance_type        = "t3.medium"
root_volume_size     = 30
enable_monitoring    = true
enable_s3_versioning = true

vpc_cidr           = "10.1.0.0/16"
public_subnet_cidr = "10.1.1.0/24"

# TODO: replace with your own public IP, e.g. "203.0.113.10/32"
allowed_ssh_cidr = "0.0.0.0/0"

# Final name becomes: utkarsh-text-storage-prod-<account-id>
bucket_prefix = "utkarsh-text-storage"
