# Build
FROM golang:1.22.8 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o ranking-service .

# Runtime
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/ranking-service .
ENV SERVER_PORT=8083
EXPOSE 8083
CMD ["/app/ranking-service"]