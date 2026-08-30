variable "aws_region" { type = string, default = "ap-south-1" }
variable "project" { type = string, default = "8byte" }
variable "environment" { type = string, default = "staging" }
variable "vpc_cidr" { type = string, default = "10.20.0.0/16" }
variable "ec2_ami_id" { type = string, description = "Amazon Linux 2023 AMI ID - CHANGE_ME" }
variable "instance_type" { type = string, default = "t3.micro" }
variable "app_port" { type = number, default = 8080 }
variable "acm_certificate_arn" { type = string, default = null, nullable = true }
variable "db_name" { type = string, default = "appdb" }
variable "db_username" { type = string, default = "appadmin" }
variable "db_password" { type = string, sensitive = true }
variable "rds_multi_az" { type = bool, default = false }
variable "alert_email" { type = string, description = "Email address to confirm SNS subscription" }
