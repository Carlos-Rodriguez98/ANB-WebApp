# ============================================
# CONFIGURACIÓN PARA AWS ACADEMY
# ============================================
# Copia este archivo a terraform.tfvars y ajusta los valores

# ---- REGIÓN AWS ----
aws_region = "us-east-1" # NO cambiar en AWS Academy

# ---- PROYECTO ----
project_name = "anbapp"

# ---- NETWORKING ----
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidr    = "10.0.1.0/24"
private_a_subnet_cidr = "10.0.2.0/24"
private_b_subnet_cidr = "10.0.3.0/24"
enable_nat            = true # Necesario para que Worker y NFS accedan a Internet

# ---- SEGURIDAD ----
# Tu IP pública para acceso SSH (obtén con: curl ifconfig.me)
allowed_ssh_cidr = "181.59.2.82/32"

# ---- INSTANCIAS EC2 ----
instance_type      = "t3.small" # 2 vCPU, 2 GiB RAM (según requisitos)
instance_disk_size = 30         # GB (según requisitos)

# ---- BASE DE DATOS RDS ----
db_engine            = "postgres"
db_engine_version    = "16.9"
db_instance_class    = "db.t3.micro"
db_name              = "anbapp"
db_username          = "anbuser"
db_password          = "ANBapp2024!Secure" # CAMBIAR por una segura en producción
db_allocated_storage = 20                  # GB
db_port              = 5432

# ---- APLICACIÓN ----
jwt_secret = "anb-jwt-secret-super-seguro-2024-academy-min-32-chars" # Mínimo 32 caracteres
ssm_path   = "/anbapp"

# ---- PUERTOS DE SERVICIOS ----
front_server_port = 8084
