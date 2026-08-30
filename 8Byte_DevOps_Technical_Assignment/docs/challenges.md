# Challenges and resolutions

## 1. Choosing a runtime without overengineering

**Challenge.** The scope mentioned EC2, ECS, or EKS. Kubernetes would demonstrate breadth but would consume time on a control plane and add cost unrelated to the core deployment and observability objectives.

**Resolution.** I selected Docker on an EC2 Auto Scaling Group behind an ALB. The result keeps the delivery artifact portable and gives health checks and scale-out capability, while preserving time for CI/CD, security and monitoring. ECS Fargate would be a sensible next managed-compute step if the service grows.

## 2. Private workloads need management access

**Challenge.** Private EC2 instances should not expose SSH or receive public IP addresses, but the pipeline still needs a secure deployment path.

**Resolution.** The design uses AWS Systems Manager and an instance role. The pipeline assumes AWS access with GitHub OIDC and sends deployment commands through SSM. Interface endpoints are included for SSM services; no inbound administrative port is opened.

## 3. Remote Terraform state must be safe for collaboration

**Challenge.** Local state can leak infrastructure metadata and causes conflicts when more than one operator runs Terraform.

**Resolution.** A separate bootstrap stack creates an encrypted, versioned, public-blocked S3 state bucket and DynamoDB lock table. Account-specific backend values are intentionally placeholders and ignored by Git.

## 4. Production promotion must be controlled

**Challenge.** An automatic production deployment after every merge carries unnecessary risk, and rebuilding during promotion can introduce a different artifact.

**Resolution.** The main-branch workflow publishes an immutable commit-SHA tag, deploys it to staging, then waits for required GitHub Environment approval before the same tag is deployed to production. A rollback is an explicit redeployment of the earlier SHA.

## 5. Observability must be useful, not just present

**Challenge.** AWS default EC2 metrics do not include memory or disk, while raw logs alone are hard to operate from.

**Resolution.** CloudWatch Agent configuration collects memory, disk, CPU, system logs, and Docker/app logs. Two dashboards answer different questions: infrastructure/database capacity and application/edge behavior. Alarms focus on actionable signals such as ALB 5XXs and RDS free storage.
