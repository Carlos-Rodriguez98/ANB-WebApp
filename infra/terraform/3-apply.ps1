# Paso 3: Desplegar infraestructura
# Este script CREA los recursos en AWS

Write-Host "=== Despliegue de Infraestructura ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que existan las credenciales
$credFile = "aws_credentials.auto.tfvars"
if (-not (Test-Path $credFile)) {
    Write-Host "Error: No se encontraron credenciales" -ForegroundColor Red
    Write-Host ""
    Write-Host "Primero ejecuta: .\1-set-credentials.ps1" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Credenciales encontradas" -ForegroundColor Green
Write-Host ""

# Confirmacion
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "ADVERTENCIA: CREACION DE RECURSOS AWS" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Este comando creara:" -ForegroundColor White
Write-Host "  - 3 instancias EC2 (Web, Worker, NFS)" -ForegroundColor White
Write-Host "    Tipo: t3.small (2 vCPU, 2 GiB RAM, 30 GiB storage)" -ForegroundColor White
Write-Host "  - 1 base de datos RDS PostgreSQL" -ForegroundColor White
Write-Host "  - VPC, Subnets, Security Groups" -ForegroundColor White
Write-Host "  - NAT Gateway (si esta habilitado)" -ForegroundColor White
Write-Host ""
Write-Host "ESTO GENERARA COSTOS EN AWS" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Deseas continuar? (escribe 'si' para confirmar)"

if ($confirm -ne "si" -and $confirm -ne "SI") {
    Write-Host ""
    Write-Host "Operacion cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Desplegando infraestructura..." -ForegroundColor Cyan
Write-Host "Esto puede tomar 5-10 minutos..." -ForegroundColor Yellow
Write-Host ""

terraform apply -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "DESPLIEGUE COMPLETADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Recursos creados:" -ForegroundColor Cyan
    Write-Host "  - 3 instancias EC2 (Web, Worker, NFS)" -ForegroundColor White
    Write-Host "  - 1 base de datos RDS PostgreSQL" -ForegroundColor White
    Write-Host "  - VPC con subnets publicas y privadas" -ForegroundColor White
    Write-Host "  - Security Groups configurados" -ForegroundColor White
    Write-Host ""
    Write-Host "Para ver los outputs (IPs, endpoints):" -ForegroundColor Yellow
    Write-Host "  terraform output" -ForegroundColor White
    Write-Host ""
    Write-Host "Para conectarte via SSH a la instancia Web:" -ForegroundColor Yellow
    Write-Host "  ssh -i ~/.ssh/labsuser.pem ec2-user@<WEB_PUBLIC_IP>" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "IMPORTANTE: GESTION DE COSTOS" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para DETENER instancias EC2 (sin eliminarlas):" -ForegroundColor Yellow
    Write-Host "  Ve a la consola EC2 -> Selecciona instancias -> Stop" -ForegroundColor White
    Write-Host ""
    Write-Host "Para ELIMINAR toda la infraestructura:" -ForegroundColor Yellow
    Write-Host "  .\4-destroy.ps1" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR DURANTE EL DESPLIEGUE" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  - Limites de cuota en AWS Academy" -ForegroundColor White
    Write-Host "  - Recursos ya existentes con el mismo nombre" -ForegroundColor White
    Write-Host "  - Credenciales expiradas (ejecuta: .\1-set-credentials.ps1)" -ForegroundColor White
    Write-Host ""
    exit 1
}
