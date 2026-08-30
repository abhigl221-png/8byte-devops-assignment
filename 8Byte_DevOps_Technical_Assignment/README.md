# 8Byte.ai DevOps Technical Assignment

> **Submission note:** This repository is an implementation package. It has not been applied to an AWS account. Values shown as `CHANGE_ME` must be configured by the candidate before use; screenshots, URLs, and metrics must be captured only after a real deployment.

## What this implements

A small Flask service is packaged in Docker and deployed to an Auto Scaling Group of EC2 instances behind an Application Load Balancer. PostgreSQL is private in RDS. GitHub Actions tests, scans and publishes images; staging deploys after a main-branch build, while production uses GitHub Environment approval. CloudWatch receives application, system and ALB access logs and supplies two importable dashboards.

```mermaid
flowchart LR
  U[Internet] --> ALB[Public ALB]
  ALB --> EC2[Private EC2 Auto Scaling Group]
  EC2 --> RDS[(Private RDS PostgreSQL)]
  EC2 --> CW[CloudWatch Logs & Metrics]
  GH[GitHub Actions] --> ECR[ECR]
  GH --> SSM[SSM Run Command]
  SSM --> EC2
  CW --> DB[CloudWatch Dashboards]
```

## Design decisions

EC2 keeps this assignment focused and economical: Docker gives portable deployments while an ALB, Launch Template and Auto Scaling Group demonstrate an upgrade path to multiple instances. EKS would add control-plane cost and operational work that is disproportionate to a 9-12 hour exercise. RDS is in isolated subnets, is not publicly accessible, and only accepts PostgreSQL traffic from the application security group. The ALB is the only internet-facing workload.

## Repository map

| Path | Purpose |
| --- | --- |
| `app/` | Dockerized Flask health/API service and tests |
| `terraform/bootstrap/` | One-time encrypted remote-state bucket + DynamoDB lock table |
| `terraform/` | VPC, ALB/EC2, RDS, logging, dashboards and alarms |
| `.github/workflows/` | Pull-request checks and build/deploy promotion pipeline |
| `monitoring/` | CloudWatch Agent and dashboard source JSON |
| `docs/` | architecture rationale, security and demo guide |

## Prerequisites

* AWS account with permissions to create the listed resources, an S3 bucket region, and a GitHub repository.
* Terraform >= 1.6, Docker, AWS CLI, and a GitHub OIDC provider configured in AWS.
* A GitHub Environment named `production` with required reviewers. This is the production approval gate.

## Configure and provision

1. Copy `terraform/bootstrap/terraform.tfvars.example` to `terraform.tfvars`; set a globally unique state bucket name and run `terraform init && terraform apply` in `terraform/bootstrap`.
2. Copy `terraform/backend.hcl.example` to `backend.hcl`; replace `CHANGE_ME_STATE_BUCKET`, region, and key. Do not commit this file if it contains account-specific names.
3. Copy `terraform/terraform.tfvars.example` to `terraform.tfvars`; set `project`, `environment`, `db_name`, `db_username`, a strong `db_password`, `alert_email`, and your existing `ec2_ami_id` (Amazon Linux 2023). Do not commit secrets.
4. From `terraform/`, run `terraform init -backend-config=backend.hcl`, `terraform fmt -recursive`, `terraform validate`, then `terraform plan -out=tfplan`. Review the plan before `terraform apply tfplan`.
5. Note outputs for ECR repository, load balancer DNS and instance role. Configure GitHub repository variables/secrets below.

### Required GitHub configuration

| Name | Type | Value |
| --- | --- | --- |
| `AWS_ROLE_ARN` | repository secret | OIDC role ARN with narrowly scoped ECR/SSM permissions |
| `AWS_REGION` | repository variable | target AWS region |
| `ECR_REPOSITORY` | repository variable | Full Terraform `ecr_repository_url` (for example, `ACCOUNT.dkr.ecr.REGION.amazonaws.com/8byte-staging-app`) |
| `STAGING_INSTANCE_IDS` | repository variable | comma-separated SSM-managed EC2 IDs |
| `PRODUCTION_INSTANCE_IDS` | repository variable | comma-separated SSM-managed EC2 IDs |
| `APP_PORT` | repository variable | `8080` unless changed |

