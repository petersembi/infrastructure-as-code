terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "default"
}

# VPC
resource "aws_vpc" "vivaldi_vpc" {
  cidr_block = "192.168.0.0/24"  # 256 IPs

  tags = {
    Name = "Vivaldi-VPC"
  }
}

# Public Subnet
resource "aws_subnet" "vivaldi_public_subnet_1" {
  vpc_id            = aws_vpc.vivaldi_vpc.id
  cidr_block        = "192.168.0.0/28"  # 16 IPs
  availability_zone = "us-west-2a"

  tags = {
    Name = "Vivaldi-PublicSubnet-1"
  }
}

resource "aws_subnet" "vivaldi_public_subnet_2" {
  vpc_id            = aws_vpc.vivaldi_vpc.id
  cidr_block        = "192.168.0.16/28"  # 16 IPs
  availability_zone = "us-west-2b"

  tags = {
    Name = "Vivaldi-PublicSubnet-2"
  }
}

resource "aws_subnet" "vivaldi_public_subnet_3" {
  vpc_id            = aws_vpc.vivaldi_vpc.id
  cidr_block        = "192.168.0.32/28"  # 16 IPs
  availability_zone = "us-west-2c"

  tags = {
    Name = "Vivaldi-PublicSubnet-3"
  }
}

# Private Subnets
resource "aws_subnet" "vivaldi_private_subnet_1" {
  vpc_id            = aws_vpc.vivaldi_vpc.id
  cidr_block        = "192.168.0.48/28"  # 16 IPs
  availability_zone = "us-west-2a"

  tags = {
    Name = "Vivaldi-PrivateSubnet-1"
  }
}

resource "aws_subnet" "vivaldi_private_subnet_2" {
  vpc_id            = aws_vpc.vivaldi_vpc.id
  cidr_block        = "192.168.0.64/28"  # 16 IPs
  availability_zone = "us-west-2b"

  tags = {
    Name = "Vivaldi-PrivateSubnet-2"
  }
}

resource "aws_subnet" "vivaldi_private_subnet_3" {
  vpc_id            = aws_vpc.vivaldi_vpc.id
  cidr_block        = "192.168.0.80/28"  # 16 IPs
  availability_zone = "us-west-2c"

  tags = {
    Name = "Vivaldi-PrivateSubnet-3"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "vivaldi_db_subnet_group" {
  name       = "vivaldi-db-subnet-group"
  subnet_ids = [
    aws_subnet.vivaldi_private_subnet_1.id,
    aws_subnet.vivaldi_private_subnet_2.id,
    aws_subnet.vivaldi_private_subnet_3.id
  ]

  tags = {
    Name = "Vivaldi-DB-Subnet-Group"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "vivaldi_ig" {
  vpc_id = aws_vpc.vivaldi_vpc.id

  tags = {
    Name = "Vivaldi-IG"
  }
}

# Public Route Table
resource "aws_route_table" "vivaldi_public_rt" {
  vpc_id = aws_vpc.vivaldi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vivaldi_ig.id
  }

  tags = {
    Name = "Vivaldi-PublicRT"
  }
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.vivaldi_public_subnet_1.id
  route_table_id = aws_route_table.vivaldi_public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.vivaldi_public_subnet_2.id
  route_table_id = aws_route_table.vivaldi_public_rt.id
}

resource "aws_route_table_association" "public_subnet_3_association" {
  subnet_id      = aws_subnet.vivaldi_public_subnet_3.id
  route_table_id = aws_route_table.vivaldi_public_rt.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "vivaldi_nat_eip" {
  domain = "vpc" 
}

# NAT Gateway
resource "aws_nat_gateway" "vivaldi_nat" {
  allocation_id = aws_eip.vivaldi_nat_eip.id
  subnet_id     = aws_subnet.vivaldi_public_subnet_1.id  # Updated to a specific public subnet

  tags = {
    Name = "Vivaldi-NAT-Gateway"
  }
}


# Private Route Table
resource "aws_route_table" "vivaldi_private_rt" {
  vpc_id = aws_vpc.vivaldi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vivaldi_nat.id
  }

  tags = {
    Name = "Vivaldi-PrivateRT"
  }
}

# Route Table Association for Private Subnets
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.vivaldi_private_subnet_1.id
  route_table_id = aws_route_table.vivaldi_private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.vivaldi_private_subnet_2.id
  route_table_id = aws_route_table.vivaldi_private_rt.id
}

resource "aws_route_table_association" "private_subnet_3_association" {
  subnet_id      = aws_subnet.vivaldi_private_subnet_3.id
  route_table_id = aws_route_table.vivaldi_private_rt.id
}
# Elastic IP for Frontend EC2 Instance
resource "aws_eip" "vivaldi_frontend_eip" {
  instance = aws_instance.vivaldi_frontend.id
  domain = "vpc" 
}

# Jumpbox (Bastion Host) EC2 Instance in Public Subnet
resource "aws_instance" "vivaldi_jumpbox" {
  ami                    = "ami-04dd23e62ed049936"  # Specify an appropriate, secure AMI
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.vivaldi_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.vivaldi_jumpbox_sg.id]

  associate_public_ip_address = true
  key_name                    = "vivaldi_key"  # Specify your SSH key here

  tags = {
    Name = "Vivaldi-Jumpbox"
  }
}

# Security Group for Jumpbox
resource "aws_security_group" "vivaldi_jumpbox_sg" {
  vpc_id = aws_vpc.vivaldi_vpc.id
  name   = "vivaldi-jumpbox-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict SSH access to your trusted IP or range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Vivaldi-JumpboxSG"
  }
}


