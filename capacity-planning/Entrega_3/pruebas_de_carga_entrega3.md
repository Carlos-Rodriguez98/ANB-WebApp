# **Pruebas de Carga - Entrega 3**

## **Herramientas**

Para las pruebas de carga se utilizará **Apache JMeter**, una herramienta de código abierto diseñada para realizar pruebas de rendimiento y medir el comportamiento de aplicaciones web y otros servicios. JMeter permite simular múltiples usuarios concurrentes que acceden a una aplicación, con el fin de evaluar su capacidad de respuesta y estabilidad bajo diferentes niveles de carga.

Además, se utilizará **Amazon CloudWatch** para el monitoreo de recursos en la infraestructura de AWS. CloudWatch recopila métricas como el uso de CPU, disco y red en tiempo real, lo que permite analizar el rendimiento del sistema durante las pruebas de carga y detectar posibles cuellos de botella o degradaciones en el servicio.

<br>

## **Arquitectura del Entorno de Pruebas**

La arquitectura del entorno de pruebas se basa en un enfoque totalmente contenedorizado para garantizar portabilidad y consistencia en la ejecución.

Se definió un Dockerfile y un docker-compose.yml que permiten levantar un contenedor local con una versión ligera de Apache JMeter en modo CLI (sin interfaz gráfica), junto con Java 17, necesario para su ejecución. Este contenedor se utiliza exclusivamente para ejecutar los scripts de pruebas de carga de forma automatizada. Por otro lado, CloudWatch ya es un servicio integrado de AWS por lo que sus métricas se consiguen directamente desde la consola de amazon desde un dashboard definido en terraform.

<br>

## **Métricas Principales**

Las pruebas de carga evaluarán el desempeño del sistema en función de cuatro métricas principales:

| Métrica | Descripción | Fuente/Herramienta |
|----------|--------------|----------------------|
| **Throughput (req/s)** | Número de peticiones procesadas por segundo. Mide la capacidad de procesamiento del sistema. | JMeter Summary Report |
| **Tiempo de Respuesta Promedio (s)** | Tiempo transcurrido desde que el usuario envía una solicitud hasta recibir la respuesta completa. | JMeter Summary Report |
| **Utilización de Recursos (%)** | Porcentaje de uso de CPU del ASG durante la carga. | Amazon CloudWatch |
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

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU ASG | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:-----------:|:---------------:|
| Registro                  | ≥ 7 req/s           | ≤ 6000 ms                    | ≤ 70%       | ≤ 1%            |
| Iniciar Sesión            | ≥ 7 req/s           | ≤ 4000 ms                    | ≤ 70%       | ≤ 1%            |
| Consultar Videos Públicos | ≥ 10 req/s          | ≤  500 ms                    | ≤ 70%       | ≤ 1%            |
| Realizar Voto             | ≥ 10 req/s          | ≤  300 ms                    | ≤ 70%       | ≤ 1%            |
| Consultar Ranking         | ≥ 10 req/s          | ≤  500 ms                    | ≤ 70%       | ≤ 1%            |
| **Flujo Completo**        | **≥ 5 req/s**       | **≤ 11300 ms**               | **≤ 70%**   | **≤ 1%**        | 

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
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/f40e55aa-9992-4249-95df-29666ade9519" />
</p>
<br>

Para visualizar la métrica de uso de CPU promedio del auto scaling group de los servidores web se abre el dashboard configurado en Amazon CloudWatch:






### Resultados

Se definen diferentes pruebas con un número creciente de usuarios concurrentes para observar el comportamiento del servidor. Para ello, se definen las pruebas con los siguientes parametros:

```
USERS=10
RAMP=5
NUM_RUNS=5
SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com
```

