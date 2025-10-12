package config

import (
	"fmt"
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() (*gorm.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%d sslmode=%s TimeZone=America/Bogota search_path=app",
		AppConfig.DBHost, AppConfig.DBUser, AppConfig.DBPassword, AppConfig.DBName, AppConfig.DBPort, AppConfig.DBSSLMode,
	)

	var err error
	for i := 1; i <= 5; i++ {
		DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err == nil {
			log.Print("[video-service] DB conectado")
			/*
				if err := DB.AutoMigrate(&models.Video{}); err != nil {
					return nil, err
				}
			*/
			return DB, nil
		}
		log.Printf("DB intento %d: %v", i, err)
		time.Sleep(3 * time.Second)
	}
	return nil, fmt.Errorf("no se pudo conectar a la base de datos: %v", err)
}
