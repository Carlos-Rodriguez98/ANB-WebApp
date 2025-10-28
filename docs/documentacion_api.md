# Endpoints API ANB-WEBAPP

Tenemos los siguientes 10 endpoints del backend de la aplicación:

| Grupo | Endpoint | Método | Descripción |
|--------|-----------|---------|-------------|
| Autenticación | `/api/auth/signup` | POST | Registro de jugadores |
| Autenticación | `/api/auth/login` | POST | Inicio de sesión |
| Videos | `/api/videos/upload` | POST | Subida de video |
| Videos | `/api/videos` | GET | Listado de videos del usuario |
| Videos | `/api/videos/{id}` | GET | Detalle de un video |
| Videos | `/api/videos/{id}` | DELETE | Eliminación de un video |
| Videos | `/api/videos/{id}/publish` | POST | Publicar un video |
| Público | `/api/public/videos` | GET | Lista de videos públicos |
| Público | `/api/public/videos/{id}/vote` | POST | Votar un video |
| Ranking | `/api/public/rankings` | GET | Ranking general |

## Grupo Autenticación

### Registro (POST) `/api/auth/signup`

**Descripción:** Se encarga de registrar un nuevo jugador en donde valida que el email no este registrado y que password1 y password2 coincidan.

**Headers:**

* Content-Type: application/json.

**Body (JSON):**
```
{
    "first_name": "first name example",
    "last_name": "last name example",
    "email": "example@example.com",
    "password1": "passwordExample",
    "password2": "passwordExample",
    "city": "Bogotá",
    "country": "Colombia"
}
```

**Respuestas esperadas:** 
* **Código 201.** Jugador creado.
```
{
    "message": "Usuario creado exitosamente."
}
```

* **Código 400.** Email duplicado o contraseñas no coinciden.
```
{
    "error": "las contraseñas ingresadas no coinciden"
}
```


### Inicio Sesión (POST) `/api/auth/login`

**Descripción:** Se encarga de iniciar sesión de un jugador ya registrado en donde valida la credenciales correctas.

**Headers:**

* Content-Type: application/json.

**Body (JSON):**
```
{
    "email": "example@example.com",
    "password": "passwordExample"
}
```

**Respuestas esperadas:** 
* **Código 201.** El jugador ha iniciado sesión con éxito.
```
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer",
    "expires_in": 3600
}
```

* **Código 401.** Credenciales inválidas.
```
{
    "error": "credenciales inválidas - password"
}
```

## Grupo Videos

## Grupo Público

### Videos Públicos (GET) `/api/public/videos`

**Descripción:** Se encarga de mostrar todos los videos públicos disponibles para votación.

**Headers:**

* Content-Type: application/json.

**Respuestas esperadas:** 
* **Código 200.** Devuelve todos los videos públicos.
```
[
    {
        "video_id": 101,
        "user_id": 1,
        "title": "Video Carlos (procesado y publicado)",
        "status": "processed",
        "uploaded_at": "2025-09-30T00:51:28.57604-05:00",
        "processed_at": "2025-09-30T01:51:28.57604-05:00",
        "processed_url": "processed/u7/carlos1.mp4",
        "published": true,
        "votes": 4
    },
    {
        "video_id": 102,
        "user_id": 2,
        "title": "Video Ana (procesado y publicado)",
        "status": "processed",
        "uploaded_at": "2025-09-29T23:51:28.57604-05:00",
        "processed_at": "2025-09-30T00:51:28.57604-05:00",
        "processed_url": "processed/u7/ana1.mp4",
        "published": true,
        "votes": 3
    }
]
```

### Realizar un voto (POST) `/api/public/videos/{video_id}/vote`

**Descripción:** Se encarga de realizar un voto para un video público.

**Headers:**

* Content-Type: application/json.
* Authorization: Bearer.

**Respuestas esperadas:** 
* **Código 200.** Voto registrado con éxito.
```
{
    "message": "Voto exitoso."
}
```
* **Código 400.** El usuario ya voto por ese video.
```
{
    "error": "Ya has votado por este video."
}
```
* **Código 401.** No hay un token jwt valido.
```
{
    "error": "Falta de autenticación."
}
```
* **Código 404.** Video no se encuentra disponible o no existe.
```
{
    "error": "Video no encontrado."
}
```

## Grupo Ranking

### Consultar Ranking (GET) `/api/public/rankings`

**Descripción:** Obtener ranking actual de los videos por votos acumulados.

**Headers:**

* Content-Type: application/json.

**Parametros:**

* from: índice/posición inicial (opcional).
* to: índice/posición final (opcional).
* city: filtro por cidudad de donde salen los videos.

**Respuestas esperadas:** 
* **Código 200.** Listado del ranking de los videos.
```
[
    {
        "position": 1,
        "username": "Carlos Ramírez",
        "city": "Bogotá",
        "votes": 5
    },
    {
        "position": 2,
        "username": "Ana Martínez",
        "city": "Medellín",
        "votes": 3
    }
]
```

* **Código 400.** parámetros inválidos.
```
{
    "error": "Parámetro inválido en la consulta."
}
```