# status-page

A public status page served from a private S3 bucket through CloudFront. The page is static HTML that reads `status.json`, written by the monitor module, and refreshes every minute.

## Usage

```hcl
module "status_page" {
  source = "git::https://github.com/drcampbell-92/terraform-aws-platform-modules.git//modules/status-page?ref=v1.0.0"

  name_prefix = "uptime-dev"
  page_title = "Service status"
  force_destroy = true
}
```

Set `force_destroy = true` only in non-production environments.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name_prefix` | `string` | required | Prefix for every resource name |
| `page_title` | `string` | `Service status` | Page heading; letters, numbers, spaces, and `. , ' -` only |
| `price_class` | `string` | `PriceClass_100` | CloudFront price class |
| `force_destroy` | `bool` | `false` | Allows deleting the bucket while it holds files |

## Outputs

| Name | Description |
|---|---|
| `url` | Public HTTPS address of the page |
| `bucket_name` | Bucket name, passed to the monitor as `status_bucket_name` |
| `bucket_arn` | ARN of the bucket |
| `distribution_id` | CloudFront distribution ID, used for cache invalidations |
| `distribution_arn` | ARN of the distribution |

## Security design

- Block Public Access is fully enabled and ACLs are disabled with `BucketOwnerEnforced`.
- CloudFront reads the bucket through Origin Access Control. The bucket policy allows `s3:GetObject` only to the CloudFront service, and only for this distribution through `AWS:SourceArn`.
- Requests without TLS are denied, and viewers are redirected to HTTPS.
- The managed security headers policy adds browser protections such as HSTS.
- The page writes every value with `textContent`, so a target name cannot inject a script. The title is validated because the template inserts it as raw HTML.
- Objects are encrypted at rest with SSE-S3.

## Caching

The managed caching policy respects each file's `Cache-Control` header. `status.json` is cached for 60 seconds and `index.html` for 5 minutes.

## Known limitations

- No WAF and no access logging, to avoid their cost.
- No custom domain, which avoids a Route 53 hosted zone charge. The page uses the CloudFront address and its default certificate.
- No bucket versioning, by design: the status file is overwritten every few minutes, and versions would accumulate with no benefit.
- Distribution changes take several minutes to deploy.
