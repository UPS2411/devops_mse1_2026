terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Applied automatically to every taggable resource..
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# -----------------------------
# VPC  
# -----------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }

  # Safety guard: the tfvars environment must match the active workspace,
  # so prod values can never be applied from the dev workspace (and vice versa).
  lifecycle {
    precondition {
      condition     = var.environment == terraform.workspace
      error_message = "var.environment (${var.environment}) does not match the active workspace (${terraform.workspace}). Run 'terraform workspace select ${var.environment}' first."
    }
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# -----------------------------
# Public Subnet
# -----------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# -----------------------------
# Route Table
# -----------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------
# Security Group
# -----------------------------

resource "aws_security_group" "ec2" {
  name        = "${var.environment}-ec2-sg"
  description = "Security group for Nginx web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-ec2-sg"
  }
}

# -----------------------------
# S3 Bucket
# -----------------------------

resource "aws_s3_bucket" "text_bucket" {
  # Account ID comes from a data block, so no hardcoded suffix is needed
  bucket = "${var.bucket_prefix}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.environment}-text-storage"
  }
}

resource "aws_s3_bucket_public_access_block" "text_bucket" {
  bucket = aws_s3_bucket.text_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "text_bucket" {
  bucket = aws_s3_bucket.text_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning is enabled only where var.enable_s3_versioning = true (prod)
resource "aws_s3_bucket_versioning" "text_bucket" {
  count  = var.enable_s3_versioning ? 1 : 0
  bucket = aws_s3_bucket.text_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------
# IAM Role for EC2
# -----------------------------

resource "aws_iam_role" "ec2_role" {
  name               = "${var.environment}-ec2-s3-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.environment}-ec2-s3-role"
  }
}

# -----------------------------
# IAM Policy (S3 access)
# -----------------------------

resource "aws_iam_role_policy" "s3_policy" {
  name   = "${var.environment}-s3-policy"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# -----------------------------
# Instance Profile
# -----------------------------

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# -----------------------------
# EC2
# -----------------------------

resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  monitoring                  = var.enable_monitoring

  # Require IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  # Script lives in its own file; Terraform fills in the bucket and region
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    bucket_name = aws_s3_bucket.text_bucket.bucket
    aws_region  = var.aws_region
  })

  # Editing the script recreates the instance so the change actually runs
  user_data_replace_on_change = true

  depends_on = [aws_iam_role_policy.s3_policy]

  tags = {
    Name = "${var.environment}-web-server"
  }
}
