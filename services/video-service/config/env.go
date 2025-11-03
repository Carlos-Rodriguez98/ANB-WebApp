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
	S3BucketName    string
	AWSRegion       string
	StorageMode     string
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
		S3BucketName:    getOrDefault("S3_BUCKET_NAME", "anb-bucket"),
		AWSRegion:       getOrDefault("AWS_REGION", "us-east-1"),
		StorageMode:     getOrDefault("STORAGE_MODE", "s3"),
	}
	log.Printf("[video-service] config OK | port=%d redis=%s mode=%s bucket=%s region=%s",
		AppConfig.ServerPort, AppConfig.RedisAddr, AppConfig.StorageMode,
		AppConfig.S3BucketName, AppConfig.AWSRegion)
}

func getOrDefault(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
