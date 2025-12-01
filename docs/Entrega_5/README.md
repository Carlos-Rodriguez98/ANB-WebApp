# **Pruebas de Carga - Entrega 5**

## **Herramientas**

Para las pruebas de carga se utilizará **Apache JMeter**, una herramienta de código abierto diseñada para realizar pruebas de rendimiento y medir el comportamiento de aplicaciones web y otros servicios. JMeter permite simular múltiples usuarios concurrentes que acceden a una aplicación, con el fin de evaluar su capacidad de respuesta y estabilidad bajo diferentes niveles de carga.

Además, se utilizará **Amazon CloudWatch** para el monitoreo de recursos en la infraestructura de AWS. CloudWatch recopila métricas como el uso de CPU, disco y red en tiempo real, lo que permite analizar el rendimiento del sistema durante las pruebas de carga y detectar posibles cuellos de botella o degradaciones en el servicio.

<br>

## **Arquitectura del Entorno de Pruebas**

La arquitectura del entorno de pruebas se basa en un enfoque totalmente contenedorizado para garantizar portabilidad y consistencia en la ejecución.

Se definió un Dockerfile y un docker-compose.yml que permiten levantar un contenedor local con una versión ligera de Apache JMeter en modo CLI (sin interfaz gráfica), junto con Java 17, necesario para su ejecución. Este contenedor se utiliza exclusivamente para ejecutar los scripts de pruebas de carga de forma automatizada. Por otro lado, CloudWatch ya es un servicio integrado de AWS por lo que sus métricas se consiguen directamente desde la consola de amazon desde un dashboard definido en terraform.

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

En esta entrega no se considera necesario volver a ejecutar las pruebas de carga correspondientes al Escenario 1, ya que la capa web no recibió ningún cambio respecto a la arquitectura implementada en la entrega número 3. El Auto Scaling Group (ASG) que atiende las solicitudes HTTP, junto con el Application Load Balancer y la configuración general de la infraestructura, se mantiene exactamente igual, sin modificaciones en número de instancias, tipo, políticas de escalado, seguridad, ni lógica de enrutamiento. Dado que no hubo ajustes en el código, la estructura de red, ni en los componentes que intervienen en este flujo, el comportamiento del sistema frente a carga sería idéntico al observado previamente. Por lo tanto, los resultados de las pruebas realizadas del escenario 1 en la Entrega 3 se consideran completamente válidos para esta entrega, ya que repetirlas produciría métricas y conclusiones equivalentes.

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

En el caso del Escenario 2, tampoco resulta necesario repetir la prueba de carga orientada a medir la capacidad del servidor web para manejar el flujo de subida de videos, ya que esta etapa depende principalmente del encolamiento de tareas en SQS y del manejo de solicitudes HTTP por parte del ASG web. Dado que esta porción de la arquitectura no sufrió ningún cambio respecto a la entrega anterior (manteniendo el mismo ASG web, la misma lógica de encolamiento y las mismas rutas de subida hacia S3) los resultados obtenidos en la Entrega 3 seguirían siendo equivalentes.

Sin embargo, lo que sí se vuelve relevante evaluar en esta entrega es la **capacidad del nuevo sistema basado en funciones AWS Lambda**, que reemplaza al ASG de workers utilizado previamente. Este cambio en la arquitectura introduce un modelo de escalado automático aún más flexible, permitiendo procesar videos de manera altamente paralela sin necesidad de administrar servidores. Por lo tanto, las pruebas de rendimiento deben centrarse ahora en validar cómo escala el procesamiento asíncrono bajo diferentes volúmenes de carga y cuán efectivamente el uso de Lambda reduce los tiempos de procesamiento totales en comparación con la entrega anterior.

<br>

## **Prueba de Carga del ASG Worker**

El objetivo principal de esta prueba es evaluar el desempeño de la nueva arquitectura de procesamiento asíncrono basada en AWS Lambda, que reemplaza al Auto Scaling Group (ASG) de workers utilizado en la entrega anterior. A diferencia del modelo previo, donde existía un conjunto limitado de instancias capaces de escalar únicamente hasta cierto punto, la nueva solución aprovecha la capacidad de escalado prácticamente ilimitado de Lambda, permitiendo procesar múltiples videos en paralelo sin necesidad de administrar servidores.

La prueba se diseña en términos de usuarios concurrentes que suben videos simultáneamente. Cada subida genera un mensaje en SQS y desencadena una ejecución independiente de Lambda. Para cada nivel de concurrencia se mide:

* El tiempo promedio de procesamiento por video, desde que el mensaje llega a la cola hasta que el video queda completamente procesado.

* El número de ejecuciones concurrentes de Lambda registradas en CloudWatch, observando si la función escala adecuadamente frente a aumentos de carga.

* La duración promedio de cada invocación, para identificar posibles cuellos de botella en la lógica interna.

El experimento busca validar si Lambda es capaz de absorber incrementos en la cantidad de videos a procesar sin provocar acumulación significativa en la cola y sin degradar el tiempo total de procesamiento. Dado su modelo serverless, se espera que la arquitectura escale automáticamente en función de la demanda, mejorando el throughput y eliminando las limitaciones impuestas por un grupo fijo de instancias. Esta prueba permitirá cuantificar el impacto del escalado automático de Lambda y confirmar que la nueva versión del sistema ofrece un procesamiento más eficiente y robusto bajo condiciones de estrés controlado.

### Tabla de Resultados

Se ha implementado un nuevo endpoint, ```/api/videos/processing-stats?from\_id=\&to\_id=```, para calcular el **tiempo promedio de procesamiento de los videos**. Este endpoint determina la métrica basándose en el rango de IDs de video proporcionado como parámetros. El resultado devuelto incluye la siguiente información:

