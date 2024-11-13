# AWS Infrastructure Provisioning with Terraform

This Terraform configuration provisions a basic infrastructure setup in AWS, including a VPC with public and private subnets, an EC2 instance for a web server, and an RDS instance for a MySQL database. The resources are configured with security groups to allow HTTP access to the EC2 instance and secure database access from the EC2 instance to the RDS instance.

## Prerequisites

- **Terraform**: Install Terraform (v1.0 or later).
- **AWS Account**: Ensure you have access to an AWS account.
- **AWS CLI**: Optionally, install the AWS CLI to verify credentials and access.

## Setup

### Environment Variables

For security, the database credentials are managed through environment variables. Before running Terraform commands, set these environment variables in your terminal:

```bash
# Set the database username
export TF_VAR_db_username="admin"

# Set the database password
export TF_VAR_db_password="secure_password"
```

> **Note**: On Windows, you can set these variables in Command Prompt as follows:
> ```cmd
> set TF_VAR_db_username=admin
> set TF_VAR_db_password=secure_password
> ```
> Or, in PowerShell:
> ```powershell
> $env:TF_VAR_db_username = "admin"
> $env:TF_VAR_db_password = "secure_password"
> ```

## Terraform Configuration

### `main.tf`

This file contains the main configuration for the AWS infrastructure.

- **Provider Configuration**:
  ```hcl
  provider "aws" {
    region = var.aws_region
  }
  ```

- **VPC and Subnets**:
  - Creates a VPC with CIDR block `10.0.0.0/16`.
  - Configures a public subnet (`10.0.1.0/24`) and two private subnets (`10.0.2.0/24` and `10.0.3.0/24`) in different availability zones.

- **Internet Gateway and Route Table**:
  - Sets up an internet gateway to allow internet access to the public subnet.
  - Configures a route table to direct traffic from the public subnet to the internet.

- **EC2 Security Group**:
  - Allows inbound HTTP traffic on port 80 to the EC2 instance from any IP.
  - Allows all outbound traffic.

- **EC2 Instance**:
  - Launches an EC2 instance in the public subnet with an Amazon Linux 2 AMI.
  - Installs Apache (HTTP server) and serves a simple HTML page.

- **RDS Security Group**:
  - Allows MySQL traffic (port 3306) only from the EC2 instance’s security group.

- **RDS Instance**:
  - Creates an RDS instance in the private subnets with MySQL `8.0.32`.
  - Uses a secure configuration with access restricted to the private subnets.

### `variables.tf`

This file defines variables to configure the infrastructure.

- **AWS Region and Availability Zone**:
  ```hcl
  variable "aws_region" {
    description = "AWS region for deployment"
    type        = string
    default     = "us-west-2"
  }

  variable "aws_availability_zone" {
    description = "AWS availability zone"
    type        = string
    default     = "us-west-2a"
  }
  ```

- **VPC and Subnet CIDR Blocks**:
  ```hcl
  variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
  }

  variable "public_subnet_cidr" {
    description = "CIDR block for the public subnet"
    type        = string
    default     = "10.0.1.0/24"
  }

  variable "private_subnet_cidr" {
    description = "CIDR block for the private subnet"
    type        = string
    default     = "10.0.2.0/24"
  }
  ```

- **Database Credentials**:
  ```hcl
  variable "db_username" {
    description = "Database username"
    type        = string
  }

  variable "db_password" {
    description = "Database password"
    type        = string
    sensitive   = true
  }
  ```

## Usage

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the Infrastructure**:
   - Preview the resources that Terraform will create:
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**:
   - Deploy the infrastructure:
   ```bash
   terraform apply
   ```
   - Type `yes` to confirm and apply the changes.

4. **Destroy the Infrastructure** (when done):
   - Clean up all resources created by this configuration:
   ```bash
   terraform destroy
   ```

## Notes

- Make sure to set the required environment variables (`TF_VAR_db_username` and `TF_VAR_db_password`) before running Terraform commands.
- This configuration uses an Amazon Linux 2 AMI (`ami-066a7fbea5161f451`) and `t2.micro` for the EC2 instance, which should be free-tier eligible. Check your AWS account for any additional costs.

---

This README provides detailed setup and usage instructions for provisioning an AWS environment with Terraform. Let me know if you’d like further customization!