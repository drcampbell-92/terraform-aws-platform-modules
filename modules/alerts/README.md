# alerts

An encrypted SNS topic for failure notifications, with one email subscription per address and a topic policy that lets only listed roles publish.

## Usage

```hcl
module "alerts" {
  source = "git::https://github.com/drcampbell-92/terraform-aws-platform-modules.git//modules/alerts?ref=v1.0.0"

  name_prefix = "uptime-dev"
  allowed_publisher_arns = [module.monitor.role_arn]
  email_addresses = var.alert_emails
}
```

Keep email addresses in a Git-ignored `terraform.tfvars`, not in committed code.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name_prefix` | `string` | required | Prefix for every resource name |
| `allowed_publisher_arns` | `list(string)` | required | IAM role ARNs allowed to publish; at least one |
| `email_addresses` | `list(string)` | `[]` | Addresses that receive alerts |
| `kms_master_key_id` | `string` | `alias/aws/sns` | KMS key that encrypts the topic at rest |

## Outputs

| Name | Description |
|---|---|
| `topic_arn` | ARN of the topic, passed to the monitor module |
| `topic_name` | Name of the topic |

## Security design

- The topic policy denies publishing without TLS, allows the listed roles, and explicitly denies every other principal through `aws:PrincipalArn`. An explicit deny overrides any allow, so not even an administrator can publish.
- A topic cannot be created without naming its publishers, because `allowed_publisher_arns` has no default.
- Subscriptions use `for_each`, so removing one address removes only that subscription.

## Known limitations

- Each email address must confirm its subscription from the email AWS sends. Terraform cannot confirm it.
- The AWS managed SNS key works for publishers with IAM permission, such as Lambda. CloudWatch alarms and some other AWS services cannot publish to a topic that uses it; those would need a customer managed key.
- Publishers must be IAM principals. Allowing an AWS service to publish would need a new statement.
