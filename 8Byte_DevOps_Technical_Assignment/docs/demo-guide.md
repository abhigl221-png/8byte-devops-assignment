# Loom demo guide (5-7 minutes)

1. **Frame the goal (30s).** “I chose EC2 plus Docker rather than EKS because it meets the required delivery and operating controls with lower cost and complexity for this assignment.”
2. **Architecture (60s).** Show the diagram in the README. Explain public ALB, private EC2 and isolated RDS; point out the security-group flow and no SSH.
3. **Infrastructure (60s).** Show the modular Terraform tree, the remote-state bootstrap configuration, and a real `terraform plan` only if you have run it. Never imply it was applied if it was not.
4. **Application and CI (90s).** Open `app/`, tests and Dockerfile. Show a real successful PR check if available: tests, pip-audit and Trivy. Explain immutable SHA tagging.
5. **Promotion (60s).** Show workflow jobs: automatic staging then protected production Environment. Explain that required reviewers perform the manual gate and SSM deploys the same SHA.
6. **Operations (60s).** Show your real CloudWatch dashboards and log group only if deployed. Call out CPU/memory/disk, ALB latency/errors, RDS connections/storage, and alarms.
7. **Close (30s).** Describe rollback to a previous SHA, backup restoration test, and two next improvements: ASG instance refresh/blue-green and Secrets Manager injection.

## Evidence checklist

Before recording, gather only genuine evidence: GitHub Actions URL, approved production Environment, ALB health, `/healthz`, dashboard screenshots, application logs, and RDS automated-backup settings. Replace all `CHANGE_ME` values. Do not include credentials in video or terminal output.