Tenemos la siguiente tabla que contiene las métricas del **Flujo Completo** del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU ASG | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-----------:|:---------------:|
| 10                    | 1.59 req/s          |  2746 ms                     |  4%         |     0%          |
| 25                    | 3.65 req/s          |  3015 ms                     |  8%         |     0%          |
| 50                    | 5.31 req/s          |  4941 ms                     | 14%         |     0%          |
| 75                    | 5.34 req/s          |  8464 ms                     | 20%         |     0%          |
| **85**                | **5.20 req/s**      | **9780 ms**                  | **24%**     |   **0%**        | 
| 100                   | 5.71 req/s          | 12293 ms                     | 27%         |     0%          |
| 125                   | 6.01 req/s          | 15165 ms                     | 33%         |     0%          |
| 150                   | 5.83 req/s          | 19822 ms                     | 38%         |     2%          |
| 175                   | 4.63 req/s          | 22742 ms                     | 46%         |     3%          |
| 200                   | 4.42 req/s          | 23229 ms                     | 49%         |    14%          |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

Vemos que el limite donde el tiempo de respuesta promedio empieza a superar el umbral de aceptación ocurre con **100 usuarios concurrentes**. Por otro lado, con **85 usuarios concurrentes** se mantiene sin sobrepasar el umbral de los criterios de aceptación.

Podemos asumir que para este escenario 1 el número de usuarios concurrentes que puede soportar el servidor web es de **85 usuarios concurrentes** antes de que se degrade. Podemos observar los siguientes resultados especificos por endpoint:

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU ASG  | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:------------:|:---------------:|
| Registro                  |  7.47 req/s         | 5331 ms                      |   24%        | 0%              |
| Iniciar Sesión            |  7.57 req/s         | 4077 ms                      |   24%        | 0%              |
| Consultar Videos Públicos | 14.72 req/s         |  117 ms                      |   24%        | 0%              |
| Realizar Voto             | 14.72 req/s         |   98 ms                      |   24%        | 0%              |
| Consultar Ranking         | 13.74 req/s         |   95 ms                      |   24%        | 0%              |

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

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU ASG | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:-----------:|:---------------:|
| Iniciar Sesión            | ≥ 7 req/s           | ≤ 4000 ms                    | ≤ 70%       | ≤ 1%            |
| Consultar Video Propios   | ≥ 3 req/s           | ≤ 6000 ms                    | ≤ 70%       | ≤ 1%            |
| Subir Video               | ≥ 1 req/s           | ≤ 20000 ms                   | ≤ 70%       | ≤ 1%            |
| Consultar Detalle Video   | ≥ 2 req/s           | ≤ 1000 ms                    | ≤ 70%       | ≤ 1%            |
| **Flujo Completo**        | **≥ 1 req/s**       | **≤ 31000 ms**               | **≤ 70%**   | **≤ 1%**        | 

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
USERS=1 RAMP=5 NUM_RUNS=5 SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com ./run_test.sh ConfiguracionEscenario2.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**.

<br>
<p align="center">
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/e0dcf463-a757-4f37-a8cd-8ec08487b00a" />
</p>
<br>

Para visualizar la métrica de uso de CPU promedio del auto scaling group de los servidores web se abre el dashboard configurado en Amazon CloudWatch:




### Resultados

Se definen diferentes pruebas con un número creciente de usuarios concurrentes para observas el comportameinto del servidor. Para ello, se definen las pruebas con los siguientes parametros:

```
USER=10
RAMP=5
NUM_RUNS=5
SERVER_NAME=anbapp-alb-543666967.us-east-1.elb.amazonaws.com
```

Tenemos la siguiente tabla que contiene las métricas del Flujo Completo del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU ASG | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-----------:|:---------------:|
| 10                    | 0.87 req/s          |  7092 ms                     |  4%         |     0%          |
| 20                    | 1.41 req/s          |  9737 ms                     |  9%         |     0%          |
| 30                    | 1.52 req/s          | 14968 ms                     | 12%         |     0%          |
| 40                    | 1.64 req/s          | 16641 ms                     | 15%         |     0%          |
| 50                    | 1.69 req/s          | 20364 ms                     | 18%         |     0%          | 
| 60                    | 1.70 req/s          | 23211 ms                     | 21%         |     0%          |
| **70**                | **1.72 req/s**      | **25774 ms**                 | **24%**     |   **0%**        |
| 80                    | 1.77 req/s          | 32573 ms                     | 30%         |     0%          |
| 90                    | 1.83 req/s          | 34582 ms                     | 35%         |     0%	         |
| 100                   | 1.85 req/s          | 37095 ms                     | 42%         |     0%          |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

Vemos que el limite donde el tiempo de respuesta promedio empieza a superar el umbral de aceptación ocurre con **80 usuarios concurrentes**. Por otro lado, con **70 usuarios concurrentes** se mantiene sin sobrepasar el umbral de los criterios de aceptación.

Podemos asumir que para este escenario 1 el número de usuarios concurrentes que puede soportar el servidor web es de **70 usuarios concurrentes** antes de que se degrade. Podemos observar los siguientes resultados especificos por endpoint:

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU ASG | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:-----------:|:---------------:|
| Iniciar Sesión            |  8.90 req/s         |  2151 ms                     |   24%       | 0%              |
| Consultar Videos Propios  |  3.36 req/s         |  5605 ms                     |   24%       | 0%              |
| Subir Video               |  1.96 req/s         | 17745 ms                     |   24%       | 0%              |
| Consultar Detalle Video   |  2.57 req/s         |   271 ms                     |   24%       | 0%              |

<br>

## Conclusiones

### Escenario 1

Para el escenario 1 tenemos las siguientes gráficas que ilustran el comportamiento del servidor durante las pruebas de carga:

<p align="center">
  <img alt="Imagen100" src="https://github.com/user-attachments/assets/fb402e64-c7c2-4cc5-978a-5a0a0e0a5505" />
</p>

<p align="center">
  <img alt="Imagen101" src="https://github.com/user-attachments/assets/c1875ff0-fa1b-4017-850f-b5e401b9be2d" />
</p>

<p align="center">
  <img alt="Imagen102" src="https://github.com/user-attachments/assets/9008f3e3-4bae-4120-bcd5-c08c005db070" />
</p>

<p align="center">
  <img alt="Imagen103" src="https://github.com/user-attachments/assets/ca23a9b5-87bb-4683-bc73-22c5c4a14ad0" />
</p>

**1. Capacidad Máxima y Estabilidad Operativa:** La nueva arquitectura con balanceador de carga demuestra una mejora radical en el rendimiento, estableciendo la capacidad máxima estable en 85 usuarios concurrentes. En este punto, el sistema cumple con todos los criterios de aceptación del flujo completo: procesa 5.20 req/s (superando el objetivo de 5 req/s), mantiene un tiempo de respuesta promedio de 9780ms (por debajo del límite de 11300ms) y opera con una utilización de recursos mínima (24% CPU) y un 0% de errores.

**2.Punto de Degradación del Servicio:** El punto de degradación de la experiencia del usuario se identifica con 100 usuarios concurrentes, momento en el que el Tiempo de Respuesta Pormedio (12293ms) se convierte en la primera métrica en fallar al superar el umbral de 11300ms. Es notable que, incluso en este punto de fallo de latencia, la utilización de recursos del servidor sigue siendo extremadamente baja (27% CPU) y la tasa de errores permanece en 0%, lo que demuestra la eficiencia del balanceo de carga.

**3. Identificación del Cuello de Botella:** A pesar de la mejora en la escalablidad, el cuello de bottela fundamental sigue estando en la lógica de la aplicación, específicamente en los endpoints de autenticación. En la carga estable de 85 usuarios, las peticiones de "Registro" (5331ms) y "Iniciar Sesión (4077ms) consumen más de 9.4 segundos del tiempo total del flujo (9.7segundos). Esto prueba que, si bien la arquitectura ahora puede manejar más usuarios simultáneos, el rendimiento general sigue estando limitado por la latencia de este servicio de autenticación.

