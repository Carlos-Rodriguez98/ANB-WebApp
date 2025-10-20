# Build
FROM golang:1.23 AS builder
WORKDIR /app

# 1) Solo los mod files para cachear dependencias
COPY go.mod go.sum ./
RUN go mod download

# 2) Ahora sí, copia el resto del código
COPY . .

# 3) Tidy dentro del contenedor para alinear go.mod/go.sum con los imports
RUN go mod tidy

# 4) Compila
RUN CGO_ENABLED=0 go build -o video-service .

# Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/video-service .
ENV SERVER_PORT=8081
EXPOSE 8081
CMD ["/app/video-service"]