The workflow deliberately accepts instance IDs as configuration rather than guessing them. For a production rollout, replace this with an ASG instance refresh or blue/green strategy.

## Local development and tests

```bash
cd app
python -m venv .venv
. .venv/bin/activate                 # Windows: .venv\\Scripts\\Activate.ps1
pip install -r requirements-dev.txt
pytest -q
docker build -t 8byte-app:local .
docker run --rm -p 8080:8080 8byte-app:local
curl http://localhost:8080/healthz
```

For an integration check with PostgreSQL, set `DATABASE_URL=postgresql+psycopg://app:app@localhost:5432/app` and start a local PostgreSQL container, then run `pytest -m integration`. The unit suite does not need AWS or a database.

## CI/CD controls

* Every pull request runs formatting, unit tests, an optional database-backed integration suite, `pip-audit`, Docker build, and Trivy filesystem/container scans.
* A merge to `main` repeats tests/scans, pushes an immutable commit-SHA tag to ECR, then deploys staging through SSM.
* The `production` job requires GitHub Environment approval and deploys the exact same SHA tag, never rebuilding a different artifact.
* Failed jobs emit GitHub workflow status. The deploy script emits an EventBridge-compatible failure event; route this to SNS/Slack/PagerDuty as documented in `docs/architecture.md`.

## Monitoring, logging, and alerting

CloudWatch Agent collects CPU, memory, disk and process metrics plus `/var/log/messages`, Docker logs and app logs. The application writes structured JSON to stdout; the agent forwards it to `/8byte/<environment>/application`. ALB access logs are retained in a dedicated S3 bucket with lifecycle expiry. RDS and ALB metrics are surfaced in two dashboards:

1. **Infrastructure & database:** EC2 CPU/memory/disk, RDS CPU, connections and free storage.
2. **Application & edge:** ALB request count, target latency, 4XX/5XX errors and healthy host count.

Alarms notify `alert_email` for ALB 5XXs, unhealthy targets, RDS free storage, and EC2 CPU. Confirm the SNS subscription email after apply.

## Security and resilience

* No SSH ingress; administrative access is through SSM Session Manager. EC2 has an SSM role, not static keys.
* GitHub uses OIDC (short-lived credentials), not long-lived AWS access keys.
* TLS listener/certificate are deliberately parameterized: set `acm_certificate_arn` to enable HTTPS; HTTP is redirected to HTTPS then. Do not expose a real workload over HTTP.
* RDS storage, logs, ECR, state and ALB log bucket are encrypted. Terraform state uses an encrypted S3 bucket, versioning, public-access block, and DynamoDB locking.
* Store the database password in AWS Secrets Manager for a real deployment. The sample uses a sensitive Terraform variable only to keep the assignment self-contained; it is never safe to commit it.
* RDS has 7-day automated backups, deletion protection, final snapshot, Multi-AZ toggle and maintenance window controls. Test restores before treating backup as recovery.

## Cost controls

The default uses one `t3.micro` EC2 instance, small `db.t4g.micro` RDS, 7-day logs and a 14-day ALB-log lifecycle. Disable production or destroy non-production environments when not demonstrating. NAT Gateways are intentionally not created: private EC2 uses SSM VPC endpoints and ECR endpoints; add a NAT Gateway only when the application needs general internet egress.

## Teardown

Run `terraform destroy` only after preserving any required RDS final snapshot. Empty the ALB log bucket manually if lifecycle retention prevents destroy. Keep the state bucket until all managed environments are removed.

## Evidence to include in your submission

After deployment, capture your own screenshots of the successful Actions run, approved production job, ALB target health, CloudWatch dashboards, log stream, RDS backup configuration, and application `/healthz` response. Do not add invented screenshots or metrics.

See [docs/demo-guide.md](docs/demo-guide.md) for a concise Loom script and [docs/challenges.md](docs/challenges.md) for the editable source of the challenges document.