**4. Límites de Resistencia y Saturación del Sistema:** El sistema exhibe una alta resistencia, manejando hasta 125 usuarios concurrentes sin generar un solo error (0%). El punto de saturación (fallo de servicio) se alcanza con 150 usuarios, donde la Tasa de Errores (2%) supera por primera vez el umbral del 1%. Más allá de este punto, con 175 usuarios, el sistema colapsa: el throughput cae drásticamente (de 6.01 req/s a 4.63 req/s) y los errores se disparan, indicando que el sistema ya no puede manejar la demanda.

### Escenario 2

Para el escenario 2 tenemos las siguientes gráficas que ilustran el comportamiento del servidor durante las pruebas de carga:

<p align="center">
  <img alt="Imagen200" src="https://github.com/user-attachments/assets/f8c3388f-830f-46e4-80f7-4a68bf587d55" />
</p>

<p align="center">
  <img alt="Imagen201" src="https://github.com/user-attachments/assets/15eef8cc-734d-4691-b2ac-d4c150621727" />
</p>

<p align="center">
  <img alt="Imagen202" src="https://github.com/user-attachments/assets/39a5f236-8f4c-4a93-979b-f9a5194eaff3" />
</p>

<p align="center">
  <img alt="Imagen203" src="https://github.com/user-attachments/assets/44dad4d4-8193-4c06-80c2-6472dd363a77" />
</p>

**1. Capacidad Máxima y Estabilidad Operativa:**  La capacidad máxima estable para el Escenario 2 se alcanza con 70 usuarios concurrentes. En este punto, el sistema cumple con todos los criterios de aceptación: el throughput del flujo completo es de 1.72 req/s (superando el mínimo de 1 req/s), el tiempo de respuesta promedio es de 25774ms (dentro del límite de 31000ms), y la utilización de recursos es notablemente baja, con solo 24% de CPU, todo con tasa de errores del 0%.

**2. Punto de Degradación del Servicio:** El punto de degradación se identifica al escalar a 80 usuarios concurrentes, momento en el que el Tiempo de Respuesta Promedio (32573ms) se convierte en la primera métrica en fallar, superando el umbral de aceptación de 31000ms. Este fallo en la latencia ocurre a pesar de que los recursos del servidor (30% CPU) y la tasa de errores (0%) todavía están muy por debajo de sus límites, indicando que la degradación es de rendimiento y no de estabilidad del servidor.

**3. Identificación del Cuello de Botella:** El cuello de botella de este escenario es, de forma inequívoca, la operación de "Subir Video". En la carga estable de 70 usuarios, esta única petición consume un promedio de 17745ms, lo que representa aproximadamente el 69% del tiempo total del flujo (25774ms). Dado que la utilización de CPU es mínima, el factor limitante no es el poder de procesamiento del servidor, sino el anchon de banda y la E/S de red necesarios para gestionar 70 subidas de archivos de 16MB de forma simultánea.

**4. Límites de Resistencia y Tasa de Errores:** El sistema demuestra una resistencia a errores en este escenario. Durante las pruebas el sistema nunca se acerca a un punto de saturación de recursos (CPU) ni de errores dentro del rango de pruebas. El único factor limitante es la degradación del tiempo de respuesta, impulsada casi en su totalidad por la naturaleza intensiva en red de la subida de archivos.

<br>

## Mejoras con respecto a la anterior entrega

La implementación de la arquitectura de la Entrega 3, centrada en la alta disponibilidad y el desacoplamiento de servicios, ha transformado radicalmente el rendimiento del sistema en comparación con la arquitectura monolítica de servidor único de la entrega anterior. La introducción de un Application Load Balancer (ALB), un Auto Scaling Group (ASG), el almacenamiento de objetos en S3, el procesamiento asíncrono con Amazon SQS y el cacheo con Redis, ha eliminado los cuellos de botella de recursos de la instancia única y ha elevado la capacidad del sistema a un nuevo orden de magnitud.

**Escenario 1 (Flujo Capa Web)**

