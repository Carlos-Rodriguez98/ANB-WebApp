package main

import (
	"ANB-WebApp/services/video-service/config"
	"ANB-WebApp/services/video-service/routes"
	"fmt"
	"log"
)

func main() {
	r := routes.SetupRouter()
	port := fmt.Sprintf(":%d", config.AppConfig.ServerPort)
	log.Printf("[video-service] escuchando en http://localhost%s", port)
	log.Fatal(r.Run(port))
}
