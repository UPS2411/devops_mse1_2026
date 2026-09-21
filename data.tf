# -----------------------------
# Data blocks (lookups, nothing is created here)--
# -----------------------------

# 1. Latest Amazon Linux 2023 AMI in whichever region is being deployed to
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }



  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 2. Availability zones available in the current region
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# 3. Current AWS account ID (used to make the S3 bucket name globally unique)
data "aws_caller_identity" "current" {}

# 4. Trust policy: lets EC2 assume the IAM role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 5. Permissions policy: least-privilege access to the text bucket only
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.text_bucket.arn]
  }

  statement {
    sid       = "ReadWriteObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.text_bucket.arn}/*"]
  }
}
