package routes

import (
	"ANB-WebApp/services/video-service/config"
	"ANB-WebApp/services/video-service/controllers"
	"ANB-WebApp/services/video-service/repository"
	"ANB-WebApp/services/video-service/services"
	"ANB-WebApp/services/video-service/storage"
	"log"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	config.LoadEnv()

	db, err := config.ConnectDatabase()
	if err != nil {
		log.Fatal(err)
	}

	repo := repository.NewVideoRepository(db)
	store := storage.NewLocalStorage()
	svc := services.NewVideoService(repo, store)
	vc := controllers.NewVideoController(svc)

	r := gin.Default()

	// Servir archivos estáticos (para URLs públicas locales)
	// Mapea /static/* a STORAGE_BASE_PATH
	r.Static("/static", config.AppConfig.StorageBasePath)

	ServiceRoutes(r, vc)
	return r
}
