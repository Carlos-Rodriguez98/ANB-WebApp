# Script para configurar credenciales de AWS Academy
# Ejecutar CADA VEZ que inicies el lab

Write-Host "=== Configuracion de Credenciales AWS Academy ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "INSTRUCCIONES:" -ForegroundColor Yellow
Write-Host "1. Ve a AWS Academy -> Learner Lab" -ForegroundColor White
Write-Host "2. Click en 'AWS Details' -> 'Show'" -ForegroundColor White
Write-Host "3. Copia CADA credencial COMPLETA (sin espacios al inicio/final)" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANTE: Pega TODO el valor, incluyendo caracteres especiales" -ForegroundColor Red
Write-Host ""

# Solicitar credenciales con validacion
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

# Limpiar espacios en blanco
$AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID.Trim()
$AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY.Trim()
$AWS_SESSION_TOKEN = $AWS_SESSION_TOKEN.Trim()

# Configurar variables de entorno para AWS CLI
$env:AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY
$env:AWS_SESSION_TOKEN = $AWS_SESSION_TOKEN
$env:AWS_DEFAULT_REGION = "us-east-1"

# Configurar variables de entorno para Terraform
$env:TF_VAR_aws_access_key_id = $AWS_ACCESS_KEY_ID
$env:TF_VAR_aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
$env:TF_VAR_aws_session_token = $AWS_SESSION_TOKEN

Write-Host ""
Write-Host "Credenciales configuradas correctamente" -ForegroundColor Green
Write-Host ""
Write-Host "Verificando conexion con AWS..." -ForegroundColor Cyan

try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Conexion exitosa!" -ForegroundColor Green
        Write-Host $identity
        Write-Host ""
        Write-Host "Las credenciales estan activas en esta sesion de PowerShell" -ForegroundColor Green
        Write-Host "Expiran en aproximadamente 4 horas" -ForegroundColor Yellow
    }
    else {
        Write-Host "Error al verificar credenciales" -ForegroundColor Red
        Write-Host $identity
        Write-Host ""
        Write-Host "Posibles causas:" -ForegroundColor Yellow
        Write-Host "- Credenciales copiadas incorrectamente (espacios extra, incompletas)" -ForegroundColor White
        Write-Host "- Lab no esta iniciado (circulo debe estar verde)" -ForegroundColor White
        Write-Host "- AWS CLI no esta instalado correctamente" -ForegroundColor White
    }
}
catch {
    Write-Host "Error al ejecutar AWS CLI" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Esta instalado AWS CLI? Verifica con: aws --version" -ForegroundColor Yellow
}
