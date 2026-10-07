output "url" {
  description = "Public HTTPS address of the status page"
  value       = "https://${aws_cloudfront_distribution.status.domain_name}"
}

output "bucket_name" {
  description = "Bucket holding the page, passed to the monitor as its status bucket"
  value       = aws_s3_bucket.status.bucket
}

output "bucket_arn" {
  description = "ARN of the status page bucket"
  value       = aws_s3_bucket.status.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID, used for cache invalidations"
  value       = aws_cloudfront_distribution.status.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.status.arn
}