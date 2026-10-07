data "aws_caller_identity" "current" {}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}

locals {
  bucket_name = "${var.name_prefix}-status-${data.aws_caller_identity.current.account_id}"
  origin_id   = "status-bucket"
  index_html  = templatefile("${path.module}/site/index.html.tftpl", { title = var.page_title })
}

resource "aws_s3_bucket" "status" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_public_access_block" "status" {
  bucket                  = aws_s3_bucket.status.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "status" {
  bucket = aws_s3_bucket.status.bucket

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "status" {
  bucket = aws_s3_bucket.status.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "status" {
  name                              = "${var.name_prefix}-status"
  description                       = "Lets the ${var.name_prefix} status page distribution read its bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "status" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix} status page"
  default_root_object = "index.html"
  price_class         = var.price_class

  origin {
    origin_id                = local.origin_id
    domain_name              = aws_s3_bucket.status.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.status.id
  }

  default_cache_behavior {
    target_origin_id           = local.origin_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "status" {
  bucket = aws_s3_bucket.status.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontRead"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.status.arn}/*"
        Condition = {
          StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.status.arn }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.status.arn, "${aws_s3_bucket.status.arn}/*"]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.status]
}

resource "aws_s3_object" "index" {
  bucket        = aws_s3_bucket.status.bucket
  key           = "index.html"
  content       = local.index_html
  content_type  = "text/html; charset=utf-8"
  cache_control = "max-age=300"
}