```
{
  "count": 70,
  "avg_processing_seconds": 248.335446,
  "min_processing_seconds": 226.484464,
  "max_processing_seconds": 287.642574
}
```

Por otro lado, tal como se mencionó anteriormente, para obtener métricas como la concurrencia utilizada de la función Lambda y la cantidad de invocaciones activas durante las pruebas, se emplea un dashboard en Amazon CloudWatch.

<p align="center">
  <img alt="cloudwatch50" src="https://github.com/user-attachments/assets/1ecee621-77e0-4bfb-b157-7851eb32a519" />
</p>

Se realizaron pruebas de carga usando [ConfiguracionEscenario2.jmx](ConfiguracionEscenario2.jmx) con distintos número de usuarios concurrentes subiendo videos a la vez, obteniendo los siguientes resultados:

| Videos Simultáneos | Tiempo Promedio de Procesamiento | Tiempo Mínimo de Procesamiento | Tiempo Máximo de Procesamiento | Concurrencia Máxima de Lambda | Errores | Videos procesados por minuto |
|:------:|:----------:|:----------:|:-----------:|:--------:|:-----:|:-----:|
| 10     | 244 sg     | 229 sg     | 286 sg      | 10       | 0     | 2.46  |
| 20     | 241 sg     | 228 sg     | 285 sg      | 20       | 0     | 4.98  |
| 30     | 243 sg     | 227 sg     | 286 sg      | 30       | 0     | 7.41  |
| 40     | 247 sg     | 226 sg     | 287 sg      | 40       | 0     | 9.72  |
| 50     | 245 sg     | 229 sg     | 287 sg      | 50       | 0     | 12.24 |
| 60     | 239 sg     | 231 sg     | 289 sg      | 60       | 0     | 15.06 |
| 70     | 248 sg     | 226 sg     | 287 sg      | 70       | 0     | 16.94 |
| 80     | 246 sg     | 228 sg     | 289 sg      | 75       | 0     | 19.51 |
| 90     | 247 sg     | 225 sg     | 291 sg      | 85       | 0     | 21.86 |
| 100    | 249 sg     | 223 sg     | 292 sg      | 287 sg   | 0     | 24.10 |

También se probó la arquitectura de la entrega 4 para comprobar cuánto tiempo tarda en procesar los videos y poder así hacer una comparativa entre ambas entregas. Se obtuvieron los siguientes resultados:

| Videos Simultáneos | Tiempo Promedio de Procesamiento | Tiempo Mínimo de Procesamiento | Tiempo Máximo de Procesamiento | CPU Máxima del ASG | Máximo de Instancias Activas | Videos procesados por minuto |
|:------:|:----------:|:----------:|:-----------:|:--------:|:-----:|:-------:|
| 10     | 151 sg     | 93 sg      | 219 sg      | 53%      | 2     | 3.97 |
| 20     | 248 sg     | 118 sg     | 463 sg      | 71%      | 2     | 4.84 |
| 30     | 337 sg     | 129 sg     | 672 sg      | 83%      | 3     | 5.34 | 
| 40     | 428 sg     | 141 sg     | 981 sg      | 88%      | 3     | 5.61 |
| 50     | 561 sg     | 167 sg     | 1395 sg     | 95%      | 3     | 5.35 |
| 60     | 612 sg     | 173 sg     | 1582 sg     | 100%     | 3     | 5.88 |
| 70     | 689 sg     | 181 sg     | 1764 sg     | 100%     | 3     | 6.09 |
| 80     | 742 sg     | 189 sg     | 1931 sg     | 100%     | 3     | 6.47 |
| 90     | 791 sg     | 196 sg     | 2084 sg     | 100%     | 3     | 6.83 |
| 100    | 819 sg     | 141 sg     | 2259 sg     | 100%     | 3     | 7.33 |

<br>

## Conclusiones

<p align="center">
  <img alt="cloudwatch50" src="https://github.com/user-attachments/assets/1a82eca9-fe9a-4605-97be-ae876c2130f3" />
</p>

Los resultados muestran una diferencia clara entre ambas arquitecturas: AWS Lambda procesa videos a una velocidad muy superior al ASG, especialmente a partir de cargas medias y altas. Mientras que el ASG incrementa su capacidad solo hasta 3 instancias, Lambda escala prácticamente sin fricción, ajustando su concurrencia en función del número de videos en la cola.

En términos de rendimiento, Lambda mantiene un crecimiento lineal en la métrica videos procesados por minuto (VPM), pasando de 2.46 VPM a 24.10 VPM a medida que aumenta la carga. Por el contrario, el ASG presenta un crecimiento marginal, moviéndose solo de 3.97 VPM a 7.33 VPM, y estabilizándose rápidamente debido a los límites de sus instancias y al 100% de CPU sostenido en cargas altas.

Esto demuestra que el cuello de botella en la arquitectura del ASG sigue siendo el cómputo disponible en sus instancias, que alcanzan el 100% de utilización de CPU a partir de 60 videos simultáneos. Aunque el ASG mejora respecto a un worker único, su capacidad de escalar horizontalmente es limitada comparada con Lambda.

En contraste, la arquitectura basada en Lambda escala de manera mucho más eficiente, distribuyendo la carga entre múltiples ejecuciones en paralelo y evitando saturación incluso en los escenarios más altos de concurrencia probados. Esto explica por qué Lambda obtiene un throughput varias veces mayor que el ASG, manteniéndose consistente pese al incremento de carga.

En conjunto, los resultados validan que Lambda es más adecuada para cargas variables, altas y distribuidas, mientras que el ASG comienza a presentar limitaciones claras cuando el procesamiento crece más allá de lo que sus tres instancias pueden sostener.

<br>