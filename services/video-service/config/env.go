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
	S3BucketName   string
	S3Prefix       string
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
		DBSSLMode:       getOrDefault("DB_SSLMODE", "disable"),
		RedisAddr:       getOrDefault("REDIS_ADDR", "localhost:6379"),
		ServerPort:      serverPort,
		StorageBasePath: getOrDefault("STORAGE_BASE_PATH", "./uploads"),
		S3BucketName:    getOrDefault("S3_BUCKET_NAME", "anbapp-uploads-bucket"),
		S3Prefix:        getOrDefault("S3_PREFIX", "videos"),
		JWTSecret:       getOrDefault("JWT_SECRET", "devsecret"),
	}
	log.Printf("[video-service] config OK, port=%d redis=%s basepath=%s s3bucket=%s s3prefix=%s",
		AppConfig.ServerPort, AppConfig.RedisAddr, AppConfig.StorageBasePath, AppConfig.S3BucketName, AppConfig.S3Prefix)
}

func getOrDefault(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
