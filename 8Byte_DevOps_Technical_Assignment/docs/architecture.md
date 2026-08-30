# Architecture and operating model

## Network path

The VPC has two public ALB subnets, two private application subnets, and two isolated database subnets across two Availability Zones. The ALB accepts 80/443; EC2 accepts only the app port from the ALB; RDS accepts 5432 only from EC2. No inbound SSH rule exists. EC2 uses Systems Manager rather than a bastion host.

The initial Auto Scaling Group is deliberately a single instance to fit the assignment budget. Its target group health check is `/healthz`. For higher availability, set desired/minimum capacity to two, enable `rds_multi_az`, use HTTPS, and introduce an ASG instance refresh or blue/green deployment.

## Delivery and rollback

Pull requests are blocked on tests and vulnerability scans. A main build publishes immutable image tag `GITHUB_SHA`; staging and production both pull that exact tag. Production is paused by GitHub Environment required reviewers. The least-risk rollback is to rerun the SSM deployment command with the prior known-good SHA, then verify target health and `/healthz`.

For notification, GitHub checks provide immediate workflow feedback. A production version should add an EventBridge rule for failed SSM commands and failed CodePipeline/GitHub workflow webhooks, delivering an SNS topic that is bridged to Slack/PagerDuty. This package does not claim such a notification target has been configured.

## Secrets

Use AWS Secrets Manager for database credentials and grant the EC2 role read permission to exactly that secret. Pass the secret ARN, not the secret text, through Terraform. The supplied `db_password` variable remains only as an assignment-friendly placeholder and is sensitive, not safe for source control or a CI variable. GitHub must use OIDC with a role constrained to the ECR repository and permitted SSM document/instance targets.

## Logging and retention

App stdout and system logs are sent to CloudWatch Logs by the supplied agent configuration. ALB access logs should be enabled to an encrypted S3 bucket with a 14-day lifecycle for a small assignment account. RDS PostgreSQL logs are exported to CloudWatch. Set explicit log retention for all production groups and restrict CloudWatch Logs access through IAM.
