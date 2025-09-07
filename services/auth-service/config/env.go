package config

import (
	"log"
	"os"
	"strconv"
	"strings"

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
	envFile := os.Getenv("ENV_FILE")

	if envFile == "" {
		if strings.HasSuffix(os.Args[0], ".test") {
			envFile = ".env.test"
		} else {
			envFile = ".env"
		}
	}
	log.Printf("envFile: %s", envFile)

	//Carga del archivo .env si existe
	if err := godotenv.Load(envFile); err == nil {
		log.Printf("Variables cargadas desde %s", envFile)
	} else if err := godotenv.Load("../infra/.env"); err == nil {
		log.Printf("Variables cargadas desde infra/.env")
	} else {
		log.Printf("No se encontró archivo .env, usando variables del sistema")
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
