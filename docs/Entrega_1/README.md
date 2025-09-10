# Entrega 1
A continuación se relacionada el detalle de las funcionalidades de la aplicación, decisiones de arquitectura y consideraciones importantes para el despliegue de la app.

## Características Principales
- Sistema de autenticación y registro de usuarios.
- Sistema para cargue de videos.
- Sistema de procesamiento asíncrono del video para que cumpla con los requerimiento de tamaño, Resolución y duración.
- Sistema de actualización de ranking.
- Interfaz de usaurio moderna y responsiva.
- Arquitectura de microservicios.
- Seguridad en la autenticación mediante token JWT.
- Uso de Docker para empaquetra código de los servicios y componentes para fácil despliegue.
- Uso de GitActions para ejecución de pruebas unitarias, pruebas de integración, construcción de imagenes y análisis estático del código.

## 📌 Arquitectura
Para la defiición de la arquitectura se tuvieron en cuenta múltiples factores de acuerdo a los solicitado en el requerimiento, que terminaron por impactar directamente las decisiones de diseño y definicion de Vistas de arquitectura, los cuales relacionamos a continuación:

### 🎯 Objetivos principales
- Diseñar e implementar una API REST escalable y segura para la gestión de usuarios y recursos.
- Incorporar un sistema de procesamiento asíncrono para ejecución de tareas en segundo plano.
- Garantizar seguridad, disponibilidad y eficiencia en el almacenamiento de archivos.
- Orquestar el despliegue mediante contenedores y CI/CD para portabilidad y resiliencia.
- Documentar la arquitectura con diagramas C4, decisiones de diseño y contratos de la API.
- Implementar un frontend integrado con la API.

### ⚙️ Requisitos funcionales clave

- Gestión de usuarios: registro, autenticación con JWT, control de sesiones y roles.
- Carga y procesamiento de videos:
- Revisión rango de video entre 20 y 60 segundos.
- Relación 16:9.
- Inclusión de marca de agua y cortinillas institucionales.
- Procesamiento asíncrono (workers + broker de mensajería).
- Gestión de estados de archivos: uploaded → processed.
- Votación pública y ranking:
- Un voto por usuario por video.
- Ranking dinámico con caching (Redis o vistas materializadas en PostgreSQL).

### 🔐 Requisitos de seguridad
- Uso de JWT para autenticación/autorización.
- Control de accesos a endpoints críticos.
- Cifrado y hashing de contraseñas.
- Validaciones estrictas en registro y login.

### 📦 Requisitos de infraestructura y despliegue
- Lenguaje backend: Go (Golang).
- Framework: Gin o Echo.
- Base de datos: PostgreSQL.
- Gestión de tareas: Asynq/Machinery con Redis.
- Servidor web: Nginx como proxy inverso.
- Contenedorización: Docker + docker-compose.
- CI/CD: GitHub Actions con pruebas unitarias, construcción automática y validación con SonarQube.

### Vista de contexto
La aplicación interactuará directamente con los usuarios que deseen registrarse en la aplicación para realizar las diferentes funcionalidades disponibles y descritas en el diagrama.
![Vista de contexto](artifacts/Context-view.png)

### Vista de Componentes
![Vista de Componentes](artifacts/Componentes-view.png)

**Componentes y responsabilidades**:

* **Frontend (HTML/CSS/JavaScript)**

    * Renderiza la UI (formularios de registro y Login, cargue de videos, consulta de videos, consulta de rankings y registro de voto por un vídeo).
    * Genera el llamado a los microservicios vía **HTTP/JSON**.
    * Gestiona el token JWT en el navegador (localStorage o cookies seguras).

* **Auth Service(Go)**
    * **Controllers**: Expone endpoints `/api/auth/signup` (registro), `/api/auth/login` (login).
    * **Utils**: Realiza el hashing de la contraseña (bcrypt), emisión de **JWT**.
    * **Models**: Define los atributos del modelo de usuarios.
    * **Repository**: Se encarga de los procesos de escritura y lectura en la base de datos.
    * **Services**: Define la lógica de negocio para registro y login de los usuarios.
    * Persiste y consulta usuarios en base de datos.

