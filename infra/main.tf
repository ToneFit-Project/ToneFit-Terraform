locals {
  tags = merge(var.tags, { Environment = var.environment })
}

module "vpc" {
  source = "./modules/vpc"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.tags
}

module "ec2" {
  source = "./modules/ec2"

  project          = var.project
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  instance_type    = var.ec2_instance_type
  key_pair_name    = var.ec2_key_pair_name
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  tags             = local.tags
}

module "rds" {
  source = "./modules/rds"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id
  instance_class        = var.rds_instance_class
  engine_version        = var.rds_engine_version
  db_name               = var.rds_db_name
  username              = var.rds_username
  password              = var.rds_password
  allocated_storage     = var.rds_allocated_storage
  tags                  = local.tags
}

module "secrets" {
  source = "./modules/secrets"

  project     = var.project
  environment = var.environment
  db_host     = module.rds.endpoint
  db_port     = module.rds.port
  db_name     = var.rds_db_name
  db_username = var.rds_username
  db_password = var.rds_password
  tags        = local.tags
}

module "frontend" {
  source = "./modules/frontend"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project     = var.project
  environment = var.environment
  domain_name = var.domain_name
  tags        = local.tags
}
