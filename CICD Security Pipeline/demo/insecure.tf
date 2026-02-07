# Intentionally insecure Terraform for IaC scanning demo
# These issues should be caught by Checkov

provider "aws" {
  region = "us-east-1"
}

# ISSUE: S3 bucket with public access (CKV_AWS_19, CKV_AWS_18)
resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-insecure-demo-bucket"
}

resource "aws_s3_bucket_public_access_block" "public_bucket" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ISSUE: S3 bucket without encryption (CKV_AWS_19)
# Missing: aws_s3_bucket_server_side_encryption_configuration

# ISSUE: S3 bucket without versioning (CKV_AWS_21)
# Missing: aws_s3_bucket_versioning

# ISSUE: S3 bucket without logging (CKV_AWS_18)
# Missing: aws_s3_bucket_logging

# ISSUE: Security group open to the world (CKV_AWS_24)
resource "aws_security_group" "wide_open" {
  name        = "wide-open-sg"
  description = "Intentionally insecure security group"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ISSUE: RDS without encryption (CKV_AWS_16)
resource "aws_db_instance" "unencrypted_db" {
  identifier        = "demo-unencrypted-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "admin"
  password          = "hardcoded-password-123"

  storage_encrypted   = false
  publicly_accessible = true
  skip_final_snapshot = true

  # ISSUE: No backup retention
  backup_retention_period = 0
}
