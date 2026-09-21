# DEV: cheap and small  
aws_region     = "ap-south-1" # Mumbai
environment    = "dev"
instance_count = 1

instance_type        = "t3.micro"
root_volume_size     = 8
enable_monitoring    = false
enable_s3_versioning = false

vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# TODO: replace with your own public IP, e.g. "203.0.113.10/32"
allowed_ssh_cidr = "0.0.0.0/0"

# Final name becomes: utkarsh-text-storage-dev-<account-id>
bucket_prefix = "utkarsh-text-storage"
