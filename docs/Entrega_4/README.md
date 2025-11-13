# Reporte de arquitectura desplegada en AWS – Entrega 4

## 1. Descripción general

La infraestructura definida en esta entrga implementa una arquitectura cloud moderna y segura sobre la cuenta sandbox de AWS, orientada a soportar una aplicación web compuesta por múltiples servicios (web, procesamiento, base de datos, almacenamiento, etc). Se utilizan recursos gestionados y buenas prácticas de segmentación, alta disponibilidad y seguridad, facilitando el despliegue, operación y escalabilidad de la solución.

![Arquitectura AWS](./artifacts/aws_arch.jpg)

## 2. Recursos utilizados

### 2.1. Red y conectividad

- **VPC dedicada**: Se crea una Virtual Private Cloud (VPC) con un bloque CIDR configurable (`10.0.0.0/16` por defecto), habilitando DNS interno.
- **Subredes públicas y privadas**: 
  - Dos subredes públicas (en distintas zonas de disponibilidad) para exponer servicios web y balanceadores.
  - Dos subredes privadas (en distintas zonas de disponibilidad) para recursos internos como la base de datos y almacenamiento.
- **Internet Gateway**: Permite la salida a Internet de las instancias en subredes públicas.
- **Tablas de rutas**: Configuración de rutas para acceso a Internet desde subredes públicas.
- **VPC Endpoints**: Se crean endpoints privados para servicios críticos de AWS (SSM, KMS), permitiendo la administración y cifrado sin exponer tráfico a Internet.

### 2.2. Seguridad

- **Grupos de seguridad**: 
  - Reglas estrictas para acceso HTTP/HTTPS desde Internet solo a los servicios web.
  - Acceso SSH restringido únicamente a una IP administrativa.
  - Comunicación interna entre servicios controlada por reglas de grupo de seguridad.
- **Roles e Instance Profiles**: Uso de roles gestionados para acceso seguro a recursos AWS desde las instancias EC2.

### 2.3. Cómputo

- **EC2 Launch Template y Auto Scaling Group**: 
  - Plantilla de lanzamiento para instancias web y worker basada en Amazon Linux 2023.
  - Configuración de escalabilidad automática (ASG) para alta disponibilidad (deseado=1, mínimo=1, máximo=3).
  - Instalación automatizada de Docker y docker-compose para orquestar los servicios de la aplicación.

### 2.4. Almacenamiento y Base de Datos

- **Amazon S3**: 
  - Un bucket para almacenamiento de videos originales subidos por los usuarios y para los videos procesados.
- **Amazon RDS (PostgreSQL)**: 
  - Instancia de base de datos en subredes privadas, no expuesta a Internet.
  - Grupo de parámetros personalizado para logging y performance.
  - Subnet group para alta disponibilidad (aunque en modo dev, sin Multi-AZ).

### 2.5. Mensajería

- **Amazon SQS**: 
  - Cola tipo standard que permite recibir peticiones de procesamiento de videos desde el servidor web para ser atendidas por el servidor worker.


## 3. Estructura de la Arquitectura

La arquitectura se organiza en capas y zonas de disponibilidad para maximizar la seguridad y disponibilidad:

- **Capa pública**: 
  - Balanceador de carga (ALB) y servicios web expuestos a Internet.
  - Acceso restringido por grupos de seguridad.
- **Capa privada**: 
  - Servicios de backend, procesamiento, base de datos y almacenamiento.
  - Comunicación interna segura, sin exposición directa a Internet.
- **Almacenamiento**: 
  - Bucket S3 para archivos y almacenamiento compartido entre instancias.
- **Administración y monitoreo**: 
  - VPC Endpoints para administración segura vía SSM/KMS.
  - Roles y políticas para acceso controlado a recursos.

## 4. Flujo de ejecución de la aplicación

1. **Despliegue de infraestructura**: Terraform crea la VPC, subredes, instancias, bucket, RDS y configura la seguridad.
2. **Inicialización de instancias**: Las instancias EC2 se configuran automáticamente (user-data) para instalar Docker y levantar los servicios de la aplicación.
3. **Carga y procesamiento de archivos**: 
   - Los usuarios suben videos a través del frontend.
   - Los archivos se almacenan en S3 según el flujo.
   - Servicios de procesamiento operan sobre los archivos y almacenan resultados en S3.
4. **Persistencia y comunicación**: 
   - Los servicios acceden a la base de datos RDS en la capa privada.
   - La comunicación entre servicios se realiza dentro de la VPC, protegida por grupos de seguridad. Entre el servidor web y el servidor worker se manejan peticiones por medio de la cola en SQS.
5. **Acceso y administración**: 
   - El acceso a la aplicación se realiza a través del ALB en la capa pública.
   - La administración de instancias se realiza de forma segura mediante SSM, sin necesidad de exponer puertos de administración.


## 5. Comandos para Desplegar la Arquitectura

### Prerequisitos:

- AWS Academy Learner Lab activo
- Terraform instalado (versión 1.0+)
- Git bash o terminal con soporte bash

### Paso 1: Preparar credenciales de AWS

Navega al directorio de Terraform:

```bash
cd infra/terraform/
```

Obtén las credenciales de AWS Academy (Learner Lab → AWS Details → AWS CLI: Show):

- `aws_access_key_id`
- `aws_secret_access_key`
- `aws_session_token`

Ejecuta el script de configuración:

**En Linux/Mac:**
```bash
./1-set-credentials.sh
```

**En Windows (PowerShell):**
```powershell
.\1-set-credentials.ps1
```

El script te pedirá las credenciales y las guardará en variables de entorno.

### Paso 2: Inicializar Terraform

```bash
terraform init
```

### Paso 3: Planificar el despliegue

Visualiza lo que Terraform va a crear:

**En Linux/Mac:**
```bash
./2-plan.sh
```

**En Windows (PowerShell):**
```powershell
.\2-plan.ps1
```

### Paso 4: Aplicar el despliegue

Despliega la infraestructura:

**En Linux/Mac:**
```bash
./3-apply.sh
```

**En Windows (PowerShell):**
```powershell
.\3-apply.ps1
```

El proceso toma aproximadamente **15-20 minutos**. Al finalizar, verás outputs con:
- URL del ALB para acceder a la aplicación
- Endpoint de RDS
- URL de la cola SQS
- IDs de recursos creados

### Paso 5: Verificar el despliegue

Accede a la aplicación usando el ALB DNS name mostrado en los outputs:

```
http://<alb-dns-name>
```

Puedes verificar el estado de los servicios conectándote a las instancias vía SSM:

1. Ve a AWS Console → EC2 → Instances
2. Selecciona una instancia web
3. Click en "Connect" → "Session Manager" → "Connect"
4. Verifica servicios: `docker ps`

### Paso 6: Destruir la infraestructura

**IMPORTANTE**: Para evitar consumir créditos de AWS Academy, elimina todos los recursos cuando termines:

**En Linux/Mac:**
```bash
./4-destroy.sh
```

**En Windows (PowerShell):**
```powershell
.\4-destroy.ps1
```

**Nota**: La eliminación toma ~10 minutos. Verifica en la consola de AWS que todos los recursos se eliminaron correctamente.