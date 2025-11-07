# **Pruebas de Carga**

## **Herramientas**

Para las pruebas de carga se utilizará **Apache JMeter**, una herramienta de código abierto diseñada para realizar pruebas de rendimiento y medir el comportamiento de aplicaciones web y otros servicios. JMeter permite simular múltiples usuarios concurrentes que acceden a una aplicación, con el fin de evaluar su capacidad de respuesta y estabilidad bajo diferentes niveles de carga.

Además, se empleará el **plugin PerfMon** (PerfMon Metrics Collector), el cual permite recopilar métricas del servidor como el uso de CPU, memoria, disco y red durante las pruebas. Esta integración proporciona una visión más completa del rendimiento del sistema.

## **Arquitectura del Entorno de Pruebas**

La arquitectura del entorno de pruebas se basa en un enfoque totalmente contenedorizado para garantizar portabilidad y consistencia en la ejecución.

Se definió un Dockerfile y un docker-compose.yml que permiten levantar un contenedor local con una versión ligera de Apache JMeter en modo CLI (sin interfaz gráfica), junto con Java 17, necesario para su ejecución. Este contenedor se utiliza exclusivamente para ejecutar los scripts de pruebas de carga de forma automatizada. Además, se realizó una modificación en el Dockerfile del servidor web que se despliega en azure para instalar el plugin PerfMon, el cual permite recopilar métricas de rendimiento del servidor (uso de CPU, memoria, red y disco) durante las pruebas.

## **Métricas Principales**

Las pruebas de carga evaluarán el desempeño del sistema en función de cuatro métricas principales:

| Métrica | Descripción | Fuente/Herramienta |
|----------|--------------|----------------------|
| **Throughput (req/s)** | Número de peticiones procesadas por segundo. Mide la capacidad de procesamiento del sistema. | JMeter Summary Report |
| **Tiempo de Respuesta Promedio (s)** | Tiempo transcurrido desde que el usuario envía una solicitud hasta recibir la respuesta completa. | JMeter Summary Report |
| **Utilización de Recursos (%)** | Porcentaje de uso de CPU y memoria RAM del servidor durante la carga. | JMeter PerfMon Plugin |
| **Tasa de errores (%)** | Porcentaje de respuestas HTTP con errores (4xx, 5xx) respecto al total de peticiones. | JMeter Summary Report |

## **Escenario 1**

### **Flujo del Escenario**

Para este escenario se define el siguiente flujo de peticiones relacionado con la capa web:

**1. Registro:** /api/auth/signup

**2. Iniciar Sesión:** /api/auth/login

**3. Consultar Videos Públicos:** /api/public/videos

**4. Realizar Voto:** /api/public/videos/{id_video}/vote

**5. Consultar Ranking:** /api/public/rankings

<p align="center">
  <img alt="Imagen1" src="https://github.com/user-attachments/assets/8f9cbaa2-5025-4b6d-91e9-ae20a8cb1499" />
</p>

### **Criterios de Aceptación**

Así mismo, se definen los criterios de aceptación que establecen los umbrales mínimos de desempeño que el sistema debe cumplir para considerarse estable y operativo durante las pruebas de carga. Estos umbrales permiten determinar cuánta carga concurrente puede soportar el servidor sin degradar la experiencia del usuario ni comprometer los recursos del sistema.

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Máx RAM   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------:|:---------------:|
| Registro                  | ≥ 5 req/s           | ≤ 2000 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| Iniciar Sesión            | ≥ 10 req/s          | ≤ 4000 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| Consultar Videos Públicos | ≥ 20 req/s          | ≤ 2500 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| Realizar Voto             | ≥ 8 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| Consultar Ranking         | ≥ 8 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| **Flujo Completo**        | **≥ 5 req/s**       | **≤ 20500 ms**               | **≤ 70%** | **≤ 75%** | **≤ 1%**       | 

> **Nota:** El *Flujo Completo* agrupa todo el recorrido del usuario (Registro → Inicio de Sesión → Consultar Videos Publicos → Realizar Voto → Consultar Ranking). Las métricas de esta fila se calculan sobre la ejecución completa del flujo, y su objetivo es validar la estabilidad del sistema durante un escenario de uso real de extremo a extremo.

