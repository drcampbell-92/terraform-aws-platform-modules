# guardrails

Platform-wide safety limits for one environment: a permissions boundary that caps every role the platform creates, and a monthly budget with email alerts.

## Usage

```hcl
module "guardrails" {
  source = "git::https://github.com/drcampbell-92/terraform-aws-platform-modules.git//modules/guardrails?ref=v1.0.0"

  name_prefix = "uptime-dev"
  environment = "dev"
  monthly_budget_usd = 5
  budget_alert_emails = var.budget_alert_emails
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name_prefix` | `string` | required | Prefix for every resource name |
| `environment` | `string` | required | `dev` or `prod`; filters the budget by the `Environment` tag |
| `monthly_budget_usd` | `number` | `5` | Monthly spending limit in USD |
| `budget_alert_emails` | `list(string)` | required | Addresses that receive budget alerts; at least one |

## Outputs

| Name | Description |
|---|---|
| `permissions_boundary_arn` | ARN of the boundary, attached to every role the platform creates |
| `budget_name` | Name of the budget |

## Security design

- A role's effective permissions are the overlap of its own policies and its boundary, so a created role can never exceed this boundary, whatever is attached to it.
- The boundary allows only the actions the platform's roles use, on resources whose names start with the environment prefix. Dev roles cannot reach prod resources.
- It allows no IAM actions, so a role under it cannot create or modify roles. This blocks privilege escalation through the pipeline.

## Budget alerts

- An email when actual spending passes 80% of the limit.
- An email when forecast spending will pass 100%.

## Known limitations

- The budget's tag filter only works after `Environment` is activated as a cost allocation tag in the Billing console. AWS can take up to a day to show a new tag there.
- When a module gains a new permission, this boundary must allow it too, or the role is silently limited.
- Budget alerts are notifications only. They do not stop spending.
