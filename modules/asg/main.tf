variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
}

# variable "private_subnet_az1_id" {
#   description = "The ID of the private subnet in AZ1"
#   type        = string
# }

# variable "private_subnet_az2_id" {
#   description = "The ID of the private subnet in AZ2"
#   type        = string
# }

# variable "project_name" {
#   description = "Project name prefix"
#   type        = string
# }

# variable "alb_security_group_id" {
#   description = "The security group ID of the ALB"
#   type        = string
# }

# variable "alb_target_group_arn" {
#   description = "The ARN of the ALB target group"
#   type        = string
# }

# variable "iam_ec2_instance_profile" {
#   description = "IAM instance profile for EC2"
#   type        = any
# }

# variable "rds_db_endpoint" {
#   description = "RDS database endpoint"
#   type        = string
# }

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.project_name}-ec2-sg-"   # ✅ ensures unique SG name
  description = "Allow inbound traffic from ALB on 8080"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  security_groups = [var.alb_security_group_id]  
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # allow all outbound
  }
}


resource "aws_launch_template" "ec2_asg" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = var.iam_ec2_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.root}/userdata.sh", {
    mysql_url = var.rds_db_endpoint
  }))

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "${var.project_name}-asg"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  force_delete        = true
  health_check_type   = "EC2"
  target_group_arns   = [var.alb_target_group_arn]   # attach to ALB TG
  vpc_zone_identifier = [
    var.private_subnet_az1_id,
    var.private_subnet_az2_id
  ]

  launch_template {
    id      = aws_launch_template.ec2_asg.id
    version = aws_launch_template.ec2_asg.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ec2"
    propagate_at_launch = true
  }

  # ✅ New: force rolling replacement when launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }
}