### **Configuración JMeter (ConfiguracionEscenario1.jmx)**

<br>
<p align="center">
  <img alt="Imagen2" src="https://github.com/user-attachments/assets/9dd8dca6-a507-44a7-b2bf-9486a6e1ec67" />
</p>
<br>

Primero se definen las siguientes variables de entorno parametrizadas para ejecutar la prueba de carga:

```
USERS=1
RAMP=5
NUM_RUNS=5
PROTOCOL=http
SERVER_NAME=host.docker.internal
AUTH_SERVICE_PORT=8080
PUBLIC_VIDEO_SERVICE_PORT=8082
RANKING_SERVICE_PORT=8083
```

Luego, se define el Transaction Controller (Escenario_1) que ejecutará cada hilo para simular el flujo completo del escenario. Dentro de esta transacción se incluyen los siguientes elementos:

**1. JSR223 Sampler (Generar TEST_EMAIL y TEST_PASSWORD):** script escrito en Groovy que se ejecuta al inicio del flujo para generar los datos de prueba que utilizará cada hilo. En particular, se crean las variables TEST_EMAIL y TEST_PASSWORD.

**2. HTTP Request (Request_1_Registrarse):** primera petición del flujo, correspondiente al registro de usuario. En ella se envía el cuerpo de la solicitud con las variables de email y contraseña generadas, creando así un usuario único para cada hilo.

**3. HTTP Request (Request_2_Iniciar_Sesión):** segunda petición, donde el hilo inicia sesión utilizando las credenciales del usuario recién creado. Esta solicitud devuelve un access_token, el cual se extrae mediante un **JSON Extractor** y se almacena en la variable ACCESS_TOKEN.

**4. HTTP Request (Request_3_Consultar_Videos_Públicos):** tercera petición, donde el hilo obtiene la lista de videos públicos disponibles para votar. A continuación, se extrae el identificador del primer video usando un **JSON Extractor**, y se guarda en la variable VIDEO_ID.

**5. HTTP Request (Request_4_Realizar_Voto):** cuarta petición, en la que el hilo emite un voto para el video obtenido anteriormente. Esta solicitud requiere una cabecera de autenticación con el formato Authorization: Bearer ${ACCESS_TOKEN}, utilizando el token obtenido en el inicio de sesión.

**6. HTTP Request (Request_5_Consultar_Ranking):** quinta y última petición del flujo, en la que el hilo consulta la tabla de ranking de los participantes.

### Ejecución de las Pruebas

Para ejecutar la prueba de carga se ejecuta los siguientes comandos para levantar el contenedor con JMeter:

```
cd capacity-planning/Entrega_2/jmeter
```
```
docker build -t jmeter-cli:5.6.3 .
```
```
docker compose up -d
```

Ahora en otra terminal bash sobre la misma ruta se ejecuta el siguiente script para correr la prueba:

