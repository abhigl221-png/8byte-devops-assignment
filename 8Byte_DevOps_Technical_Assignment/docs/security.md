# Security checklist

- [ ] State bucket is unique, encrypted, versioned, publicly blocked, and uses DynamoDB locking.
- [ ] `terraform.tfvars`, backend config and secrets are absent from Git history.
- [ ] GitHub production Environment requires a reviewer.
- [ ] OIDC role has no wildcard write access beyond necessary ECR/SSM actions.
- [ ] ACM certificate is attached and port 80 redirects to HTTPS before sharing a public URL.
- [ ] RDS is private, encrypted, has automated backups, deletion protection, and a tested restore procedure.
- [ ] EC2 has no SSH ingress and SSM session logging is enabled in the AWS account.
- [ ] Dependency and image scan findings are reviewed rather than blindly waived.
