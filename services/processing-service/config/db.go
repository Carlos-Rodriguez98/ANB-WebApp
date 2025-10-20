package config

import (
	"fmt"
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func ConnectDatabase() (*gorm.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%d sslmode=%s TimeZone=America/Bogota search_path=app",
		App.DBHost, App.DBUser, App.DBPass, App.DBName, App.DBPort, App.DBSSLMode,
	)
	var db *gorm.DB
	var err error

	for i := 1; i <= 5; i++ {
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err == nil {
			log.Print("[processing-service] DB conectado")
			return db, nil
		}
		log.Printf("DB intento %d: %v", i, err)
		time.Sleep(3 * time.Second)
	}
	return nil, fmt.Errorf("no se pudo conectar a la base: %w", err)
}
