variable "private_subnet_az1_id" {
  description = "The ID of the private subnet in AZ1 where ASG instances will run"
  type        = string
}

variable "private_subnet_az2_id" {
  description = "The ID of the private subnet in AZ2 where ASG instances will run"
  type        = string
}

variable "application_load_balancer" {
  description = "The ALB resource object (if needed for reference)"
  type        = any
}

variable "alb_target_group_arn" {
  description = "The ARN of the ALB target group to attach ASG instances"
  type        = string
}

variable "alb_security_group_id" {
  description = "The security group ID of the ALB, used to allow traffic into EC2"
  type        = string
}

variable "iam_ec2_instance_profile" {
  description = "IAM instance profile for EC2 instances in the ASG"
  type        = any
}

variable "project_name" {
  description = "Prefix for naming ASG-related resources"
  type        = string
}

variable "rds_db_endpoint" {
  description = "RDS database endpoint for application connection"
  type        = string
}
