# Script para configurar credenciales y ejecutar terraform apply
# Este script crea un archivo temporal con las credenciales

Write-Host "=== Despliegue de Infraestructura ANB App ===" -ForegroundColor Cyan
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

# Confirmacion antes de aplicar
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "ADVERTENCIA: CREACION DE RECURSOS AWS" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Este comando creara los siguientes recursos en AWS:" -ForegroundColor White
Write-Host "  - 3 instancias EC2 (Web, Worker, NFS)" -ForegroundColor White
Write-Host "  - 1 base de datos RDS PostgreSQL" -ForegroundColor White
Write-Host "  - VPC, Subnets, Security Groups" -ForegroundColor White
Write-Host "  - NAT Gateway (si esta habilitado)" -ForegroundColor White
Write-Host ""
Write-Host "ESTO GENERARA COSTOS EN AWS" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Deseas continuar? (escribe 'si' para confirmar)"

if ($confirm -ne "si" -and $confirm -ne "SI") {
    Write-Host ""
    Write-Host "Operacion cancelada por el usuario" -ForegroundColor Yellow
    Remove-Item $credFile -ErrorAction SilentlyContinue
    exit 0
}

Write-Host ""
Write-Host "Ejecutando terraform apply..." -ForegroundColor Cyan
Write-Host "Esto puede tomar varios minutos (5-10 min aprox)..." -ForegroundColor Yellow
Write-Host ""

terraform apply -auto-approve

$exitCode = $LASTEXITCODE

# Limpiar archivo de credenciales
Write-Host ""
Write-Host "Limpiando archivo temporal de credenciales..." -ForegroundColor Yellow
Remove-Item $credFile -ErrorAction SilentlyContinue

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "DESPLIEGUE COMPLETADO EXITOSAMENTE!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Recursos creados en AWS:" -ForegroundColor Cyan
    Write-Host "  - 3 instancias EC2 (Web, Worker, NFS)" -ForegroundColor White
    Write-Host "  - 1 base de datos RDS PostgreSQL" -ForegroundColor White
    Write-Host "  - VPC con subnets publicas y privadas" -ForegroundColor White
    Write-Host "  - Security Groups configurados" -ForegroundColor White
    Write-Host ""
    Write-Host "Para ver los outputs (IPs, endpoints, etc):" -ForegroundColor Yellow
    Write-Host "  terraform output" -ForegroundColor White
    Write-Host ""
    Write-Host "Para conectarte via SSH a la instancia Web:" -ForegroundColor Yellow
    Write-Host "  ssh -i ~/.ssh/labsuser.pem ec2-user@<WEB_PUBLIC_IP>" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "IMPORTANTE: GESTION DE COSTOS" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para DETENER las instancias EC2 (sin eliminarlas):" -ForegroundColor Yellow
    Write-Host "  aws ec2 stop-instances --instance-ids <INSTANCE_ID>" -ForegroundColor White
    Write-Host ""
    Write-Host "Para ELIMINAR toda la infraestructura:" -ForegroundColor Yellow
    Write-Host "  Ejecuta: .\set-credentials-and-destroy.ps1" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR DURANTE EL DESPLIEGUE" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Revisa los errores arriba para mas detalles" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  - Limites de cuota en AWS Academy" -ForegroundColor White
    Write-Host "  - Recursos ya existentes con el mismo nombre" -ForegroundColor White
    Write-Host "  - Credenciales expiradas (duran ~4 horas)" -ForegroundColor White
    Write-Host ""
    exit $exitCode
}
