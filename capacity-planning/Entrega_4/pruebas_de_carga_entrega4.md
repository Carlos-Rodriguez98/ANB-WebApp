# **Pruebas de Carga - Entrega 4**

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

En esta entrega no se considera necesario volver a ejecutar las pruebas de carga correspondientes al Escenario 1, ya que la capa web no recibió ningún cambio respecto a la arquitectura implementada en la entrega anterior. El Auto Scaling Group (ASG) que atiende las solicitudes HTTP, junto con el Application Load Balancer y la configuración general de la infraestructura, se mantiene exactamente igual, sin modificaciones en número de instancias, tipo, políticas de escalado, seguridad, ni lógica de enrutamiento. Dado que no hubo ajustes en el código, la estructura de red, ni en los componentes que intervienen en este flujo, el comportamiento del sistema frente a carga sería idéntico al observado previamente. Por lo tanto, los resultados de las pruebas realizadas del escenario 1 en la Entrega 3 se consideran completamente válidos para esta entrega, ya que repetirlas produciría métricas y conclusiones equivalentes.

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

Sin embargo, lo que sí se vuelve relevante evaluar en esta entrega es la **capacidad del nuevo ASG de workers**, que sustituye al único worker previo. Esta mejora en la arquitectura introduce la posibilidad de procesar videos de forma paralela y más eficiente, por lo que las pruebas de rendimiento deben centrarse ahora en validar cómo escala el procesamiento asíncrono bajo diferentes cargas y cuán efectivamente el ASG worker reduce los tiempos de procesamiento totales en comparación con la entrega anterior.

<br>

## **Prueba de Carga del ASG Worker**

El objetivo principal de esta prueba es evaluar el desempeño del nuevo Auto Scaling Group (ASG) de workers, encargado del procesamiento asíncrono de videos. A diferencia de la entrega anterior, donde existía un único worker estático, esta versión introduce un ASG con capacidad de escalar entre 1 y 3 instancias, lo que habilita el procesamiento paralelo de múltiples tareas provenientes de la cola SQS.

La prueba se diseña en términos de usuarios concurrentes que suben videos de manera simultánea. Cada subida genera un mensaje en SQS y, por lo tanto, una tarea a procesar por el worker. Para cada nivel de concurrencia se mide:

* Promedio de tiempo de procesamiento por video, desde que aparece el mensaje en la cola hasta que el video está completamente procesado.

* Uso máximo de CPU del ASG Worker, según métricas de CloudWatch.

* Cantidad de instancias activas en el ASG, observando cuándo el escalado automático se activa y cuántos workers se mantienen en funcionamiento.

El experimento busca determinar si el escalado dinámico del ASG permite absorber incrementos en la cantidad de videos a procesar sin degradar significativamente los tiempos totales. La expectativa es que, ante cargas moderadas o altas, el ASG incremente automáticamente el número de instancias, reduciendo la acumulación en la cola y mejorando la eficiencia del sistema frente al modelo anterior. Esta prueba permitirá cuantificar el impacto real del escalado automático y validar que la nueva arquitectura mejora el throughput de procesamiento bajo condiciones de estrés controlado.

### Tabla de Resultados

Se ha implementado un nuevo endpoint, ```/api/videos/processing-stats?from\_id=\&to\_id=```, para calcular el **tiempo promedio de procesamiento de los videos**. Este endpoint determina la métrica basándose en el rango de IDs de video proporcionado como parámetros. El resultado devuelto incluye la siguiente información:

```
{
  "count": 70,
  "avg_processing_seconds": 689.335446,
  "min_processing_seconds": 181.484464,
  "max_processing_seconds": 1764.642574
}
```

Por otro lado, como se menciono anteriormente para obtener el uso de CPU del ASG worker y el número de instances activas de workers se usa un dashboard en Amazon CloudWatch:

<p align="center">
  <img alt="cloudwatch50" src="https://github.com/user-attachments/assets/1ecee621-77e0-4bfb-b157-7851eb32a519" />
</p>

Se realizaron pruebas de carga usando [ConfiguracionEscenario2.jmx](ConfiguracionEscenario2.jmx) con distintos número de usuarios concurrentes subiendo videos a la vez, obteniendo los siguientes resultados:

