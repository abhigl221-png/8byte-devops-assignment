output "load_balancer_dns_name" { value = module.compute.alb_dns_name }
output "ecr_repository_url" { value = module.compute.ecr_repository_url }
output "rds_endpoint" { value = module.rds.endpoint, sensitive = true }
output "ssm_instance_role_name" { value = module.compute.instance_role_name }
