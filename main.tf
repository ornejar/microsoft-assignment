# Provider Configuration
provider "aws" {
  region = var.aws_region
}

# VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = var.aws_availability_zone
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.aws_availability_zone
}

# Second private subnet in a different AZ
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"  # Adjust the CIDR as needed
  availability_zone = "us-west-2b"   # Ensure this is a different AZ from the first private subnet

  tags = {
    Name = "private-subnet-2"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2 instance to allow HTTP access
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ec2_security_group"

  # Inbound rule for HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows access from anywhere
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# EC2 Instance in the public subnet
resource "aws_instance" "web_server" {
  ami           = "ami-066a7fbea5161f451" # Amazon Linux 2 AMI (update to a region-specific AMI)
  instance_type = "t2.micro"              # Free-tier eligible instance type

  # Associate the instance with the public subnet and security group
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id] 
  # User data (optional) to run on instance startup
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hi Microsoft and Welcome to the Web Server!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "WebServer"
  }
}

# Security Group for RDS to allow access from EC2 instance
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  name   = "rds_security_group"

  # Inbound rule to allow MySQL access from EC2 instance's security group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Only allow traffic from EC2 security group
  }

  # Allow all outbound traffic (optional, default behavior for AWS)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# RDS Database instance in private subnet
resource "aws_db_instance" "database" {
  allocated_storage    = 20                        # Storage size in GB
  storage_type         = "gp2"                     # General-purpose SSD
  engine               = "mysql"                   # Database engine (e.g., MySQL)
  engine_version       = "8.0.32"                     # MySQL version
  instance_class       = "db.t2.micro"             # Free-tier eligible instance type
  username             = var.db_username           # Master username
  password             = var.db_password           # Master password (ensure it's secure)
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # Attach RDS security group
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  # Optional: Set automatic backups and retention period
  backup_retention_period = 7
  skip_final_snapshot     = true # Skip final snapshot on deletion

  tags = {
    Name = "MyDatabase"
  }
}

# Subnet Group for RDS (required for RDS in a VPC)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id] # Add both private subnets
  tags = {
    Name = "RDSSubnetGroup"
  }
}


