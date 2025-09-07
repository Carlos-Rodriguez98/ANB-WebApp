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

	ServerPort int
}

var AppConfig EnvConfig

func LoadEnv() {
	prueba, _ := strconv.Atoi(os.Getenv("DB_HOST"))
	log.Printf("Validación DB_HOST: %s", prueba)
	//Carga del archivo .env si existe
	err := godotenv.Load()
	if err != nil {
		log.Println("No se pudo cargar .env, usando variables de entorno")
	}

	//Valida variable de entorno de puerto de BD
	dbPort, err := strconv.Atoi(os.Getenv("DB_PORT"))
	if err != nil {
		dbPort = 5432 //Valor por defecto
	}

	//Valida variable de entorno de puerto del servidor
	serverPort, err := strconv.Atoi(os.Getenv("SERVER_PORT"))
	if err != nil {
		serverPort = 8080 //Valor por defecto
	}

	AppConfig = EnvConfig{
		DBHost:     os.Getenv("DB_HOST"),
		DBPort:     dbPort,
		DBUser:     os.Getenv("DB_USER"),
		DBPassword: os.Getenv("DB_PASSWORD"),
		DBName:     os.Getenv("DB_NAME"),
		ServerPort: serverPort,
	}

	log.Printf("Config cargado: host=%s user=%s db=%s port=%d",
		AppConfig.DBHost, AppConfig.DBUser, AppConfig.DBName, AppConfig.DBPort)
}