```
cd capacity-planning/Entrega_2/jmeter
```
```
USERS=1 RAMP=5 NUM_RUNS=5 SERVER_NAME=host.docker.internal ./run_test.sh ConfiguracionEscenario1.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**.

<br>
<p align="center">
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/d57684e9-9c3f-4c5a-bde0-e3aa3276c5c1" />
</p>
<br>

### Resultados

Se definen 3 etapas diferentes de número de usuarios concurrentes para observar el comportamiento del servidor. En particular una prueba de humo, una prueba de carga progresiva, y una prueba de estrés.

#### Prueba de humo

Se define la prueba con los siguientes parametros:

```
USERS=10,20,30,40,50
RAMP=5
SERVER_NAME={amazon_url}
```

Es una prueba rápida y ligera que valida si el sistema está correctamente configurado y responde de forma básica antes de ejecutar las otras pruebas más intensas. Tenemos la siguiente tabla que mide las métricas para el Flujo Completo del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Máx RAM | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-------:|:-------:|:---------------:|
| 10                    | 2.01 req/s          | 855 ms                       | N/A     | N/A     | 0%              |
| 20                    | 3.65 req/s          | 964 ms                       | N/A     | N/A     | 0%              |
| 30                    | 4.58 req/s          | 2775 ms                      | N/A     | N/A     | 0%              |
| 40                    | 5.85 req/s          | 2817 ms                      | N/A     | N/A     | 0%              |
| 50                    | 6.06 req/s          | 4020 ms                      | N/A     | N/A     | 0%              |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

#### Prueba de carga progresiva

Se define la prueba con los siguientes parametros:

```
USERS=75,100,125,150,175
RAMP=5
SERVER_NAME={amazon_url}
```

Es una prueba que evalúa el comportamiento del sistema al aumentar progresivamente la carga, observando cómo varía el rendimiento (latencia, throughput, errores). Tenemos la siguiente tabla que mide las métricas para el Flujo Completo del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Máx RAM | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-------:|:-------:|:---------------:|
| 75                    | 6.65 req/s          | 7120 ms                      | N/A     | N/A     | 0%              |
| 100                   | 6.35 req/s          | 11483 ms                     | N/A     | N/A     | 0%              |
| 125                   | 6.88 req/s          | 13757 ms                     | N/A     | N/A     | 0%              |
| 150                   | 6.69 req/s          | 17956 ms                     | N/A     | N/A     | 0%              |
| 175                   | 6.58 req/s          | 22494 ms                     | N/A     | N/A     | 0%              |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

#### Prueba de estrés

Se define la prueba con los siguientes parametros:

```
USERS=200,250,300,350,400
RAMP=5
SERVER_NAME={amazon_url}
```

Es una prueba que somete al sistema a una carga superior a la esperada para encontrar el punto de ruptura y evaluar su comportamiento bajo condiciones extremas. Tenemos la siguiente tabla que mide las métricas para el Flujo Completo del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Máx RAM | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-------:|:-------:|:---------------:|
| 200                   | ≥ 5 req/s           | ≤ 2.0 s                      | ≤ 70%   | ≤ 75%   | 0%              |
| 250                   | ≥ 5 req/s           | ≤ 2.0 s                      | ≤ 70%   | ≤ 75%   | 0%              |
| 300                   | ≥ 5 req/s           | ≤ 2.0 s                      | ≤ 70%   | ≤ 75%   | 0%              |
| 350                   | ≥ 5 req/s           | ≤ 2.0 s                      | ≤ 70%   | ≤ 75%   | 0%              |
| 400                   | ≥ 5 req/s           | ≤ 2.0 s                      | ≤ 70%   | ≤ 75%   | 0%              |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

Vemos que el limite donde el tiempo de respuesta promedio empieza a superar el umbral de aceptación ocurre con **250 usuarios concurrentes**. Por otro lado, con **240 usuarios concurrentes** se mantiene sin sobrepasar el umbral de los criterios de aceptación. Podemos asumir que para este flujo completo el número de usuarios concurrentes que puede soportar el servidor web es de **240 usuarios concurrentes** antes de que se degrade 

 En particular tenemos los siguientes resultados especificos por endpoint para ese número de usuarios concurrentes:

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Máx RAM   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------:|:---------------:|
| Registro                  | ≥ 5 req/s           | ≤ 2000 ms                    | ≤ 70%     | ≤ 75%     | 0%              |
| Iniciar Sesión            | ≥ 10 req/s          | ≤ 4000 ms                    | ≤ 70%     | ≤ 75%     | 0%              |
| Consultar Videos Públicos | ≥ 20 req/s          | ≤ 2500 ms                    | ≤ 70%     | ≤ 75%     | 0%              |
| Realizar Voto             | ≥ 8 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 75%     | 0%              |
| Consultar Ranking         | ≥ 8 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 75%     | 0%              |



## **Escenario 2**

Para este escenario se define el siguiente flujo de peticiones relacionado con la capa de procesamiento de videos (worker):

**1. Iniciar Sesión:** /api/auth/login

**2. Consultar Videos Propios:** /api/videos

**3. Subir Video:** /api/videos/upload

**4. Consultar Detalle Video:** /api/videos/{id_video}

<br>
<p align="center">
  <img alt="imagen4" src="https://github.com/user-attachments/assets/3651611b-1071-47bc-83e0-d21f7ec3d927" />
</p>
<br>

### **Criterios de Aceptación**

Así mismo, se definen los criterios de aceptación que establecen los umbrales mínimos de desempeño que el sistema debe cumplir para considerarse estable y operativo durante las pruebas de carga. Estos umbrales permiten determinar cuánta carga concurrente puede soportar el servidor sin degradar la experiencia del usuario ni comprometer los recursos del sistema.

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Máx RAM   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------:|:---------------:|
| Iniciar Sesión            | ≥ 10 req/s          | ≤ 4000 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| Consultar Video Propios   | ≥ 20 req/s          | ≤ 2500 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| Subir Video               | ≥ 8 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| Consultar Detalle Video   | ≥ 8 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 75%     | ≤ 1%            |
| **Flujo Completo**        | **≥ 5 req/s**       | **≤ 20500 ms**               | **≤ 70%** | **≤ 75%** | **≤ 1%**       | 

> **Nota:** El *Flujo Completo* agrupa todo el recorrido del usuario (Inicio de Sesión → Consultar Videos Propios → Subir Video → Consultar Detalle Video). Las métricas de esta fila se calculan sobre la ejecución completa del flujo, y su objetivo es validar la estabilidad del sistema durante un escenario de uso real de extremo a extremo.

### **Configuración JMeter (ConfiguracionEscenario2.jmx)**

<br>
<p align="center">
  <img alt="Imagen2" src="https://github.com/user-attachments/assets/3a5309ec-9e6c-4b3d-9dd5-d309cec6eebd" />
</p>
<br>

Primero se definen las siguientes variables de entorno parametrizadas para ejecutar la prueba de carga:

```
USERS=1
RAMP=5
NUM_RUNS=5
PROTOCOL=http
SERVER_NAME=host.docker.internal
AUTH_SERVICE_PORT=8080
VIDEO_SERVICE_PORT=8081
TEST_EMAIL=carlos.ramirez@example.com
TEST_PASSWORD=password123
VIDEO_FILE_PATH=
```

Luego, se define el Transaction Controller (Escenario_2) que ejecutará cada hilo para simular el flujo completo del escenario. Dentro de esta transacción se incluyen los siguientes elementos:

**1. HTTP Request (Request_1_Iniciar_Sesión):** primera petición, donde el hilo inicia sesión utilizando las credenciales del usuario pasado por las variables de entorno. Esta solicitud devuelve un access_token, el cual se extrae mediante un **JSON Extractor** y se almacena en la variable ACCESS_TOKEN.

**2. HTTP Request (Request_2_Consultar_Videos_Propios):** segunda petición, donde el hilo obtiene la lista de videos propios. Esta solicitud requiere una cabecera de autenticación con el formato Authorization: Bearer ${ACCESS_TOKEN}, utilizando el token obtenido en el inicio de sesión.

**3. HTTP Request (Request_3_Subir_Video):** tercera petición, en la que el hilo sube un video a la plataforma y se encola para que el worker lo processe de forma asíncrona. A continuación, se extrae el identificador del primer video usando un **JSON Extractor**, y se guarda en la variable VIDEO_ID. Esta solicitud requiere una cabecera de autenticación con el formato Authorization: Bearer ${ACCESS_TOKEN}, utilizando el token obtenido en el inicio de sesión.

**4. HTTP Request (Request_4_Consultar_Detalle_Video):** cuarta y última petición del flujo, en la que el hilo consulta la información detallada de ese video que acaba de subir. Esta solicitud requiere una cabecera de autenticación con el formato Authorization: Bearer ${ACCESS_TOKEN}, utilizando el token obtenido en el inicio de sesión.

### Ejecución de las Pruebas

Para ejecutar la prueba de carga se ejecuta los siguientes comandos para levantar el contenedor con JMeter:

```
cd capacity-planning/Entrega_2/jmeter
```
```
docker build -t jmeter-cli:5.6.3 .
```
```
docker compose up -d
```

Ahora en otra terminal bash sobre la misma ruta se ejecuta el siguiente script para correr la prueba:

```
cd capacity-planning/Entrega_2/jmeter
```
```
USERS=1 RAMP=5 NUM_RUNS=5 SERVER_NAME=host.docker.internal ./run_test.sh ConfiguracionEscenario2.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**.

<br>
<p align="center">
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/4b820b81-e080-4187-a013-54d23c16a478" />
</p>
<br>
