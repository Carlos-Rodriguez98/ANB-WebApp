# Paso 1: Configurar credenciales AWS
# Ejecuta este script UNA VEZ al inicio de tu sesion de trabajo
# Las credenciales se guardaran en un archivo temporal que expira en 4 horas

Write-Host "=== Configuracion de Credenciales AWS Academy ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "INSTRUCCIONES:" -ForegroundColor Yellow
Write-Host "1. Ve a AWS Academy -> Learner Lab" -ForegroundColor White
Write-Host "2. Asegurate de que el lab este INICIADO (circulo verde)" -ForegroundColor White
Write-Host "3. Click en 'AWS Details' -> 'Show'" -ForegroundColor White
Write-Host "4. Copia CADA credencial COMPLETA (sin espacios extra)" -ForegroundColor White
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

# Guardar en archivo temporal (se ignora por .gitignore)
$credFile = "aws_credentials.auto.tfvars"
$content = @"
# Credenciales temporales de AWS Academy
# Este archivo expira en aproximadamente 4 horas
# Generado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

aws_access_key_id     = "$AWS_ACCESS_KEY_ID"
aws_secret_access_key = "$AWS_SECRET_ACCESS_KEY"
aws_session_token     = "$AWS_SESSION_TOKEN"
"@

$content | Out-File -FilePath $credFile -Encoding UTF8

Write-Host ""
Write-Host "Credenciales guardadas en: $credFile" -ForegroundColor Green
Write-Host ""
Write-Host "Verificando conexion con AWS..." -ForegroundColor Cyan

# Configurar variables de entorno para AWS CLI
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
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "CREDENCIALES CONFIGURADAS CORRECTAMENTE" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ahora puedes ejecutar:" -ForegroundColor Cyan
        Write-Host "  .\2-plan.ps1   - Para ver que se va a crear" -ForegroundColor White
        Write-Host "  .\3-apply.ps1  - Para crear la infraestructura" -ForegroundColor White
        Write-Host "  .\4-destroy.ps1 - Para eliminar todo" -ForegroundColor White
        Write-Host ""
        Write-Host "Las credenciales expiran en ~4 horas" -ForegroundColor Yellow
        Write-Host "Despues de eso, ejecuta este script nuevamente" -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        Write-Host "Error al verificar credenciales" -ForegroundColor Red
        Write-Host $identity
        Write-Host ""
        Write-Host "Posibles causas:" -ForegroundColor Yellow
        Write-Host "- Credenciales copiadas incorrectamente" -ForegroundColor White
        Write-Host "- Lab no esta iniciado (debe estar en verde)" -ForegroundColor White
        Write-Host "- AWS CLI no esta instalado" -ForegroundColor White
        Remove-Item $credFile -ErrorAction SilentlyContinue
        exit 1
    }
}
catch {
    Write-Host "Error al ejecutar AWS CLI" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Verifica que AWS CLI este instalado: aws --version" -ForegroundColor Yellow
    Remove-Item $credFile -ErrorAction SilentlyContinue
    exit 1
}
