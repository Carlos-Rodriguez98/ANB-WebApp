# Endpoints API ANB-WEBAPP

Tenemos los siguientes 10 endpoints del backend de la aplicación:

| Grupo         | Endpoint                             | Método | Descripción                   |
|---------------|--------------------------------------|--------|-------------------------------|
| Autenticación | `/api/auth/signup`                   | POST   | Registro de jugadores         |
| Autenticación | `/api/auth/login`                    | POST   | Inicio de sesión              |
| Videos        | `/api/videos/upload`                 | POST   | Subida de video               |
| Videos        | `/api/videos`                        | GET    | Listado de videos del usuario |
| Videos        | `/api/videos/{video_id}`             | GET    | Detalle de un video           |
| Videos        | `/api/videos/{video_id}`             | DELETE | Eliminación de un video       |
| Videos        | `/api/videos/{video_id}/publish`     | POST   | Publicar un video             |
| Público       | `/api/public/videos`                 | GET    | Lista de videos públicos      |
| Público       | `/api/public/videos/{video_id}/vote` | POST   | Votar un video                |
| Ranking       | `/api/public/rankings`               | GET    | Ranking general               |

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

### Subir Video (POST) `/api/videos/upload`

**Descripción:** Se encarga de subir un video por parte de un jugador que ya tenga su sesión iniciada.

**Headers:**

* Content-Type: application/json.
* Authentication: Bearer.

**Body (form-data):**

| key        | Tipo    | Requerido | Descripción                                      |
|------------|---------|-----------|--------------------------------------------------|
| video_file | archivo | Sí        | Archivo de video en formato MP4 con máximo 100MB |
| title      | string  | Sí        | Título descriptivo del video                     |

**Respuestas esperadas:** 
* **Código 201.** Video subido exitosamente, tarea creada.
```
{
    "message": "Video subido correctamente. Procesamiento en curso.",
    "task_id": "100"
}
```

* **Código 400.** Error en el archivo (tipo o tamaño inválido).
```
{
    "error": "solo se permite un video en formato .mp4"
}
```
```
{
    "error": "Archivo muy grande (max 100MB)"
}
```

* **Código 401.** Falta de autenticación.
```
{
    "error": "missing bearer token"
}
```

### Consultar Listado Videos Propios (GET) `/api/videos`

**Descripción:** Se encarga de mostrar todos los videos que ha subido el jugador que ha iniciado sesión.

**Headers:**

* Content-Type: application/json.
* Authentication: Bearer.

**Respuestas esperadas:** 
* **Código 200.** Lista de videos obtenida.
```
[
  {
    "video_id": 101,
    "title": "Título descriptivo del video. (101)",
    "status": "uploaded",
    "uploaded_at": "2025-11-07T00:28:22Z",
    "published": false
  },
  {
    "video_id": 100,
    "title": "Título descriptivo del video. (100)",
    "status": "processed",
    "uploaded_at": "2025-11-07T00:23:37Z",
    "processed_at": "2025-11-07T00:23:58Z",
    "processed_url": "/static/processed/user_916/140.mp4",
    "published": false
  }
]
```

* **Código 401.** Falta de autenticación.
```
{
    "error": "missing bearer token"
}
```

### Consultar Detalle de un Video Propio (GET) `/api/videos/{videos_id}`

**Descripción:** Se encarga de mostrar todo el detalle de un video que ha subido el jugador que ha iniciado sesión.

**Headers:**

* Content-Type: application/json.
* Authentication: Bearer.

**Respuestas esperadas:** 
* **Código 200.** Consulta exitosa. Se devuelve el detalle del video.
```
{
  "video_id": 100,
  "title": "Título descriptivo del video. (100)",
  "status": "processed",
  "uploaded_at": "2025-11-07T00:28:22Z",
  "processed_at": "2025-11-07T00:28:44Z",
  "original_url": "/static/original/user_916/100.mp4",
  "processed_url": "/static/processed/user_916/100.mp4",
  "published": false,
  "votes": 0
}
```
```
{
  "video_id": 101,
  "title": "Título descriptivo del video. (101)",
  "status": "uploaded",
  "uploaded_at": "2025-11-07T00:35:10Z",
  "original_url": "/static/",
  "published": false,
  "votes": 0
}
```

* **Código 401.** Falta de autenticación.
```
{
  "error": "missing bearer token"
}
```

* **Código 403.** El usuario autenticado no tiene permisos para acceder a este video (no es el propietario).
```
{
  "error": "no tienes permiso para acceder a este video"
}
```

* **Código 404.** El video con el video_id especificado no existe o no pertenece al usuario.
```
{
  "error": "video no encontrado (no existe)"
}
```

### Eliminar un Video Propio (DELETE) `/api/videos/{videos_id}`

**Descripción:** Se encarga de eliminar un video que haya subido el jugador que ha iniciado sesión.

**Headers:**

* Content-Type: application/json.
* Authentication: Bearer.

**Respuestas esperadas:**
* **Código 200.** El video ha sido eliminado correctamente.
```
{
  "message": "El video ha sido eliminado exitosamente.",
  "video_id": "100"
}
```

* **Código 400.** El video no puede ser eliminado porque no cumple las condiciones (por ejemplo, ya está habilitado para votación).
```
{
  "error": "no se puede eliminar un video que ya esta publicado"
}
```

* **Código 401.** El usuario no está autenticado o el token JWT es inválido o expirado.
```
{
  "error": "missing bearer token"
}
```

* **Código 403.** El usuario autenticado no tiene permisos para eliminar este video (no es el propietario).
```
{
  "error": "no tienes permiso para eliminar este video"
}
```

* **Código 404.** El video con el video_id especificado no existe o no pertenece al usuario autenticado.
```
{
    "error": "video no encontrado (no existe)"
}
```

### Publicar un Video Propio para Votación (POST) `/api/videos/{videos_id}/publish`

**Descripción:** Se encarga de habilitar un video que haya subido el jugador que ha iniciado sesión para que este disponible para votación.

**Headers:**

* Content-Type: application/json.
* Authentication: Bearer.

**Respuestas esperadas:**
* **Código 200.** El video ha sido publicado correctamente.
```
{
  "message": "video publicado",
  "video_id": "100"
}
```

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
