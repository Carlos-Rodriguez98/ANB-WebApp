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
  <img width="921" height="882" alt="Imagen1" src="https://github.com/user-attachments/assets/8f9cbaa2-5025-4b6d-91e9-ae20a8cb1499" />
</p>

### **Criterios de Aceptación**

Así mismo, se definen los criterios de aceptación junto con los umbrales de desempeño esperados para establecer cuánta carga de usuarios puede soportar el servidor:

| Endpoint | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Máx RAM | Tasa de Errores |
|:--------:|:-------------------:|:----------------------:|:-------:|:-------:|:---------------:|
| Registro                  | ≥ 5 req/s      | ≤ 2.0 s      | ≤ 70%     | ≤ 75%     | ≤ 1%     |
| Iniciar Sesión            | ≥ 10 req/s     | ≤ 4.0 s      | ≤ 70%     | ≤ 75%     | ≤ 1%     |
| Consultar Videos Públicos | ≥ 20 req/s     | ≤ 2.5 s      | ≤ 70%     | ≤ 75%     | ≤ 1%     |
| Realizar Voto             | ≥ 8 req/s      | ≤ 6.0 s      | ≤ 70%     | ≤ 75%     | ≤ 1%     |
| Consultar Ranking         | ≥ 8 req/s      | ≤ 6.0 s      | ≤ 70%     | ≤ 75%     | ≤ 1%     |
| **Flujo Completo**        | **≥ 5 req/s** | **≤ 20.5 s** | **≤ 70%** | **≤ 75%** | **≤ 1%** | 

### **Configuración JMeter (ConfiguracionEscenario1.jmx)**

<br>
<p align="center">
  <img width="492" height="433" alt="Imagen2" src="https://github.com/user-attachments/assets/04fe0798-ea07-46d4-9068-e5ab23d2d0a1" />
</p>
<br>

Primero se definen las siguientes variables de entorno parametrizadas para ejecutar la prueba de carga:

```
USERS=1
RAMP=5
PROTOCOL=http
SERVER_NAME=host.docker.internal
AUTH_SERVICE_PORT=8080
PUBLIC_VIDEO_SERVICE_PORT=8082
RANKING_SERVICE_PORT=8083
```

Luego, se define el Transaction Controller (Escenario_1) que ejecutará cada hilo para simular el flujo completo del escenario. Dentro de esta transacción se incluyen los siguientes elementos:

**1. JSR223 Sampler (Generar TEST_EMAIL y TEST_PASSWORD):** script escrito en Groovy que se ejecuta al inicio del flujo para generar los datos de prueba que utilizará cada hilo. En particular, se crean las variables TEST_EMAIL y TEST_PASSWORD.

**2. HTTP Request (Request_Registrarse):** primera petición del flujo, correspondiente al registro de usuario. En ella se envía el cuerpo de la solicitud con las variables de email y contraseña generadas, creando así un usuario único para cada hilo.

**3. HTTP Request (Request_Iniciar_Sesión):** segunda petición, donde el hilo inicia sesión utilizando las credenciales del usuario recién creado. Esta solicitud devuelve un access_token, el cual se extrae mediante un **JSON Extractor** y se almacena en la variable ACCESS_TOKEN.

**4. HTTP Request (Request_Consultar_Videos_Públicos):** tercera petición, donde el hilo obtiene la lista de videos públicos disponibles para votar. A continuación, se extrae el identificador del primer video usando un **JSON Extractor**, y se guarda en la variable VIDEO_ID.

**5. HTTP Request (Request_Realizar_Voto):** cuarta petición, en la que el hilo emite un voto para el video obtenido anteriormente. Esta solicitud requiere una cabecera de autenticación con el formato Authorization: Bearer ${ACCESS_TOKEN}, utilizando el token obtenido en el inicio de sesión.

**6. HTTP Request (Request_Consultar_Ranking):** quinta y última petición del flujo, en la que el hilo consulta la tabla de ranking de los participantes.

### Ejecución de las Pruebas

Para ejecutar la prueba de carga se ejecuta los siguientes comandos para levantar el contenedor con JMeter:

```
cd capacity-planning/Entrega_2/jmeter

docker build -t jmeter-cli:5.6.3 .

docker-compose up -d
```

Ahora en otra terminal bash sobre la misma ruta se ejecuta el siguiente script para correr la prueba:

```
cd capacity-planning/Entrega_2/jmeter

SERVER_NAME=host.docker.internal USERS=1 RAMP=5 ./run_test.sh ConfiguracionEscenario1.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**.

<br>
<p align="center">
  <img width="2550" height="1330" alt="Imagen3" src="https://github.com/user-attachments/assets/d57684e9-9c3f-4c5a-bde0-e3aa3276c5c1" />
</p>
<br>

### Resultados

Para una **prueba smoke** se obtienen los siguientes resultados:





