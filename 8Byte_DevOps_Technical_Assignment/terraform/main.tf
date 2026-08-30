data "aws_availability_zones" "available" { state = "available" }

module "vpc" {
  source = "./modules/vpc"
  project = var.project
  environment = var.environment
  vpc_cidr = var.vpc_cidr
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "compute" {
  source = "./modules/compute"
  project = var.project
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_ami_id = var.ec2_ami_id
  instance_type = var.instance_type
  app_port = var.app_port
  acm_certificate_arn = var.acm_certificate_arn
}

module "rds" {
  source = "./modules/rds"
  project = var.project
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.db_subnet_ids
  app_security_group_id = module.compute.app_security_group_id
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  multi_az = var.rds_multi_az
}

module "monitoring" {
  source = "./modules/monitoring"
  project = var.project
  environment = var.environment
  alb_arn_suffix = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  asg_name = module.compute.asg_name
  db_identifier = module.rds.db_identifier
  alert_email = var.alert_email
}
