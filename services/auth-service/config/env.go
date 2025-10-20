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

	ServerPort int
}

var AppConfig EnvConfig

func LoadEnv() {
	log.Printf("DEBUG ENV -> DB_HOST=%s DB_USER=%s DB_NAME=%s",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_NAME"))

	// Solo intenta cargar .env si DB_HOST no existe en el sistema
	if os.Getenv("DB_HOST") == "" {
		if err := godotenv.Load(); err == nil {
			log.Println("Variables cargadas desde archivo .env")
		} else {
			log.Println("No se encontró archivo .env, usando solo variables del sistema")
		}
	} else {
		log.Println("Detectadas variables del sistema, se omite carga de archivo .env")
	}

	//Valida variable de entorno de puerto de BD
	dbPort, err := strconv.Atoi(os.Getenv("DB_PORT"))
	if err != nil {
		dbPort = 5432 //Valor por defecto
	}

	//Valida variable de entorno de puerto del servidor
	serverPort, err := strconv.Atoi(os.Getenv("AUTH_SERVER_PORT"))
	if err != nil {
		serverPort = 8080 //Valor por defecto
	}

	dbSSLMode := os.Getenv("DB_SSLMODE")
	if dbSSLMode == "" {
		dbSSLMode = "require" // Valor por defecto para RDS
	}

	AppConfig = EnvConfig{
		DBHost:     os.Getenv("DB_HOST"),
		DBPort:     dbPort,
		DBUser:     os.Getenv("DB_USER"),
		DBPassword: os.Getenv("DB_PASSWORD"),
		DBName:     os.Getenv("DB_NAME"),
		DBSSLMode:  dbSSLMode,
		ServerPort: serverPort,
	}

	log.Printf("Config cargado: host=%s user=%s db=%s port=%d",
		AppConfig.DBHost, AppConfig.DBUser, AppConfig.DBName, AppConfig.DBPort)
}
