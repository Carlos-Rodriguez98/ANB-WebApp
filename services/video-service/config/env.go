package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type EnvConfig struct {
	DBHost     string
	DBPort     int
	DBUser     string
	DBPassword string
	DBName     string
	DBSSLMode  string

	RedisAddr  string
	ServerPort int

	StorageBasePath string // ej: ./uploads
	JWTSecret       string
}

var AppConfig EnvConfig

func LoadEnv() {
	_ = godotenv.Load()

	dbPort, _ := strconv.Atoi(getOrDefault("DB_PORT", "5432"))
	serverPort, _ := strconv.Atoi(getOrDefault("SERVER_PORT", "8081"))

	AppConfig = EnvConfig{
		DBHost:          getOrDefault("DB_HOST", "localhost"),
		DBPort:          dbPort,
		DBUser:          getOrDefault("DB_USER", "postgres"),
		DBPassword:      getOrDefault("DB_PASSWORD", "postgres"),
		DBName:          getOrDefault("DB_NAME", "anb"),
		DBSSLMode:       getOrDefault("DB_SSLMODE", "require"),
		RedisAddr:       getOrDefault("REDIS_ADDR", "localhost:6379"),
		ServerPort:      serverPort,
		StorageBasePath: getOrDefault("STORAGE_BASE_PATH", "./uploads"),
		JWTSecret:       getOrDefault("JWT_SECRET", "devsecret"),
	}
	log.Printf("[video-service] config OK, port=%d redis=%s basepath=%s",
		AppConfig.ServerPort, AppConfig.RedisAddr, AppConfig.StorageBasePath)
}

func getOrDefault(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
