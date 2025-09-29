# Build
FROM golang:1.22.8 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o voting-service .

# Runtime
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/voting-service .
ENV SERVER_PORT=8082
EXPOSE 8082
CMD ["/app/voting-service"]