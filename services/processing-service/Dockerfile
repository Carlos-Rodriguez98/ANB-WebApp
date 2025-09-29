# Build
FROM golang:1.23 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o processing-service .

# Runtime con ffmpeg
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/processing-service .
COPY logo_anb.png /app/logo_anb.png

# Variables por defecto (puedes sobreescribirlas en compose)
ENV REDIS_ADDR=redis:6379
ENV STORAGE_BASE_PATH=/data/uploads
CMD ["/app/processing-service"]
