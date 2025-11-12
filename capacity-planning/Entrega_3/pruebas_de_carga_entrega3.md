# **Pruebas de Carga Entrega 3**

## **Herramientas**

Para las pruebas de carga se utilizará **Apache JMeter**, una herramienta de código abierto diseñada para realizar pruebas de rendimiento y medir el comportamiento de aplicaciones web y otros servicios. JMeter permite simular múltiples usuarios concurrentes que acceden a una aplicación, con el fin de evaluar su capacidad de respuesta y estabilidad bajo diferentes niveles de carga.

Además, se utilizará **Amazon CloudWatch** para el monitoreo de recursos en la infraestructura de AWS. CloudWatch recopila métricas como el uso de CPU, memoria, disco y red en tiempo real, lo que permite analizar el rendimiento del sistema durante las pruebas de carga y detectar posibles cuellos de botella o degradaciones en el servicio.

<br>

## **Arquitectura del Entorno de Pruebas**

La arquitectura del entorno de pruebas se basa en un enfoque totalmente contenedorizado para garantizar portabilidad y consistencia en la ejecución.

Se definió un Dockerfile y un docker-compose.yml que permiten levantar un contenedor local con una versión ligera de Apache JMeter en modo CLI (sin interfaz gráfica), junto con Java 17, necesario para su ejecución. Este contenedor se utiliza exclusivamente para ejecutar los scripts de pruebas de carga de forma automatizada. Por otro lado, CloudWatch ya es un servicio integrado de AWS por lo que sus métricas se consiguen directamente desde la consola de amazon.

<br>

## **Métricas Principales**

Las pruebas de carga evaluarán el desempeño del sistema en función de cuatro métricas principales:

| Métrica | Descripción | Fuente/Herramienta |
|----------|--------------|----------------------|
| **Throughput (req/s)** | Número de peticiones procesadas por segundo. Mide la capacidad de procesamiento del sistema. | JMeter Summary Report |
| **Tiempo de Respuesta Promedio (s)** | Tiempo transcurrido desde que el usuario envía una solicitud hasta recibir la respuesta completa. | JMeter Summary Report |
| **Utilización de Recursos (%)** | Porcentaje de uso de CPU y memoria RAM del servidor durante la carga. | Amazon CloudWatch |
| **Tasa de errores (%)** | Porcentaje de respuestas HTTP con errores (4xx, 5xx) respecto al total de peticiones. | JMeter Summary Report |

<br>

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
| Registro                  | ≥ 7 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| Iniciar Sesión            | ≥ 7 req/s           | ≤ 4000 ms                    | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| Consultar Videos Públicos | ≥ 10 req/s          | ≤  500 ms                    | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| Realizar Voto             | ≥ 10 req/s          | ≤  300 ms                    | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| Consultar Ranking         | ≥ 10 req/s          | ≤  500 ms                    | ≤ 70%     | ≤ 89%     | ≤ 1%            |
| **Flujo Completo**        | **≥ 5 req/s**       | **≤ 11300 ms**               | **≤ 70%** | **≤ 80%** | **≤ 1%**       | 

> **Nota:** El *Flujo Completo* agrupa todo el recorrido del usuario (Registro → Inicio de Sesión → Consultar Videos Publicos → Realizar Voto → Consultar Ranking). Las métricas de esta fila se calculan sobre la ejecución completa del flujo, y su objetivo es validar la estabilidad del sistema durante un escenario de uso real de extremo a extremo.

### **Configuración JMeter ([ConfiguracionEscenario1.jmx](ConfiguracionEscenario1.jmx))**

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
SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com
ALB_PORT=80
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
cd capacity-planning/Entrega_3/jmeter
```
```
docker build -t jmeter-cli:5.6.3 .
```
```
docker compose up -d
```

Una vez levantado el contenedor con Jmeter se ejecuta el siguiente script para correr la prueba:

```
USERS=1 RAMP=5 NUM_RUNS=5 SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com ./run_test.sh ConfiguracionEscenario1.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**.

<br>
<p align="center">
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/d57684e9-9c3f-4c5a-bde0-e3aa3276c5c1" />
</p>
<br>

### Resultados

