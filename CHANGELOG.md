# Changelog

All notable changes to these modules are recorded here. Versions follow semantic versioning.

## v1.0.0

First release.

### Added

- `monitor`: scheduled URL checks with results in DynamoDB, an optional status file, optional failure alerts, and least-privilege roles that accept a permissions boundary.
- `alerts`: encrypted SNS topic with email subscriptions and a policy that allows only listed publishers.
- `status-page`: private S3 bucket served through CloudFront with Origin Access Control and security headers.
- `guardrails`: workload permissions boundary and a monthly budget filtered by environment.
- Tests for every module using `terraform test` with mock providers.
- Pipeline running formatting, validation, and tests on pull requests.
