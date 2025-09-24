provider "aws" {
  region = var.region
}

# Create VPC
module "vpc" {
  source                  = "../modules/vpc"
  region                  = var.region
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_az1_cidr  = var.public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.public_subnet_az2_cidr
  private_subnet_az1_cidr = var.private_subnet_az1_cidr
  private_subnet_az2_cidr = var.private_subnet_az2_cidr
  secure_subnet_az1_cidr  = var.secure_subnet_az1_cidr
  secure_subnet_az2_cidr  = var.secure_subnet_az2_cidr
}

# Create NAT Gateway
module "natgateway" {
  source                = "../modules/natgateway"
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  internet_gateway      = module.vpc.internet_gateway
  vpc_id                = module.vpc.vpc_id
  private_subnet_az1_id = module.vpc.private_subnet_az1_id
  private_subnet_az2_id = module.vpc.private_subnet_az2_id
}

# Create Security Groups
module "security_group" {
  source = "../modules/security_group"
  vpc_id = module.vpc.vpc_id
}

# Create ALB
module "application_load_balancer" {
  source                = "../modules/alb"
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security_group.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
}

# Create EC2 (IAM role/profile etc.)
module "ec2" {
  source = "../modules/ec2"
  vpc_id = module.vpc.vpc_id
  region = var.region
}

# Create RDS
module "rds" {
  source                = "../modules/rds"
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.security_group.alb_security_group_id
  secure_subnet_az1_id  = module.vpc.secure_subnet_az1_id
  secure_subnet_az2_id  = module.vpc.secure_subnet_az2_id
}

# Create Auto Scaling Group (in private subnets)
module "asg" {
  source                    = "../modules/asg"
  project_name              = module.vpc.project_name
  rds_db_endpoint           = module.rds.rds_db_endpoint
  vpc_id                    = module.vpc.vpc_id
  private_subnet_az1_id     = module.vpc.private_subnet_az1_id
  private_subnet_az2_id     = module.vpc.private_subnet_az2_id
  application_load_balancer = module.application_load_balancer.application_load_balancer
  alb_target_group_arn      = module.application_load_balancer.alb_target_group_arn
  alb_security_group_id     = module.security_group.alb_security_group_id
  iam_ec2_instance_profile  = module.ec2.iam_ec2_instance_profile
}

# --- Outputs ---

output "application_load_balancer_dns_name" {
  description = "DNS name of the ALB"
  value       = module.application_load_balancer.application_load_balancer_dns_name
}

output "rds_db_endpoint" {
  description = "The RDS endpoint"
  value       = module.rds.rds_db_endpoint
}
