package main

import (
	"ANB-WebApp/services/auth-service/config"
	"ANB-WebApp/services/auth-service/routes"
	"fmt"
	"log"
)

func main() {
	//Crear router con todas las configuraciones
	r := routes.SetupRouter()

	//Puerto del servidor
	port := fmt.Sprintf(":%d", config.AppConfig.ServerPort)

	//Iniciar servidor
	log.Printf("Servidor corriendo en http://localhost%s", port)
	if error := r.Run(port); error != nil {
		log.Fatal(error)
	}

}
