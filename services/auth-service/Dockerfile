# Etapa de compilación (imagen oficial de GO)
FROM golang:1.24.6 AS builder

# Define directorio de trabajo dentro del contenedor
WORKDIR /app
# Copiar go.mod y go.sum (Archivos de dependencias)
COPY go.mod go.sum ./
# Descargar dependencias
RUN go mod download

# Copiar todo el código fuente al contenedor
COPY . . 

# Compila el proyecto y generar un ejecutable llamado main
RUN go build -o main .

# Etapa final (Genera imagen ligera para producción)
FROM debian:bookworm-slim

#Crear usuario seguro
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Define app como directorio de trabajo
WORKDIR /app

# Copia el binario main que se generó anteriormente al contenedor final
COPY --from=builder /app/main .
# Copia el archivo .env
#COPY .env .

#Indica que el contenedor escuchará en el puerto definido en el .env
EXPOSE 8080

#Cambiar al usuario no-root
USER appuser

#Indica que al iniciar el contenedor se ejecute el binario main.
CMD ["./main"]