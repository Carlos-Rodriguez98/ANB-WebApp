# Build
FROM golang:1.22.8 AS builder
WORKDIR /app

# 1) Solo los mod files para cachear dependencias
COPY go.mod go.sum ./
RUN go mod download

# 2) Ahora sí, copia el resto del código
COPY . .

# 3) Tidy dentro del contenedor para alinear go.mod/go.sum con los imports
RUN go mod tidy

# 4) Compila
RUN CGO_ENABLED=0 go build -o voting-service .

# Runtime
FROM gcr.io/distroless/base-debian12
WORKDIR /app
COPY --from=builder /app/voting-service .
ENV SERVER_PORT=8080
EXPOSE 8080
CMD ["/app/voting-service"]