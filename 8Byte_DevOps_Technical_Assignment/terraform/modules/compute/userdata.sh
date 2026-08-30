#!/bin/bash
set -euxo pipefail
dnf update -y
dnf install -y docker amazon-cloudwatch-agent
systemctl enable --now docker amazon-ssm-agent
usermod -aG docker ec2-user
# CI deploys a signed-by-SHA ECR image through SSM after the instance is healthy.
