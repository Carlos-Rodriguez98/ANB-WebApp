terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for web/worker/fileserver. Default selected to satisfy 2 vCPU + 2 GiB RAM (t3.small)."
  type        = string
  default     = "t3.small"
}

variable "ec2_ami_filter_name" {
  description = "AMI name filter for selecting Amazon Linux 2"
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
}

variable "key_name" {
  description = "Optional: key pair name for SSH access (create/import in AWS console). Leave empty to skip."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Prefix name for resources"
  type        = string
  default     = "entrega2"
}

variable "db_identifier" {
  description = "RDS DB identifier"
  type        = string
  default     = "ANB-WebApp"
}

variable "db_name" {
  description = "Postgres DB name"
  type        = string
  default     = "ANB-WebApp"
}

variable "db_username" {
  description = "Master username for RDS postgres"
  type        = string
  default     = "Admin"
}

variable "db_password" {
  description = "Master password for RDS postgres (REPLACE before apply)"
  type        = string
  default     = "Admin" 
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "allow_ssh_from" {
  description = "CIDR allowed to SSH into EC2 instances"
  type        = string
  default     = "0.0.0.0/0"
}