* **Processing Service (Go)**
    * **Controllers**: Encargado de realizar todo el procesamiento del video para que cumpla con los requisitos.

* **Ranking Service (Go)**
    * **Controllers**: Expone endpoint `/api/public/ranking`
    * Se encarga de realizar el proceso de validación continuamente para actualizar el rankig con los usuarios más votados.

* **Video Service (Go)**
    * **Controllers**: Expone endpoints `/api/videos/upload` (Subir video), `/api/videos` (Lista de videos subidos), `/api/videos/:video_id` (Obtiene detalle del video - GET, Elimina un video propio - DELETE) 
    * Toma la información de la cola y es el encar
    * Se encarga de recibir el video cargado y entregarlo a la capa de abstracción para almacenar el archivo y registrar la tarea en la cola.

* **Voting Service (Go)**
    * **Controllers**: Expone endpoint `api/public/videos` (Consulta videos publicos), `/api/public/videos/{video_id}/vote` (Registra un voto)
    * Se encarga de registrar los votos de los usuarios.

+ **Database Manager**
    * Almacena los usuarios, información de videos y votos registrados.
    * Los serviciso acceden mediante consultas parametrizadas (evitando inyección SQL).
    * Utiliza indices para acelerar las búsquedas.

* **Broker**
    * 

* **IStorageService**
    +

* Cada servicio tiene su “capa de controladores” (HTTP) y “lógica” (reglas/validaciones).
* Se comparte una única BD (patrón **DB-shared** entre microservicios); simple en local.
* Contratos REST simples, formato JSON, y autenticación **Bearer JWT**.

**Flujo de trabajo**
La aplicación esta construida siguiendo una arquitectura de microservicios, donde cada servicio es responsable de una función especifíca:

1. **auth-service**:
    - Gestiona la autenticación (Login) y registro de usuarios.
    - Maneja token JWT para sesiones seguras.

2. **processing-service**:
    - Maneja el procesamiento asincrono del video para que cumpla con los requisitos de tamaño, resolucion y duración.
    - Toma la información de las tareas pendientes de la cola.

3. **ranking-service**:
    - Permite consultar el ranking con los usuarios más votados.

4. **video-service**:
    - Permite el cargue del video y notifica que se encuentra en procesamiento.
    - Entrega la tareas para procesamiento asincrono a la cola.

5. **voting-service**:
    - Permite a los usuarios votar por sus videos favoritos.
    - Valida que cada usuario solo pueda emitir un voto por video.

### Vista de Componentes
![Vista de Despliegue](artifacts/Despliegue-view.png)

* **Host Loca (localhost)** con **Docker Engine**.
* Contenedores separados:

    * `frontend` (Nginx sirviendo estáticos) **localhost:8084**
    * `auth-service` (Go) - **localhost:8080**
    * `video-service` (Go) - **localhost:8081**
    * `voting-service` (Go) - **localhost:8082**
    * `ranking-service` (Go) - **localhost:8083**
    * `redis` - **Usa el puerto 6379**
    * `anb-database` - **Usa el puerto 5432**
* **Red de Dcker** compartida para que los serviciso se resuelvan por nombre.

**Conexiones**

* Web App → cada microservicio vía **HTTP/JSON** (puertos publicados al host).
* Microservicios → **PostgreSQL** vía **SQL/TCP** (con `DATABASE_URL`).
* Variables de entorno típicas:

  * `DATABASE_URL=postgres://user:pass@postgres:5432/tododb?sslmode=disable`
  * `JWT_SECRET=...`
  * `MAX_UPLOAD_SIZE`, `DEFAULT_AVATAR_URL`, etc.

