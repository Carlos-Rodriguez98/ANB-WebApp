# Script para configurar credenciales y destruir infraestructura
# CUIDADO: Este script ELIMINARA todos los recursos creados por Terraform

Write-Host "========================================" -ForegroundColor Red
Write-Host "DESTRUCCION DE INFRAESTRUCTURA" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "Este script ELIMINARA PERMANENTEMENTE:" -ForegroundColor Yellow
Write-Host "  - Todas las instancias EC2" -ForegroundColor White
Write-Host "  - La base de datos RDS (y sus datos)" -ForegroundColor White
Write-Host "  - VPC, Subnets, Security Groups" -ForegroundColor White
Write-Host "  - NAT Gateway" -ForegroundColor White
Write-Host ""
Write-Host "ESTA ACCION NO SE PUEDE DESHACER" -ForegroundColor Red
Write-Host ""

$confirm1 = Read-Host "Estas SEGURO de que quieres continuar? (escribe 'ELIMINAR' en mayusculas)"

if ($confirm1 -ne "ELIMINAR") {
    Write-Host ""
    Write-Host "Operacion cancelada" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "=== Configuracion de Credenciales AWS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "INSTRUCCIONES:" -ForegroundColor Yellow
Write-Host "1. Ve a AWS Academy -> Learner Lab" -ForegroundColor White
Write-Host "2. Click en 'AWS Details' -> 'Show'" -ForegroundColor White
Write-Host "3. Copia CADA credencial COMPLETA" -ForegroundColor White
Write-Host ""

# Solicitar credenciales
do {
    $AWS_ACCESS_KEY_ID = Read-Host "AWS_ACCESS_KEY_ID (empieza con ASIA...)"
    if ($AWS_ACCESS_KEY_ID -notmatch "^ASIA") {
        Write-Host "Advertencia: Normalmente empieza con 'ASIA'" -ForegroundColor Yellow
    }
} while ([string]::IsNullOrWhiteSpace($AWS_ACCESS_KEY_ID))

do {
    $AWS_SECRET_ACCESS_KEY = Read-Host "AWS_SECRET_ACCESS_KEY (40 caracteres aprox)"
    if ($AWS_SECRET_ACCESS_KEY.Length -lt 30) {
        Write-Host "Advertencia: Parece muy corta" -ForegroundColor Yellow
    }
} while ([string]::IsNullOrWhiteSpace($AWS_SECRET_ACCESS_KEY))

do {
    $AWS_SESSION_TOKEN = Read-Host "AWS_SESSION_TOKEN (muy largo, 500+ caracteres)"
    if ($AWS_SESSION_TOKEN.Length -lt 100) {
        Write-Host "Advertencia: El token de sesion suele ser MUY largo" -ForegroundColor Yellow
    }
} while ([string]::IsNullOrWhiteSpace($AWS_SESSION_TOKEN))

# Limpiar espacios
$AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID.Trim()
$AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY.Trim()
$AWS_SESSION_TOKEN = $AWS_SESSION_TOKEN.Trim()

# Crear archivo temporal con credenciales
$credFile = "aws_credentials.auto.tfvars"
$content = @"
aws_access_key_id     = "$AWS_ACCESS_KEY_ID"
aws_secret_access_key = "$AWS_SECRET_ACCESS_KEY"
aws_session_token     = "$AWS_SESSION_TOKEN"
"@

$content | Out-File -FilePath $credFile -Encoding UTF8

Write-Host ""
Write-Host "Credenciales guardadas en $credFile" -ForegroundColor Green
Write-Host ""
Write-Host "Verificando conexion con AWS CLI..." -ForegroundColor Cyan

# Configurar para AWS CLI tambien
$env:AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY
$env:AWS_SESSION_TOKEN = $AWS_SESSION_TOKEN
$env:AWS_DEFAULT_REGION = "us-east-1"

try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Conexion exitosa!" -ForegroundColor Green
        Write-Host $identity
        Write-Host ""
    }
    else {
        Write-Host "Error al verificar credenciales" -ForegroundColor Red
        Write-Host $identity
        Remove-Item $credFile -ErrorAction SilentlyContinue
        exit 1
    }
}
catch {
    Write-Host "Error al ejecutar AWS CLI" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Remove-Item $credFile -ErrorAction SilentlyContinue
    exit 1
}

# Confirmacion final
Write-Host "========================================" -ForegroundColor Red
Write-Host "ULTIMA CONFIRMACION" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
$confirm2 = Read-Host "Escribe 'si' para ELIMINAR PERMANENTEMENTE todos los recursos"

if ($confirm2 -ne "si" -and $confirm2 -ne "SI") {
    Write-Host ""
    Write-Host "Operacion cancelada" -ForegroundColor Green
    Remove-Item $credFile -ErrorAction SilentlyContinue
    exit 0
}

Write-Host ""
Write-Host "Ejecutando terraform destroy..." -ForegroundColor Red
Write-Host "Esto puede tomar varios minutos..." -ForegroundColor Yellow
Write-Host ""

terraform destroy -auto-approve

$exitCode = $LASTEXITCODE

# Limpiar archivo de credenciales
Write-Host ""
Write-Host "Limpiando archivo temporal de credenciales..." -ForegroundColor Yellow
Remove-Item $credFile -ErrorAction SilentlyContinue

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "INFRAESTRUCTURA ELIMINADA EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Todos los recursos han sido eliminados de AWS" -ForegroundColor White
    Write-Host "Ya no se generaran costos por estos recursos" -ForegroundColor Green
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
    exit $exitCode
}