# Frontend Security Group
resource "aws_security_group" "vivaldi_frontend_sg" {
  vpc_id = aws_vpc.vivaldi_vpc.id
  name   = "vivaldi-frontend-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to a specific IP or CIDR block for more security
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Vivaldi-FrontendSG"
  }
}

# Backend Security Group
resource "aws_security_group" "vivaldi_backend_sg" {
  vpc_id = aws_vpc.vivaldi_vpc.id
  name   = "vivaldi-backend-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"] # Change this to a specific IP or CIDR block for more security
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Vivaldi-BackendSG"
  }
}

# MySQL Security Group
resource "aws_security_group" "vivaldi_mysql_sg" {
  vpc_id = aws_vpc.vivaldi_vpc.id
  name   = "vivaldi-mysql-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"] # Change this to a specific IP or CIDR block for more security
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.48/28", "192.168.0.64/28", "192.168.0.80/28"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Vivaldi-MySQL-SG"
  }
}

# Application Load Balancer
resource "aws_lb" "vivaldi_alb" {
  name               = "vivaldi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vivaldi_frontend_sg.id]
  subnets            = [
    aws_subnet.vivaldi_public_subnet_1.id,
    aws_subnet.vivaldi_public_subnet_2.id,
    aws_subnet.vivaldi_public_subnet_3.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "Vivaldi-ALB"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "vivaldi_target_group" {
  name     = "vivaldi-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vivaldi_vpc.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name = "Vivaldi-Target-Group"
  }
}

resource "aws_lb_listener" "vivaldi_listener" {
  load_balancer_arn = aws_lb.vivaldi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.vivaldi_target_group.arn
  }
}

# Aurora RDS Cluster
resource "aws_rds_cluster" "vivaldi_aurora_cluster" {
  cluster_identifier      = "vivaldi"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.05.2" # Specify the latest 8.0 compatible version available if needed
  master_username         = var.db_username
  master_password         = var.db_password
  database_name           = var.db_name
  availability_zones      = ["us-west-2b", "us-west-2c"]  # Multi-AZ deployment
  db_subnet_group_name    = aws_db_subnet_group.vivaldi_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.vivaldi_mysql_sg.id] # Use the MySQL SG for access control

  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"

    tags = {
    Name = "Vivaldi-Aurora-Cluster"
  }
}

resource "aws_rds_cluster_instance" "vivaldi_aurora_instance" {
  count                    = 2
  identifier               = "vivaldi-instance-${count.index}"
  cluster_identifier       = aws_rds_cluster.vivaldi_aurora_cluster.id
  instance_class           = "db.t3.medium"
  engine                   = "aurora-mysql"
  engine_version           = aws_rds_cluster.vivaldi_aurora_cluster.engine_version
  publicly_accessible      = false

  # Multi-AZ Deployment
  availability_zone        = element(["us-west-2b", "us-west-2c"], count.index)

}

# Frontend EC2 Instance
resource "aws_instance" "vivaldi_frontend" {
  ami                    = "ami-04dd23e62ed049936"
  instance_type          = "t3.medium"
  associate_public_ip_address = true
  subnet_id              = aws_subnet.vivaldi_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.vivaldi_frontend_sg.id]
  

  # User Data for nginx Installation
  # Load the script from the template file
  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {})

  key_name = "vivaldi_key"  # Specify your SSH key here

  tags = {
    Name = "Vivaldi-Frontend"
  }
}

# Associate Elastic IP with the Frontend EC2 Instance
resource "aws_eip_association" "frontend_eip_association" {
  instance_id   = aws_instance.vivaldi_frontend.id
  allocation_id = aws_eip.vivaldi_frontend_eip.id
}

# Backend EC2 Instance
resource "aws_instance" "vivaldi_backend" {
  ami                    = "ami-04dd23e62ed049936"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.vivaldi_private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.vivaldi_backend_sg.id]

  key_name = "vivaldi_key"  # Specify your SSH key here

  tags = {
    Name = "Vivaldi-Backend"
  }
}

# Outputs
output "db_endpoint" {
  value = aws_rds_cluster.vivaldi_aurora_cluster.endpoint
}

# # S3 Bucket 
# resource "aws_s3_bucket" "vivaldi_bucket" {
#   bucket = "vivaldi-bucket-2024"

#   tags = {
#     Name        = "Vivaldi-S3Bucket"
#     Environment = "Dev"
#   }
# }