## Modelo Entidad - Relación (ERD)
```mermaid
erDiagram
    USERS {
        int user_id PK
        string first_name
        string last_name
        string email
        string password
        string city
        string country
        datetime created_at
    }

    VIDEOS {
        int video_id PK
        int user_id FK
        string title
        string original_path
        string processed_path
        string status
        datetime uploaded_at
        datetime processed_at
        bool published
    }

    VOTES {
        int vote_id PK
        int video_id FK
        int user_id FK
        datetime created_at
    }

    USERS ||--o{ VIDEOS : "sube"
    VIDEOS ||--o{ VOTES : "recibe"
    USERS ||--o{ VOTES : "emite"
```

---
📌 Relaciones principales:  
- **Un usuario puede subir muchos videos** (`Users 1 → N Videos`).  
- **Un video puede recibir muchos votos** (`Videos 1 → N Votes`).  
- **Un usuario puede emitir muchos votos** (`Users 1 → N Votes`).  

### Vistas secuenciales
1. Registro de usuario (Signup)
```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant N as Nginx (Reverse Proxy)
    participant A as AuthService
    participant DB as Database Manager

    U->>F: Completa formulario de registro
    F->>N: POST /api/auth/signup
    N->>A: Redirige petición
    A->>DB: Guarda usuario (con hashing de contraseña)
    DB-->>A: Confirmación
    A-->>N: Usuario creado (201)
    N-->>F: Respuesta exitosa
    F-->>U: Usuario registrado
```

2. Login y generación de JWT
```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant N as Nginx
    participant A as AuthService
    participant DB as Database Manager

    U->>F: Ingresa email y contraseña
    F->>N: POST /api/auth/login
    N->>A: Redirige petición
    A->>DB: Verifica credenciales
    DB-->>A: Credenciales válidas
    A-->>N: Retorna JWT
    N-->>F: Respuesta (token)
    F-->>U: Usuario autenticado

```

3. Carga de vídeo
```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant N as Nginx
    participant V as VideoService
    participant S as IStorageService
    participant FS as File Storage
    participant DB as Database Manager
    participant B as Broker
    participant P as Processing Service

    U->>F: Sube video
    F->>N: POST /api/videos
    N->>V: Redirige petición
    V->>S: Guardar archivo
    S->>FS: Almacena video original
    FS-->>S: Confirmación
    S-->>V: OK
    V->>DB: Registro en estado "uploaded"
    DB-->>V: Confirmación
    V->>B: Publica tarea de procesamiento
    B-->>P: Worker recibe tarea
    P->>FS: Procesa y guarda versión final
    P->>DB: Actualiza estado a "processed"
    V-->>N: Respuesta (tarea creada)
    N-->>F: Video en procesamiento
    F-->>U: Notificación de carga exitosa
```

4. Votación
```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant N as Nginx
    participant Vt as VotingService
    participant DB as Database Manager

    U->>F: Emite voto por un video
    F->>N: POST /api/videos/{id}/vote
    N->>Vt: Redirige petición
    Vt->>DB: Verifica si el usuario ya votó
    DB-->>Vt: Resultado
    Vt->>DB: Registra voto (si válido)
    DB-->>Vt: Confirmación
    Vt-->>N: Respuesta (éxito o error)
    N-->>F: Notificación de voto
    F-->>U: Mensaje de confirmación
```

5. Ranking
```mermaid
sequenceDiagram
    participant U as Usuario
    participant F as Frontend
    participant N as Nginx
    participant R as RankingService
    participant DB as Database Manager
    participant C as Cache (Redis)

    U->>F: Consulta ranking
    F->>N: GET /api/ranking
    N->>R: Redirige petición
    R->>C: Consulta ranking en cache
    alt Cache hit
        C-->>R: Retorna ranking
    else Cache miss
        R->>DB: Consulta votos y genera ranking
        DB-->>R: Datos
        R->>C: Actualiza cache
    end
    R-->>N: Respuesta con ranking
    N-->>F: Datos de ranking
    F-->>U: Muestra clasificación
```

