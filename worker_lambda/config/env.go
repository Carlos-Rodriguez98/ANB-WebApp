package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// Config stores all configuration of the application.
// The values are read by godotenv from a .env file.
type Config struct {
	DB struct {
		Host     string
		Port     string
		User     string
		Password string
		Name     string
		SSLMode  string
	}
	S3 struct {
		BucketName string
	}
	AWS struct {
		Region string
	}
	SQS struct {
		QueueURL string
	}
}

// LoadConfig loads application configuration from environment variables.
func LoadConfig() (*Config, error) {
	if os.Getenv("AWS_LAMBDA_FUNCTION_NAME") == "" {
		// Only load .env file if not running in Lambda
		if err := godotenv.Load(); err != nil {
			fmt.Println("No .env file found, relying on environment variables")
		}
	}

	cfg := &Config{}
	cfg.DB.Host = os.Getenv("DB_HOST")
	cfg.DB.Port = os.Getenv("DB_PORT")
	cfg.DB.User = os.Getenv("DB_USER")
	cfg.DB.Password = os.Getenv("DB_PASSWORD")
	cfg.DB.Name = os.Getenv("DB_NAME")
	cfg.DB.SSLMode = os.Getenv("DB_SSLMODE")
	cfg.S3.BucketName = os.Getenv("S3_BUCKET_NAME")
	cfg.AWS.Region = os.Getenv("AWS_REGION")
	cfg.SQS.QueueURL = os.Getenv("SQS_QUEUE_URL")

	return cfg, nil
}
