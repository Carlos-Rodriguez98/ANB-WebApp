# Paso 2: Ver plan de despliegue
# Ejecuta este script para ver que recursos se van a crear
# NO crea ningun recurso, solo muestra el plan

Write-Host "=== Plan de Despliegue ===" -ForegroundColor Cyan
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
Write-Host "Generando plan de despliegue..." -ForegroundColor Cyan
Write-Host ""

terraform plan

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "PLAN GENERADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Revisa el plan arriba para ver que recursos se crearan" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Si todo se ve bien, ejecuta:" -ForegroundColor Yellow
    Write-Host "  .\3-apply.ps1" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "Error al generar el plan" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "- Credenciales expiradas (ejecuta: .\1-set-credentials.ps1)" -ForegroundColor White
    Write-Host "- Error en la configuracion de Terraform" -ForegroundColor White
    Write-Host ""
    exit 1
}
