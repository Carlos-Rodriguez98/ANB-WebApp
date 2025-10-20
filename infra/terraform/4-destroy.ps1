# Paso 4: Eliminar infraestructura
# CUIDADO: Este script ELIMINARA todos los recursos

Write-Host "========================================" -ForegroundColor Red
Write-Host "DESTRUCCION DE INFRAESTRUCTURA" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
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

Write-Host "Este script ELIMINARA PERMANENTEMENTE:" -ForegroundColor Yellow
Write-Host "  - Todas las instancias EC2" -ForegroundColor White
Write-Host "  - La base de datos RDS (y sus datos)" -ForegroundColor White
Write-Host "  - VPC, Subnets, Security Groups" -ForegroundColor White
Write-Host "  - NAT Gateway" -ForegroundColor White
Write-Host ""
Write-Host "ESTA ACCION NO SE PUEDE DESHACER" -ForegroundColor Red
Write-Host ""

$confirm1 = Read-Host "Estas SEGURO? (escribe 'ELIMINAR' en mayusculas)"

if ($confirm1 -ne "ELIMINAR") {
    Write-Host ""
    Write-Host "Operacion cancelada" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "Ejecutando terraform destroy..." -ForegroundColor Red
Write-Host "Esto puede tomar varios minutos..." -ForegroundColor Yellow
Write-Host ""

terraform destroy -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "INFRAESTRUCTURA ELIMINADA EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Todos los recursos han sido eliminados de AWS" -ForegroundColor White
    Write-Host "Ya no se generaran costos por estos recursos" -ForegroundColor Green
    Write-Host ""
    
    # Limpiar archivo de credenciales
    Write-Host "Limpiando archivo de credenciales..." -ForegroundColor Yellow
    Remove-Item $credFile -ErrorAction SilentlyContinue
    Write-Host "Archivo de credenciales eliminado" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR AL ELIMINAR RECURSOS" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Algunos recursos pueden no haberse eliminado" -ForegroundColor Yellow
    Write-Host "Verifica manualmente en la consola de AWS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  - Recursos con dependencias activas" -ForegroundColor White
    Write-Host "  - Credenciales expiradas (ejecuta: .\1-set-credentials.ps1)" -ForegroundColor White
    Write-Host ""
    exit 1
}
