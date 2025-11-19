# **Pruebas de Carga - Entrega 2**

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
| **Utilización de Recursos (%)** | Porcentaje de uso de CPU del servidor durante la carga. | Amazon CloudWatch |
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

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------------:|
| Registro                  | ≥ 1.5 req/s         | ≤ 6000 ms                    | ≤ 70%     | ≤ 1%            |
| Iniciar Sesión            | ≥ 1.5 req/s         | ≤ 4000 ms                    | ≤ 70%     | ≤ 1%            |
| Consultar Videos Públicos | ≥ 1.7 req/s         | ≤  500 ms                    | ≤ 70%     | ≤ 1%            |
| Realizar Voto             | ≥ 1.7 req/s         | ≤  300 ms                    | ≤ 70%     | ≤ 1%            |
| Consultar Ranking         | ≥ 1.7 req/s         | ≤  500 ms                    | ≤ 70%     | ≤ 1%            |
| **Flujo Completo**        | **≥ 0.8 req/s**     | **≤ 11300 ms**               | **≤ 70%** | **≤ 1%**        | 

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

Para ejecutar la prueba de carga se ejecuta los siguientes comandos en una terminal bash para levantar el contenedor con JMeter:

```
cd capacity-planning/Entrega_2/jmeter
```
```
docker build -t jmeter-cli:5.6.3 .
```
```
docker compose up -d
```

Una vez levantado el contenedor con Jmeter se puede ejecutar el siguiente script para correr la prueba:

