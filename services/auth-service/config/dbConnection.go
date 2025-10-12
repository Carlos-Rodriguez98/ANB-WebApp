package config

import (
	"fmt"
	"log"
	"time"

	"ANB-WebApp/services/auth-service/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

// Función para establecer conexión a BD
func ConnectDatabase() (*gorm.DB, error) {
	//Construcción de URL de BD
	DSN := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%d sslmode=%s TimeZone=America/Bogota search_path=app",
		AppConfig.DBHost, AppConfig.DBUser, AppConfig.DBPassword, AppConfig.DBName, AppConfig.DBPort, AppConfig.DBSSLMode,
	)

	var err error //Declaro variable para captura de errores
	//Intento de conexión a la base de datos (hasta 5 intentos cada 2 seg)
	for i := 1; i <= 5; i++ {
		DB, err = gorm.Open(postgres.Open(DSN), &gorm.Config{})
		if err == nil {
			log.Print("Conexión exitosa a la base de datos")

			// Crear esquema 'app' si no existe
			if err := DB.Exec("CREATE SCHEMA IF NOT EXISTS app").Error; err != nil {
				log.Printf("Error creando esquema: %v", err)
				return nil, err
			}
			log.Println("Esquema 'app' verificado/creado")

			//Ejecución de automigración
			if err := DB.AutoMigrate(&models.User{}); err != nil {
				log.Fatal("Error en la migración: ", err)
				return nil, err
			}
			log.Println("Migración completada")
			
			return DB, nil
		}
		log.Printf("Intento %d: error conectando a la base de datos: %v", i, err)
		time.Sleep(3 * time.Second)
	}

	return nil, fmt.Errorf("no se pudo conectar a la base de datos de varios intentos: %v", err)
}
