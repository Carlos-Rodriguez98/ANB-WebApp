variable "aws_region"            { 
    type = string 
    default = "us-east-1" 
    }
variable "project_name"          { 
    type = string 
    default = "anbapp" 
    }
variable "vpc_cidr"              { 
    type = string 
    default = "10.0.0.0/16" 
    }
variable "public_subnet_cidr"    { 
    type = string 
    default = "10.0.1.0/24" 
    }
variable "private_a_subnet_cidr" { 
    type = string 
    default = "10.0.2.0/24" 
    }
variable "private_b_subnet_cidr" { 
    type = string
    default = "10.0.3.0/24" 
    }
variable "enable_nat"            { 
    type = bool   
    default = false 
    } 

variable "allowed_ssh_cidr" {
  type        = string
  description = "IP pública para SSH (CIDR). Ej: 200.1.2.3/32"
  default     = "191.107.37.114/32" 
}

variable "db_port" {
  type        = number
  description = "Puerto de BD (PostgreSQL=5432)"
  default     = 5432
}

variable "nfs_port" {
  type        = number
  description = "Puerto NFS v4"
  default     = 2049
}

# ---- RDS ----
variable "db_engine"        { 
    type = string 
    default = "postgres" 
    }
variable "db_engine_version"{ 
    type = string 
    default = "15.8" 
    }
variable "db_instance_class"{ 
    type = string 
    default = "db.t3.micro" 
    }
variable "db_name"          { 
    type = string 
    default = "anbapp" 
    }
variable "db_username"      { 
    type = string 
    default = "anbuser" 
    }
variable "db_password"      { 
    type = string 
    sensitive = true 
    }        # pásalo por tfvars/var de entorno
variable "db_allocated_storage" { 
    type = number 
    default = 20 
    }        # GB
