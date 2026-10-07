mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn                         = "arn:aws:s3:::uptime-test-status-123456789012"
      bucket_regional_domain_name = "uptime-test-status-123456789012.s3.us-east-1.amazonaws.com"
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      arn         = "arn:aws:cloudfront::123456789012:distribution/EMOCK123"
      domain_name = "dmock123.cloudfront.net"
    }
  }
}

variables {
  name_prefix = "uptime-test"
}

run "uses_naming_standard" {
  command = apply

  assert {
    condition     = aws_s3_bucket.status.bucket == "uptime-test-status-123456789012"
    error_message = "Bucket name must follow the uptime-<env>-status-<account> pattern."
  }
}

run "blocks_all_public_access" {
  command = apply

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.status.block_public_acls,
      aws_s3_bucket_public_access_block.status.block_public_policy,
      aws_s3_bucket_public_access_block.status.ignore_public_acls,
      aws_s3_bucket_public_access_block.status.restrict_public_buckets,
    ])
    error_message = "All four Block Public Access settings must be on."
  }
}

run "disables_acls" {
  command = apply

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.status.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled so only policies control access."
  }
}

run "grants_read_only_to_this_distribution" {
  command = apply

  assert {
    condition     = strcontains(aws_s3_bucket_policy.status.policy, "arn:aws:cloudfront::123456789012:distribution/EMOCK123")
    error_message = "Bucket access must be limited to this distribution."
  }

  assert {
    condition     = strcontains(aws_s3_bucket_policy.status.policy, "s3:GetObject")
    error_message = "CloudFront must be allowed to read objects."
  }

  assert {
    condition     = !strcontains(aws_s3_bucket_policy.status.policy, "s3:PutObject")
    error_message = "The bucket policy must not grant write access."
  }
}

run "denies_insecure_transport" {
  command = apply

  assert {
    condition     = strcontains(aws_s3_bucket_policy.status.policy, "aws:SecureTransport")
    error_message = "The bucket policy must deny requests without TLS."
  }
}

run "reads_bucket_through_origin_access_control" {
  command = apply

  assert {
    condition     = one(aws_cloudfront_distribution.status.origin).origin_access_control_id == aws_cloudfront_origin_access_control.status.id
    error_message = "The distribution must read the bucket through Origin Access Control."
  }
}

run "redirects_viewers_to_https" {
  command = apply

  assert {
    condition     = one(aws_cloudfront_distribution.status.default_cache_behavior).viewer_protocol_policy == "redirect-to-https"
    error_message = "Viewers must be redirected to HTTPS."
  }
}

run "rejects_unsafe_title" {
  command = plan

  variables {
    page_title = "<script>alert(1)</script>"
  }

  expect_failures = [var.page_title]
}