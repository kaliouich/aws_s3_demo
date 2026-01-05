variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 buckets to ensure uniqueness"
  type        = string
  default     = "s3-demo-journey"
}
