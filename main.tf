terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Generate a random suffix for unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name     = "${var.bucket_prefix}-${random_id.suffix.hex}"
  log_bucket_name = "${var.bucket_prefix}-logs-${random_id.suffix.hex}"
}

# -------------------------------------------------------------------------------------------------
# S3 Configuration for Logging Bucket
# -------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  bucket = local.log_bucket_name
  force_destroy = true # Allow destruction even if not empty
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rule for logs: Transition to Glacier > 30 days, Expire > 90 days
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "log-management"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
    expiration {
      days = 90
    }
  }
}

# Access control for logs delivery
# Modern approach uses Bucket Policy or ACL if ObjectOwnership is BucketOwnerPreferred
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}


# -------------------------------------------------------------------------------------------------
# S3 Configuration for Website Bucket
# -------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "website" {
  bucket        = aws_s3_bucket.website.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Public Read Policy
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  depends_on = [aws_s3_bucket_public_access_block.website]
  bucket     = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })
}

# -------------------------------------------------------------------------------------------------
# Upload Content
# -------------------------------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/www/index.html"
  content_type = "text/html"
  # Etag to detect changes
  etag = filemd5("${path.module}/www/index.html")
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  source       = "${path.module}/www/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/www/error.html")
}

# -------------------------------------------------------------------------------------------------
# Upload Secret File (to Private Log Bucket)
# -------------------------------------------------------------------------------------------------
resource "aws_s3_object" "secret" {
  bucket       = aws_s3_bucket.logs.id
  key          = "secret.txt"
  source       = "${path.module}/www/secret.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/www/secret.txt")
}

# -------------------------------------------------------------------------------------------------
# S3 Access Point: Auditor
# -------------------------------------------------------------------------------------------------
resource "aws_s3_access_point" "auditor" {
  bucket = aws_s3_bucket.logs.id
  name   = "${var.bucket_prefix}-auditor-${random_id.suffix.hex}"

  # Access Points are blocked from public by default, which is good.
}

resource "aws_s3_access_point_policy" "auditor" {
  access_point_arn = aws_s3_access_point.auditor.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAuditorReadLogs"
        Effect    = "Allow"
        Principal = { AWS = data.aws_caller_identity.current.account_id }
        Action    = ["s3:GetObject", "s3:ListBucket"]
        Resource  = [
          "${aws_s3_access_point.auditor.arn}",
          "${aws_s3_access_point.auditor.arn}/object/log/*"
        ]
      }
    ]
  })
}
