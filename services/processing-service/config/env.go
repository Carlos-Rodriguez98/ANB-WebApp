package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type EnvConfig struct {
	// DB
	DBHost string
	DBPort int
	DBUser string
	DBPass string
	DBName string

	// Infra
	RedisAddr       string // ej: redis:6379
	StorageBasePath string // ej: /data/uploads

	// Worker
	WorkerConcurrency int // ej: 5
}

var App EnvConfig

func LoadEnv() {
	_ = godotenv.Load()

	dbPort := atoiDefault(os.Getenv("DB_PORT"), 5432)
	concurrency := atoiDefault(os.Getenv("WORKER_CONCURRENCY"), 5)

	App = EnvConfig{
		DBHost: os.Getenv("DB_HOST"),
		DBPort: dbPort,
		DBUser: os.Getenv("DB_USER"),
		DBPass: os.Getenv("DB_PASSWORD"),
		DBName: os.Getenv("DB_NAME"),

		RedisAddr:       getenv("REDIS_ADDR", "redis:6379"),
		StorageBasePath: getenv("STORAGE_BASE_PATH", "/data/uploads"),

		WorkerConcurrency: concurrency,
	}

	log.Printf("[processing-service] env OK | redis=%s base=%s conc=%d",
		App.RedisAddr, App.StorageBasePath, App.WorkerConcurrency)
}

func atoiDefault(s string, def int) int {
	if v, err := strconv.Atoi(s); err == nil {
		return v
	}
	return def
}
func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
