output "website_endpoint" {
  description = "The public URL of the static website"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "website_bucket_name" {
  description = "Name of the website bucket"
  value       = aws_s3_bucket.website.id
}

output "log_bucket_name" {
  description = "Name of the log bucket"
  value       = aws_s3_bucket.logs.id
}

output "secret_file_direct_url" {
  description = "Direct HTTPS URL to the secret file (Expected: 403 Forbidden)"
  value       = "https://${aws_s3_bucket.logs.bucket_regional_domain_name}/secret.txt"
}

output "s3_presign_command" {
  description = "Run this command to generate a pre-signed URL for the secret file"
  value       = "aws s3 presign s3://${aws_s3_bucket.logs.id}/secret.txt --expires-in 300"
}

output "auditor_access_point_arn" {
  description = "ARN of the Auditor Access Point"
  value       = aws_s3_access_point.auditor.arn
}

output "auditor_access_command" {
  description = "Try to list files using the Access Point (Restricted view)"
  # Access Points use the format arn:aws:s3:region:account-id:accesspoint/name
  value       = "aws s3 ls s3://${aws_s3_access_point.auditor.arn}/log/"
}
