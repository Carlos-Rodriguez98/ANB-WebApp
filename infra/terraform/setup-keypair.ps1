# Script para configurar el Key Pair desde AWS Academy
# Ejecutar UNA VEZ al inicio

Write-Host "=== Configuración de Key Pair ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Descarga el archivo labsuser.pem desde AWS Academy" -ForegroundColor Yellow
Write-Host "2. Guárdalo en: $HOME\.ssh\labsuser.pem" -ForegroundColor Yellow
Write-Host ""

$keyPath = "$HOME\.ssh\labsuser.pem"
$pubKeyPath = "$HOME\.ssh\labsuser.pub"

# Verificar si existe el archivo
if (Test-Path $keyPath) {
    Write-Host "✓ Archivo $keyPath encontrado" -ForegroundColor Green
    
    # Generar clave pública desde la privada
    Write-Host "Generando clave pública..." -ForegroundColor Cyan
    
    # Usar ssh-keygen para extraer la clave pública
    ssh-keygen -y -f $keyPath | Out-File -FilePath $pubKeyPath -Encoding ASCII
    
    Write-Host "✓ Clave pública generada: $pubKeyPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Contenido de la clave pública:" -ForegroundColor Cyan
    Get-Content $pubKeyPath
} else {
    Write-Host "✗ No se encontró el archivo $keyPath" -ForegroundColor Red
    Write-Host "Por favor, descarga labsuser.pem y guárdalo en esa ubicación" -ForegroundColor Yellow
}