| Videos Simultáneos | Tiempo Promedio de Procesamiento | Tiempo Mínimo de Procesamiento | Tiempo Máximo de Procesamiento | CPU Máxima del ASG | Máximo de Instancias Activas |
|:----:|:------:|:------:|:-------:|:----:|:----:|
| 10   | 151 sg |  93 sg |  219 sg |  53% | 2    |
| 20   | 248 sg | 118 sg |  463 sg |  71% | 2    |
| 30   | 337 sg | 129 sg |  672 sg |  83% | 3    |
| 40   | 428 sg | 141 sg |  981 sg |  88% | 3    |
| 50   | 561 sg | 167 sg | 1395 sg |  95% | 3    |
| 60   | 612 sg | 173 sg | 1582 sg | 100% | 3    |
| **70** | **689 sg** | **181 sg** | **1764 sg** | **100%** | **3**    |
| 80   | 742 sg | 189 sg | 1931 sg | 100% | 3    |
| 90   | 791 sg | 196 sg | 2084 sg | 100% | 3    |
| 100  | 819 sg | 141 sg | 2259 sg | 100% | 3    |

También se probó la arquitectura de la entrega 3 para comprobar cuánto tiempo tarda en procesar los videos y poder así hacer una comparativa entre ambas entregas. Se obtuvieron los siguientes resultados:

| Videos Simultáneos | Tiempo Promedio de Procesamiento | Tiempo Mínimo de Procesamiento | Tiempo Máximo de Procesamiento | Uso de CPU |
|:----:|:------:|:------:|:-------:|:----:|
| 10   | 280 sg | 179 sg |  374 sg |  85% |
| 20   | 469 sg | 185 sg |  754 sg | 100% |
| 30   | 663 sg | 190 sg | 1146 sg | 100% |
| 40   | 859 sg | 193 sg | 1531 sg | 100% |
| 50   | 1112 sg | 195 sg | 1984 sg | 100% |
| 60   | 1338 sg | 197 sg | 2417 sg | 100% |
| **70** | **1498 sg** | **189 sg** | **2805 sg** | 100% |
| 80   | 1621 sg | 189 sg | 3059 sg | 100% |
| 90   | 1784 sg | 192 sg | 3386 sg | 100% |
| 100  | 1919 sg | 194 sg | 3652 sg | 100% |

<br>

## Conclusiones

<p align="center">
  <img alt="cloudwatch50" src="https://github.com/user-attachments/assets/1a82eca9-fe9a-4605-97be-ae876c2130f3" />
</p>

Las pruebas realizadas demuestran que la nueva arquitectura con ASG de workers mejora significativamente el rendimiento del sistema frente a la arquitectura anterior basada en un único worker. Los tiempos de procesamiento disminuyen entre 45% y 57% según el nivel de carga, lo que confirma que el escalado automático permite atender múltiples videos en paralelo y reduce la acumulación de tareas en la cola SQS.

El ASG llega rápidamente a sus 3 instancias máximas, y aunque esto mejora el throughput, también evidencia que bajo cargas altas la CPU opera al 100%, indicando que el sistema continúa siendo intensivo en cómputo. Aun así, los tiempos máximos y promedios son considerablemente mejores que en la entrega anterior.

En resumen, la nueva arquitectura sí escala, sí reduce los tiempos de procesamiento y maneja mejor la concurrencia, pero se observa que el límite de 3 instancias se alcanza con frecuencia, por lo que podrían evaluarse ajustes futuros como aumentar el máximo del ASG, optimizar el proceso de transcodificación o considerar tipos de instancia más potentes.

<br>

## Recomendaciones

Para mejorar aún más la capacidad de procesamiento y evitar saturación en cargas elevadas, se puede recomendar:

* Aumentar el máximo de instancias del ASG Worker (por ejemplo, de 3 a 4 o 5) para permitir un mayor grado de paralelismo en momentos de alta concurrencia.

* Optimizar el pipeline de procesamiento de los videos, revisando parámetros de transcodificación, paralelismo interno o uso de librerías más eficientes para reducir el tiempo por tarea.

* Evaluar tipos de instancia más potentes o especializadas, especialmente porque el procesamiento es CPU-bound; instancias compute-optimized podrían reducir significativamente la saturación observada.
