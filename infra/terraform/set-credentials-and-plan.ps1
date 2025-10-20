# Script para configurar credenciales y ejecutar terraform plan
# Este script crea un archivo temporal con las credenciales

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

Write-Host "Ejecutando terraform plan..." -ForegroundColor Cyan
Write-Host ""

terraform plan

$exitCode = $LASTEXITCODE

# Limpiar archivo de credenciales
Write-Host ""
Write-Host "Limpiando archivo temporal de credenciales..." -ForegroundColor Yellow
Remove-Item $credFile -ErrorAction SilentlyContinue

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "Plan generado exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para aplicar los cambios, ejecuta:" -ForegroundColor Yellow
    Write-Host "  terraform apply" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTA: Deberas volver a ejecutar este script antes de 'terraform apply'" -ForegroundColor Red
    Write-Host "      para que las credenciales esten disponibles" -ForegroundColor Red
}
else {
    Write-Host ""
    Write-Host "Error al generar el plan" -ForegroundColor Red
    exit $exitCode
}
