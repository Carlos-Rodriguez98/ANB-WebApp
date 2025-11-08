package config

import (
	"fmt"
	"log"
	"time"

	"ANB-WebApp/services/video-service/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() (*gorm.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%d sslmode=require TimeZone=America/Bogota search_path=app",
		AppConfig.DBHost, AppConfig.DBUser, AppConfig.DBPassword, AppConfig.DBName, AppConfig.DBPort,
	)

	var err error
	for i := 1; i <= 5; i++ {
		DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err == nil {
			log.Print("[video-service] DB conectado")

			// Crear esquema 'app' si no existe
			if err := DB.Exec("CREATE SCHEMA IF NOT EXISTS app").Error; err != nil {
				log.Printf("Error creando esquema: %v", err)
				return nil, err
			}
			log.Println("[video-service] Esquema 'app' verificado/creado")

			if err := DB.AutoMigrate(&models.Video{}); err != nil {
				log.Printf("Error en migración: %v", err)
				return nil, err
			}
			log.Println("[video-service] Migración completada")

			return DB, nil
		}
		log.Printf("DB intento %d: %v", i, err)
		time.Sleep(3 * time.Second)
	}
	return nil, fmt.Errorf("no se pudo conectar a la base de datos: %v", err)
}
