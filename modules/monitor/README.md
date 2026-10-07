# monitor

Checks a list of URLs on a schedule. EventBridge Scheduler runs a Python Lambda function, which records every result in DynamoDB, optionally writes the current results to a status file in S3, and optionally publishes failures to an SNS topic.

## Usage

```hcl
module "monitor" {
  source = "git::https://github.com/drcampbell-92/terraform-aws-platform-modules.git//modules/monitor?ref=v1.0.0"

  name_prefix = "uptime-dev"
  targets = {
    homepage = "https://example.com"
    docs = "https://docs.example.com"
  }

  alert_topic_arn = module.alerts.topic_arn
  status_bucket_name = module.status_page.bucket_name
  permissions_boundary_arn = module.guardrails.permissions_boundary_arn
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name_prefix` | `string` | required | Prefix for every resource name |
| `targets` | `map(string)` | required | Target names mapped to URLs; each must start with `http://` or `https://` |
| `schedule_expression` | `string` | `rate(5 minutes)` | EventBridge Scheduler rate or cron expression |
| `enabled` | `bool` | `true` | Set to `false` to pause checks without destroying anything |
| `check_timeout_seconds` | `number` | `5` | Seconds to wait for each URL, from 1 to 30 |
| `result_retention_days` | `number` | `7` | Days before DynamoDB deletes a result automatically |
| `log_retention_days` | `number` | `7` | Days to keep the function's logs |
| `enable_point_in_time_recovery` | `bool` | `false` | Turns on point-in-time recovery for the results table |
| `alert_topic_arn` | `string` | `null` | SNS topic for failures; `null` disables alerts |
| `status_bucket_name` | `string` | `null` | Bucket for the status file; `null` disables it |
| `status_object_key` | `string` | `status.json` | Key of the status file |
| `permissions_boundary_arn` | `string` | `null` | Boundary attached to both roles this module creates |

## Outputs

| Name | Description |
|---|---|
| `function_name` | Name of the checker function |
| `function_arn` | ARN of the checker function |
| `role_arn` | ARN of the checker's execution role, for resource policies that grant it access |
| `table_name` | Name of the results table |
| `table_arn` | ARN of the results table |
| `schedule_name` | Name of the EventBridge schedule |

## Security design

- The checker role gets `dynamodb:PutItem` on its own table and log permissions on its own log group. `sns:Publish` and `s3:PutObject` are added only when `alert_topic_arn` or `status_bucket_name` is set, and each is scoped to that one topic or that one object key.
- The scheduler role can invoke only this function, and its trust policy requires `aws:SourceAccount` to match the account, which prevents the confused deputy problem.
- Both roles accept a permissions boundary.
- Results expire through DynamoDB TTL, so old rows are deleted at no cost.

## Known limitations

- Checks run one after another, so the function timeout grows with the number of targets.
- A target that stays down sends an alert on every run. There is no deduplication yet.
- There is no reserved concurrency, because some accounts' concurrency quotas reject it.
- Checks run from a single region.