En el Escenario 1, la capacidad máxima de usuarios concurrentes estables aumentó en un 112.5%, pasando de 40 usuarios en la arquitectura anterior a 85 usuarios en la nueva. El impacto más significativo se observa en el throughput (capacidad de procesamiento), que en el punto máximo estable creció un 490%, saltando de 0.88 req/s a 5.20 req/s. Este éxito es atribuible directamente al ALB y al Auto Scaling Group, que distribuyen la carga entre múltiples instancias (2-3), y a Redis, que reduce la carga en endpoints de consulta frecuente. La nueva arquitectura maneja más del doble de usuarios utilizando menos recursos proporcionales (solo 24% de CPU).

| Métrica | Arquitectura Entrega 2 | Arquitectura Entrega 3 | Mejora |
|:-------:|:----------------------:|:----------------------:|:------:|
|Usuarios Concurrentes | 40 | 85 | +112% |
| Throughput Promedio | 0.88 req/s | 5.20 req/s | +490% |
| Tiempo de Repuesta | 9988 ms | 9780 ms | Similar |
| Uso de CPU (Máx) | 30% | 24% | Más eficiente |


**Escenario 2 (Flujo Capa Procesamiento)**

En el Escenario 2, los beneficios de la nueva arquitectura son aún más evidentes. Aunque el tiempo de respuesta por usuario sigue dominado por el cuello de botella físico de la subida del archivo de 16MB (aprox. 17 segundos en ambos tests), la capacidad del sistema para manejar cargas simultáneas ha explotado. La capacidad de usuarios aumentó en un 75% (de 40 a 70), y el throughput total se disparó en un 514% (de 0.28 a 1.72 req/s). Esto se debe a la migración del almacenamiento a S3 y, fundamentalmente, al desacoplamiento del procesamiento mediante SQS y un worker dedicado. Los servidores web (ASG) ya no gastan recursos en procesar o almacenar archivos; simplemente gestionan la subida a S3 y encolan el mensaje.

| Métrica | Arquitectura Entrega 2 | Arquitectura Entrega 3 | Mejora |
|:-------:|:----------------------:|:----------------------:|:------:|
| Usuarios Concurrentes | 40 | 70 | +75% |
| Throughput Promedio | 0.28 req/s | 1.72 req/s | +514% |
| Tiempo de Repuesta | 25872 ms | 25774 ms | Similar |
| Uso de CPU (Máx) | 48% | 28% | Más eficiente |

<br>

## Consideraciones para escalar la aplicación

Aunque la arquitectura de la Entrega 3 implementa mejoras significativas en escalabilidad (ALB, ASG para web, S3), aún existen componentes que pueden optimizarse para manejar un crecimiento a gran escala. Las siguientes estrategias se centran en eliminar los cuellos de botella restantes y mejorar la resiliencia global.

**1. Implementar Auto Scaling para la Capa de Workers**

La arquitectura actual utiliza una única instancia de worker, lo cual representa un cuello de botella para el procesamiento asíncrono. Si 100 usuarios suben videos (Escenario 2), todos los trabajos de procesamiento se encolarán en SQS y serán procesados secuencialmente por ese único worker.

Por ello se propone reemplazar la instancia EC2 privada única por un Grupo de Autoescalado (ASG) para los workers. La capacidad de procesamiento de videos se ajustará dinámicamente a la demanda de subidas, reduciendo drásticamente el tiempo total desde que el usuario sube el video hasta que está procesado y disponible.

**2. Habilitar Multi-AZ en RDS para Alta Disponibilidad**

La configuración actual de RDS (mencionada en el reporte) no está en modo Multi-AZ. Esto significa que cualquier fallo de hardware en la instancia de RDS o mantenimiento de AWS provocará una interrupción total del servicio, ya que toda la aplicación depende de ella.

Se propone habilitar la opción Multi-AZ para la instancia de RDS. Es un simple cambio de configuración en RDS. AWS mantendrá automáticamente una réplica síncrona de la base de datos en una Zona de Disponibilidad diferente. En caso de fallo, RDS conmutará automáticamente (failover) a la réplica en la otra AZ, garantizando la continuidad del negocio y la alta disponibilidad de la base de datos con un tiempo de inactividad mínimo.