Se definen diferentes pruebas con un número creciente de usuarios concurrentes para observar el comportamiento del servidor. Para ello, se definen las pruebas con los siguientes parametros:

```
USERS=10
RAMP=5
NUM_RUNS=5
SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com
```

Tenemos la siguiente tabla que contiene las métricas del **Flujo Completo** del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Máx RAM | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-------:|:-------:|:---------------:|
| 10                    | 1.59 req/s          |  2746 ms                     |  4%     |   6%    |     0%          |
| 25                    | 3.65 req/s          |  3015 ms                     |  8%     |  10%    |     0%          |
| 50                    | 5.31 req/s          |  4941 ms                     | 14%     |  16%    |     0%          |
| 75                    | 5.34 req/s          |  8464 ms                     | 20%     |  22%    |     0%          |
| **85**                | **5.20 req/s**      | **9780 ms**                 | **24%** | **25%** |     **0%**      | 
| 100                   | 5.71 req/s          | 12293 ms                     | 27%     |  30%    |     0%          |
| 125                   | 6.01 req/s          | 15165 ms                     | 33%     |  36%    |     0%          |
| 150                   | 5.83 req/s          | 19822 ms                     | 38%     |  38%    |     2%          |
| 175                   | 4.63 req/s          | 22742 ms                     | 46%     |  45%    |     3%          |
| 200                   | 4.42 req/s          | 23229 ms                     | 49%     |  52%    |    14%          |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

Vemos que el limite donde el tiempo de respuesta promedio empieza a superar el umbral de aceptación ocurre con **100 usuarios concurrentes**. Por otro lado, con **85 usuarios concurrentes** se mantiene sin sobrepasar el umbral de los criterios de aceptación.

Podemos asumir que para este escenario 1 el número de usuarios concurrentes que puede soportar el servidor web es de **85 usuarios concurrentes** antes de que se degrade. Podemos observar los siguientes resultados especificos por endpoint:

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Máx RAM   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------:|:---------------:|
| Registro                  |  7.47 req/s         | 5331 ms                      |   24%     |  25%      | 0%              |
| Iniciar Sesión            |  7.57 req/s         | 4077 ms                      |   24%     |  25%      | 0%              |
| Consultar Videos Públicos | 14.72 req/s         |  117 ms                      |   24%     |  25%      | 0%              |
| Realizar Voto             | 14.72 req/s         |   98 ms                      |   24%     |  25%      | 0%              |
| Consultar Ranking         | 13.74 req/s         |   95 ms                      |   24%     |  25%      | 0%              |

<br>

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
| Iniciar Sesión            | ≥ 7 req/s           | ≤ 4000 ms                    | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| Consultar Video Propios   | ≥ 3 req/s           | ≤ 6000 ms                    | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| Subir Video               | ≥ 1 req/s           | ≤ 20000 ms                   | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| Consultar Detalle Video   | ≥ 2 req/s           | ≤ 1000 ms                    | ≤ 70%     | ≤ 80%     | ≤ 1%            |
| **Flujo Completo**        | **≥ 1 req/s**       | **≤ 31000 ms**               | **≤ 70%** | **≤ 80%** | **≤ 1%**       | 

> **Nota:** El *Flujo Completo* agrupa todo el recorrido del usuario (Inicio de Sesión → Consultar Videos Propios → Subir Video → Consultar Detalle Video). Las métricas de esta fila se calculan sobre la ejecución completa del flujo, y su objetivo es validar la estabilidad del sistema durante un escenario de uso real de extremo a extremo.

### **Configuración JMeter ([ConfiguracionEscenario2.jmx](ConfiguracionEscenario2.jmx))**

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
SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com
ALB_PORT=80
TEST_EMAIL=carlos.ramirez@example.com
TEST_PASSWORD=password123
VIDEO_FILE_PATH=../../../collections/mp4_16mb_test.mp4
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

Una vez levantado el contenedor con Jmeter se ejecuta el siguiente script para correr la prueba:

```
USERS=1 RAMP=5 NUM_RUNS=5 SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com ./run_test.sh ConfiguracionEscenario2.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**.

<br>
<p align="center">
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/4b820b81-e080-4187-a013-54d23c16a478" />
</p>
<br>

### Resultados

Se definen diferentes pruebas con un número creciente de usuarios concurrentes para observas el comportameinto del servidor. Para ello, se definen las pruebas con los siguientes parametros:

```
USER=10
RAMP=5
NUM_RUNS=5
SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com
```

Tenemos la siguiente tabla que contiene las métricas del Flujo Completo del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Máx RAM | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-------:|:-------:|:---------------:|
| 10                    | 0.87 req/s          |  7092 ms                     |  4%     |   6%    |     0%          |
| 20                    | 1.41 req/s          |  9737 ms                     |  9%     |  11%    |     0%          |
| 30                    | 1.52 req/s          | 14968 ms                     | 12%     |  15%    |     0%          |
| 40                    | 1.64 req/s          | 16641 ms                     | 15%     |  19%    |     0%          |
| 50                    | 1.69 req/s          | 20364 ms                     | 18%     |  22%    |     0%          | 
| 60                    | 1.70 req/s          | 23211 ms                     | 21%     |  25%    |     0%          |
| **70**                | **1.72 req/s**      | **25774 ms**                 | **24%** | **28%** |     **0%**      |
| 80                    | 1.77 req/s          | 32573 ms                     | 30%     |  34%    |     0%          |
| 90                    | 1.83 req/s          | 34582 ms                     | 35%     |  40%    |     0%	       |
| 100                   | 1.85 req/s          | 37095 ms                     | 42%     |  47%    |     0%          |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

Vemos que el limite donde el tiempo de respuesta promedio empieza a superar el umbral de aceptación ocurre con **80 usuarios concurrentes**. Por otro lado, con **70 usuarios concurrentes** se mantiene sin sobrepasar el umbral de los criterios de aceptación.

Podemos asumir que para este escenario 1 el número de usuarios concurrentes que puede soportar el servidor web es de **70 usuarios concurrentes** antes de que se degrade. Podemos observar los siguientes resultados especificos por endpoint:

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Máx RAM   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------:|:---------------:|
| Iniciar Sesión            |  8.90 req/s         |  2151 ms                     |   24%     |  28%      | 0%              |
| Consultar Videos Propios  |  3.36 req/s         |  5605 ms                     |   24%     |  28%      | 0%              |
| Subir Video               |  1.96 req/s         | 17745 ms                     |   24%     |  28%      | 0%              |
| Consultar Detalle Video   |  2.57 req/s         |   271 ms                     |   24%     |  28%      | 0%              |

<br>

## Conclusiones

### Escenario 1

Para el escenario 1 tenemos las siguientes gráficas que ilustran el comportamiento del servidor durante las pruebas de carga:

<p align="center">
  <img alt="Imagen100" src="https://github.com/user-attachments/assets/14b951cc-4a36-47a5-b5f1-24269d351370" />
</p>

<p align="center">
  <img alt="Imagen101" src="https://github.com/user-attachments/assets/b3b1580f-f9b8-4d92-93e4-791ce2818c18" />
</p>

<p align="center">
  <img alt="Imagen102" src="https://github.com/user-attachments/assets/bd64a909-f03b-4ec2-9f19-6e3f646cf463" />
</p>

<p align="center">
  <img alt="Imagen103" src="https://github.com/user-attachments/assets/5265e438-ecfc-4db9-a805-37837d92b495" />
</p>



### Escenario 2

Para el escenario 2 tenemos las siguientes gráficas que ilustran el comportamiento del servidor durante las pruebas de carga:

<p align="center">
  <img alt="Imagen100" src="https://github.com/user-attachments/assets/9e820560-e620-457f-90af-59a1c19ee623" />
</p>

<p align="center">
  <img alt="Imagen101" src="https://github.com/user-attachments/assets/a92d3c0e-2afb-4dff-a62d-ea0a6058d130" />
</p>

<p align="center">
  <img alt="Imagen102" src="https://github.com/user-attachments/assets/2792fa92-621a-4a55-9764-6de044f953f3" />
</p>

<p align="center">
  <img alt="Imagen103" src="https://github.com/user-attachments/assets/595d03f9-cea9-4f08-bb25-52b857491554" />
</p>



<br>

## Consideraciones para escalar la aplicación