## Referencia API(Postman)
A continuación se relaciona el enlace donde se encuentra la docuemntación de la API en Postman.
![Link del .json de la colección de Postman](https://github.com/Carlos-Rodriguez98/ANB-WebApp/blob/main/collections)


##Estructura Repositorio 

## Estructura del Proyecto

```plaintext
.github/
└── workflows/               # Configuraciones de CI/CD (GitHub Actions)

capacity-planning/           # Documentación y planificación de pruebas de capacidad
collections/                 # Contiene documentación de pruebas en POSTMAN
docs/
└── Entrega_1/              # Documentación de la primera entrega

infra/                       # Contiene docker-compose, inicialización de tablas y .env
services/                       
├── auth-service/               # Servicio de autenticación
│   ├── config/                 # Configuración de BD y variables de entorno
│   ├── controllers/            # Controladores de login y registro
│   ├── models/                 # Definición de entidades (Usuario, Tokens, etc.)
│   ├── services/               # Lógica de negocio de autenticación
│   ├── test/                   # Contiene pruebas de integración
│   ├── utils/                  # Utilidades (hash, JWT, middlewares)
│   └── Dockerfile              # Imagen Docker del servicio
│
├── video-service/              # Servicio de gestión de videos
│   ├── controllers/            # Endpoints para subir y consultar videos
│   ├── models/                 # Definición de entidades de video
│   ├── services/               # Procesamiento y lógica de negocio de videos
│   └── Dockerfile
│
├── processing-service/         # Servicio de procesamiento de datos/videos
│   ├── workers/                # Procesos asíncronos de procesamiento
│   ├── services/               # Lógica de negocio de procesamiento
│   └── Dockerfile
│
├── voting-service/             # Servicio de votación y ranking
│   ├── controllers/            # Endpoints para votar
│   ├── models/                 # Definición de entidades de voto
│   ├── services/               # Lógica de negocio de votación y consenso
│   └── Dockerfile
│
frontend/                       # Interfaz de usuario (WebApp)
├── categories/                 # Componentes de categorías
├── tasks/                      # Componentes de tareas
└── Dockerfile                  # Imagen Docker del frontend

README.md
sonar-project.properties        # Configuración para SonarCloud
.gitignore
.gitattributes
```

## Uso

### Requisitos previos
- Docker y Docker Compose
- Espacio en disco para imágenes Docker
- Puertos 8080-8084 disponibles

### Instrucciones de Ejecución

1. Clonar el repositorio:
```bash
git clone https://github.com/Carlos-Rodriguez98/ANB-WebApp.git
cd ANB-WebApp/infra
```

2. Definir variables de entorno:
En la carpeta infra se debe definir un archivo .env con la siguiente estructura:
```
# Database
DB_HOST=anb-database
DB_PORT=5432
DB_USER=Admin
DB_PASSWORD=Admin
DB_NAME=ANB-WebApp

# Redis
REDIS_ADDR=redis:6379
STORAGE_BASE_PATH=/data/uploads
WORKER_CONCURRENCY=5
REDIS_PORT=6379

# Services Port
AUTH_SERVER_PORT=8080
VIDEO_SERVER_PORT=8081
VOTING_SERVER_PORT=8082
RANKING_SERVER_PORT=8083
FRONT_SERVER_PORT=8084

# Json Web Token
JWT_SECRET=clavesecreta
```

3. Definir puertos de acceso:
    - Frontend: http://localhost:8084
    - servicios API:
        - Auth Service: http://localhost:8080
        - Video Service: http://localhost:8081
        - Voting service: http://localhost:8082
        - Ranking service: http://localhost:8083

3. Iniciar los servicios con Docker Compose:
```bash
docker-compose up --build
```
Los servicios se conectarán automáticamente a la base de datos usando las credenciales configuradas en el docker-compose.yml.