```
USERS=1 RAMP=5 NUM_RUNS=5 SERVER_NAME=3.236.136.31 ./run_test.sh ConfiguracionEscenario1.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**:

<br>
<p align="center">
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/ff7d519c-05e0-40bd-a73d-23c539bc993c" />
</p>
<br>

Para visualizar la métrica de uso de CPU de la instancia web se abre el dashboard configurado en Amazon CloudWatch:

<br>
<p align="center">
  <img alt="imagencloudwatch1" src="https://github.com/user-attachments/assets/bb7904b1-501b-4563-8e65-a3388c2333f2" />
</p>
<br>

### Resultados

Se definen diferentes pruebas con un número creciente de usuarios concurrentes para observar el comportamiento del servidor. Para ello, se definen las pruebas con los siguientes parametros:

```
USERS=10
RAMP=5
SERVER_NAME=3.236.136.31
```

Tenemos la siguiente tabla que contiene las métricas del **Flujo Completo** del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-------:|:---------------:|
| 10                    | 0.27 req/s          |  2217 ms                     | 12%     |     0%          |
| 25                    | 0.60 req/s          |  6116 ms                     | 20%     |     0%          |
| **40**                | **0.88 req/s**      |  **9988 ms**                 | **30%** |     **0%**      |
| 50                    | 1.02 req/s          | 12860 ms                     | 33%     |     0%          |
| 60                    | 1.14 req/s          | 15962 ms                     | 35%     |     0%          |
| 75                    | 1.25 req/s          | 20916 ms                     | 40%     |     0%          |
| 100                   | 1.45 req/s          | 27230 ms                     | 54%     |     0%          |
| 125                   | 1.67 req/s          | 35278 ms                     | 67%     |     0%          |
| 150                   | 1.82 req/s          | 41373 ms                     | 80%     |  2.93%          |
| 175                   | 2.06 req/s          | 43710 ms                     | 88%     | 15.89%	         |
| 200                   | 2.24 req/s          | 46477 ms                     | 92%     | 28.10%          |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

Vemos que el limite donde el tiempo de respuesta promedio empieza a superar el umbral de aceptación ocurre con **50 usuarios concurrentes**. Por otro lado, con **40 usuarios concurrentes** se mantiene sin sobrepasar el umbral de los criterios de aceptación.

Podemos asumir que para este escenario 1 el número de usuarios concurrentes que puede soportar el servidor web es de **40 usuarios concurrentes** antes de que se degrade. Podemos observar los siguientes resultados especificos por endpoint:

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------------:|
| Registro                  | 1.73 req/s          | 5324 ms                      | 30%       | 0%              |
| Iniciar Sesión            | 1.72 req/s          | 3982 ms                      | 30%       | 0%              |
| Consultar Videos Públicos | 1.78 req/s          | 184 ms                       | 30%       | 0%              |
| Realizar Voto             | 1.78 req/s          | 95 ms                        | 30%       | 0%              |
| Consultar Ranking         | 1.78 req/s          | 182 ms                       | 30%       | 0%              |

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

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------------:|
| Iniciar Sesión            | ≥ 0.4 req/s         | ≤ 4000 ms                    | ≤ 70%     | ≤ 1%            |
| Consultar Video Propios   | ≥ 0.4 req/s         | ≤ 2500 ms                    | ≤ 70%     | ≤ 1%            |
| Subir Video               | ≥ 0.3 req/s         | ≤ 20000 ms                   | ≤ 70%     | ≤ 1%            |
| Consultar Detalle Video   | ≥ 0.3 req/s         | ≤ 1000 ms                    | ≤ 70%     | ≤ 1%            |
| **Flujo Completo**        | **≥ 0.2 req/s**     | **≤ 26500 ms**               | **≤ 70%** | **≤ 1%**       | 

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
SERVER_NAME=54.82.32.232
AUTH_SERVICE_PORT=8080
VIDEO_SERVICE_PORT=8081
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

Para ejecutar la prueba de carga se ejecuta los siguientes comandos en una terminal bash para levantar el contenedor con JMeter:

```
cd capacity-planning/Entrega_2/jmeter
```
```
docker build -t jmeter-cli:5.6.3 .
```
```
docker compose up -d
```

Una vez levantado el contenedor con Jmeter se puede ejecutar el siguiente script para correr la prueba:

```
USERS=1 RAMP=5 NUM_RUNS=5 SERVER_NAME=54.82.32.232 ./run_test.sh ConfiguracionEscenario2.jmx
```

Una vez terminada la prueba se obtienen los resultados en el archivo **resultados.jtl** y para visualizarlo en el navegador se abre el **report/index.html**:

<br>
<p align="center">
  <img alt="Imagen3" src="https://github.com/user-attachments/assets/93f0f990-1b2a-496d-b01a-9d5fc93dd484" />
</p>
<br>

### Resultados

Se definen diferentes pruebas con un número creciente de usuarios concurrentes para observas el comportameinto del servidor. Para ello, se definen las pruebas con los siguientes parametros:

```
USER=10
RAMP=5
SERVER_NAME=54.227.119.251
```

Tenemos la siguiente tabla que contiene las métricas del Flujo Completo del escenario con diferentes usuarios concurrentes:

| Usuarios Concurrentes | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU | Tasa de Errores |
|:---------------------:|:-------------------:|:----------------------------:|:-------:|:---------------:|
| 10                    | 0.08 req/s          | 17286 ms                     | 8%      |     0%          |
| 20                    | 0.16 req/s          | 18777 ms                     | 14%     |     0%          |
| 30                    | 0.24 req/s          | 24203 ms                     | 20%     |     0%          |
| **40**                | **0.28 req/s**      | **25872 ms**                 | **25%** |    **0%**       |
| 50                    | 0.39 req/s          | 27438 ms                     | 32%     |     0%          |
| 60                    | 0.56 req/s          | 30189 ms                     | 38%     |     0%          |
| 70                    | 0.60 req/s          | 35642 ms                     | 45%     |     0%          |
| 80                    | 0.65 req/s          | 43823 ms                     | 50%     |     0%          |
| 90                    | 0.67 req/s          | 52910 ms                     | 57%     |     0%	         |
| 100                   | 0.69 req/s          | 61254 ms                     | 63%     |     0%          |

> **Nota:** Los valores presentados en la tabla son el resultado de promediar las métricas obtenidas de la herramienta de pruebas JMeter tras ejecutar el mismo escenario cinco (5) veces para cada nivel de usuarios concurrentes. Este proceso de promediado asegura la consistencia y mitiga la variabilidad inherente a las pruebas de rendimiento.

Vemos que el limite donde el tiempo de respuesta promedio empieza a superar el umbral de aceptación ocurre con **50 usuarios concurrentes**. Por otro lado, con **40 usuarios concurrentes** se mantiene sin sobrepasar el umbral de los criterios de aceptación.

Podemos asumir que para este escenario 1 el número de usuarios concurrentes que puede soportar el servidor web es de **40 usuarios concurrentes** antes de que se degrade. Podemos observar los siguientes resultados especificos por endpoint:

| Endpoint                  | Throughput Promedio | Tiempo de Respuesta Promedio | Máx CPU   | Tasa de Errores |
|:-------------------------:|:-------------------:|:----------------------------:|:---------:|:---------------:|
| Iniciar Sesión            | 0.41 req/s          |  3640 ms                     | 25%       | 0%              |
| Consultar Videos Propios  | 0.41 req/s          |   482 ms                     | 25%       | 0%              |
| Subir Video               | 0.35 req/s          | 17909 ms                     | 25%       | 0%              |
| Consultar Detalle Video   | 0.35 req/s          |   615 ms                     | 25%       | 0%              |

<br>

## **Prueba de Carga Capa Worker (Videos Procesados)**

Dado que en el Escenario 2 el componente crítico es el procesamiento de videos por parte del worker, se incorpora una nueva métrica de calidad que permite evaluar su capacidad real bajo distintos niveles de carga.

**Definición de la Métrica Videos Procesados por Minuto (VPM):** Es básicamente la cantidad de videos que el sistema es capaz de procesar por minuto bajo una carga determinada.

| Métrica | Criterio Propuesto | Descripción |
|:-------:|:------------------:|:-----------:|
| **Videos Procesados por Minuto (VPM)** | **≥ 0.07 VPM**     | El sistema debe ser capaz de procesar al menos un video cada 14 minutos bajo carga estable. Este valor corresponde al máximo nivel de usuarios concurrentes donde el tiempo de procesamiento aún no muestra degradación significativa. |

Para esta prueba, se definió un nuevo endpoint ```/api/videos/processing-stats?from\_id=\&to\_id=```, para calcular el **tiempo promedio de procesamiento de los videos**. Este endpoint determina la métrica basándose en el rango de IDs de video proporcionado como parámetros. El resultado devuelto incluye la siguiente información:

```
{
  "count": 40,
  "avg_processing_seconds": 859.335446,
  "min_processing_seconds": 193.484464,
  "max_processing_seconds": 1531.642574
}
```

Haciendo las pruebas con diferente número de usuarios concurrentes. Se obtuvieron los siguientes resultados:

| Videos Simultáneos | Tiempo Promedio | Tiempo Mínimo | Tiempo Máximo | Uso de CPU | VPM (Videos/min) |
|:----:|:------:|:------:|:-------:|:----:|:------:|
| 10   | 280 sg | 179 sg | 374 sg  | 85%  | 0.21 |
| 20   | 469 sg | 185 sg | 754 sg  | 100% | 0.13 |
| 30   | 663 sg | 190 sg | 1146 sg | 100% | 0.09 |
| **40** | **859 sg** | **193 sg** | **1531 sg** | **100%** | **0.07** |
| 50   | 1112 sg | 195 sg | 1984 sg | 100% | 0.05 |
| 60   | 1338 sg | 197 sg | 2417 sg | 100% | 0.04 |
| 70   | 1498 sg | 189 sg | 2805 sg | 100% | 0.04 |
| 80   | 1621 sg | 189 sg | 3059 sg | 100% | 0.04 |
| 90   | 1784 sg | 192 sg | 3386 sg | 100% | 0.03 |
| 100  | 1919 sg | 194 sg | 3652 sg | 100% | 0.03 |


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
  <img alt="Imagen102" src="https://github.com/user-attachments/assets/7c2dc8a5-ca24-4f3e-8fa4-b26514d55b71" />
</p>

<p align="center">
  <img alt="Imagen103" src="https://github.com/user-attachments/assets/5265e438-ecfc-4db9-a805-37837d92b495" />
</p>

**1. Capacidad Máxima y Estabilidad Operativa:** El análisis de los resultados del Escenario 1 indica que la capacidad máxima estable del sistema, cumpliendo con todos los critierios de aceptación del flujo completo, es de **40 usuarios concurrentes**. A este nivel de carga, el sistema mantiene un tiempo de respuesta promedio aceptable de 9988 ms y una utilización de recursos de servidor baja (30% de CPU), demostrando un buen desempeño y estabilidad sin degradación de la experiencia del usuario ni sobrecarga de la infraestructura.

**2. Punto de Degradación del Servicio:** Este punto se identifica con 50 usuarios concurrentes, momento en el cual el Tiempo de Respuesto Promedio del flujo completo supera el umbral de aceptación (se incrementa a 12860ms superando el límite de 11300ms). Este es el primer indicador de cuello de botella y marca la capacidad máxima que el sistema puede manejar antes de que la latencia impacte negativamente la experiencia del usuario, incluso antes de que los recursos de hardware se agoten.

**3. Identificación del Cuello de Botella:** El cuello de botella primario no está directamente asociado al agotamiento de recursos físicos (CPU), dado que estos se mantienen en niveles bajos a moderados (<= 40% hasta 75 usuarios) en el punto de degradación. En su lugar, la limitación parece ser interna de la aplicación, especificamente del servicio de autenticación, posiblemente debido a la contención de threads o procesos ineficientes en las peticiones de Registro e Inicio de Sesión. La optimización debe enforcarse en estos componentes de la capa de aplicación para mejorar la gestión de la concurrencia.

**4. Límites de Resistencia y Tasa de Errores:** El sistema exhibe un alto grado de resistencia en términos de errrores, manteniendo una Tasa de Errores del 0% hasta 125 usuarios concurrentes. La saturación y alta tasa de errores ocurre más tarde, a partir de 150 usuarios, donde el uso de CPU supera el umbral del 70% y la tasa de errores se dispara a 2.93% y luego a 28.10% con 200 usuarios. Esto sugiere que el servidor está bien configurado para no fallar en un punto de carga aceptable, pero la degradación del tiempo de respuesta es el problema más urgente a resolver.

### Escenario 2

Para el escenario 2 tenemos las siguientes gráficas que ilustran el comportamiento del servidor durante las pruebas de carga:

<p align="center">
  <img alt="Imagen100" src="https://github.com/user-attachments/assets/9e820560-e620-457f-90af-59a1c19ee623" />
</p>

<p align="center">
  <img alt="Imagen101" src="https://github.com/user-attachments/assets/a92d3c0e-2afb-4dff-a62d-ea0a6058d130" />
</p>

<p align="center">
  <img alt="Imagen102" src="https://github.com/user-attachments/assets/29b4ddc3-85c3-4357-aa8a-57ab2b4b0a47" />
</p>

<p align="center">
  <img alt="Imagen103" src="https://github.com/user-attachments/assets/595d03f9-cea9-4f08-bb25-52b857491554" />
</p>

**1. Capacidad Máxima y Estabilidad Operativa:** La capacidad máxima estable del Escenario 2, se establece con 40 usuarios concurrentes. En este nivel de carga, el sistema cumple con todos los criterios de aceptación definidos, registrando un tiempo de respuesta promedio de 25872 ms (dentro del límite de 26500 ms) y un througput de 0.28 req/s (superando el mínimo de 0.2 req/s). La utilización de recursos se mantien en niveles bajos (25% CPU), indicando una operación estable.

**2. Punto de Degradación del Servicio:** El punto de degradación del flujo completo se identifica claramente con 50 usuarios concurrentes, momento en el cual el Tiempo de Respuesta Promedio se eleva a 27438 ms, superando el umbral máximo aceptable de 26500 ms. Este es el primer criterio que se incumple y marca el límite de la experiencia de usuario, a pesar de que los recursos del servidor (32% CPU) y la tasa de errores (0%) aún se encuentran dentro de los parámetros aceptables.

**3 Identificación del Cuello de Botella:** El cuello de botella de este escenario es inequívocamente la petición de "Subir Video" (Request_3). Con 40 usuarios, esta operación consume 17909 ms (casi el 70% del tiempo total del flujo). Dado que la utilización de CPU (25%) es muy baja, el cuello de botella no es el procesamiento del servidor, sino el ancho de banda y la E/S de red, limitados por el tiempo requerido para transferir el archivo de 16MB en cada solicitud concurrente.

**4. Límites de Resistencia y Tasa de Errores:** El sistema demuestra una resistencia a errores, manteniendo una Tasa de Errores de 0% en todos los niveles probados (hasta 100 usuarios).

<br>

### Prueba de Carga Capa Worker (Videos Procesados)

<p align="center">
  <img alt="tiempopromediovideosprocesados" src="https://github.com/user-attachments/assets/fbbddc91-1ff4-4f4a-b871-329ac8419cf5" />
</p>

<p align="center">
  <img alt="vpmgrafica" src="https://github.com/user-attachments/assets/45b58484-564e-47dd-ad18-958a4363070c" />
</p>

El análisis del tiempo de procesamiento del pipeline de videos demuestra que el sistema mantiene un rendimiento estable hasta aproximadamente 40 videos procesados simultáneamente, con un tiempo promedio de 859 segundos por video. Esto equivale a un rendimiento de 0.07 videos procesados por minuto, que se establece como el umbral mínimo aceptable de calidad para el worker en condiciones normales de operación.

Sin embargo, también se puede apreciar que el sistema experimenta saturación de CPU muy rápidamente: desde 20 videos simultáneos, el uso de CPU llega al 100%, y permanece así hasta los 100 videos concurrentes. Esta saturación constante indica que la CPU sí es el cuello de botella principal del worker, y no el I/O ni la lógica interna del pipeline.

<br>

## Consideraciones para escalar la aplicación

Con el fin de mejorar la capacidad de respuesta y la disponibilidad del sistema frente a un aumento en el número de usuarios concurrentes, se identifican algunas estrategias de escalamiento que permitirían manejar una mayor carga de trabajo de forma más eficiente. Estas mejoras aplican tanto al escenario 1 como al escenario 2:

**1. Migrar el almacenamiento de archivos desde EC2 hacia Amazon S3**

Actualmente, el servidor web se encarga directamente de recibir y almacenar los archivos, lo que genera una carga adicional de red y procesamiento. Al trasladar el almacenamiento a un servicio especializado como S3, se logra que el servidor se enfoque únicamente en la lógica de negocio y no en el manejo de archivos pesados.

Esto permite:

* Aumentar la velocidad y confiabilidad en la carga y descarga de archivos.
* Mejorar la escalabilidad y durabilidad de los datos, ya que S3 está diseñado para manejar grandes volúmenes de información y crecer automáticamente según la demanda.

**2. Incorporar un balanceador de carga (ALB) y un grupo de autoescalado para el servidor web**

Actualmente, el sistema depende de una única instancia de servidor web. Esto limita su capacidad de respuesta frente a picos de tráfico y representa un punto único de falla. Al incluir un balanceador de carga que distribuya las solicitudes entre múltiples instancias, se asegura que la carga se reparta de forma equilibrada, evitando saturaciones en un solo punto.

Además, con un grupo de autoescalado se pueden añadir o eliminar instancias automáticamente según la demanda del sistema, lo que permite:

* Responder dinámicamente al aumento o disminución del tráfico.
* Mantener un rendimiento estable y tiempos de respuesta aceptables.
* Optimizar costos, ya que solo se utilizan los recursos necesarios en cada momento.

**3. Implementar un Auto Scaling Group (ASG) para la capa de procesamiento (Workers)**

En el escenario actual, todo el procesamiento de videos recae sobre una única instancia EC2 que ejecuta el worker encargado de manejar la cola de tareas. Esto genera varias limitaciones:

* La capacidad de procesamiento queda restringida por los recursos de un único servidor.
* El tiempo promedio de procesamiento se degrada al alcanzar saturación de CPU.
* Existe un punto único de falla: si la instancia del worker se detiene, todo el flujo de procesamiento de videos queda inoperativo.

Para solucionar esto, se recomienda crear un Auto Scaling Group dedicado a la capa de workers, con la capacidad de lanzar múltiples instancias idénticas que extraen tareas desde la misma cola de trabajo (por ejemplo, Amazon SQS).

Esto permite:

* Escalamiento horizontal: incrementar dinámicamente la cantidad de workers durante los picos de carga, procesando más videos en paralelo.
* Balanceo natural por cola: al utilizar SQS (o una cola equivalente), las tareas se distribuyen automáticamente entre los workers disponibles, sin necesidad de un balanceador adicional.
* Alta disponibilidad: si una instancia falla, el ASG la reemplaza automáticamente por otra nueva.
* Reducción de tiempos de procesamiento: con múltiples workers procesando videos simultáneamente, el tiempo total para vaciar la cola disminuye significativamente.
* Optimización de costos: se pueden definir políticas de escalamiento basadas en métricas como número de mensajes en la cola, CPU o duración promedio de tareas, asegurando que solo haya workers activos cuando realmente se necesitan.

En conjunto, esta estrategia elimina el cuello de botella que supone una única instancia de procesamiento y permite que el sistema soporte mayor demanda de forma eficiente y resiliente.
