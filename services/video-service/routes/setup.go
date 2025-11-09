package routes

import (
	"ANB-WebApp/services/video-service/config"
	"ANB-WebApp/services/video-service/controllers"
	"ANB-WebApp/services/video-service/repository"
	"ANB-WebApp/services/video-service/services"
	"ANB-WebApp/services/video-service/storage"
	"log"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	config.LoadEnv()

	db, err := config.ConnectDatabase()
	if err != nil {
		log.Fatal(err)
	}

	repo := repository.NewVideoRepository(db)
	var store storage.Storage
	if config.AppConfig.StorageMode == "s3" {
		s3Store, err := storage.NewS3Storage()
		if err != nil {
			log.Fatal("Error inicializando S3:", err)
		}
		store = s3Store
	} else {
		store = storage.NewLocalStorage()
	}
	svc := services.NewVideoService(repo, store)
	vc := controllers.NewVideoController(svc)

	r := gin.Default()

	// Servir archivos estáticos (para URLs públicas locales)
	// Mapea /static/* a STORAGE_BASE_PATH/static
	r.Static("/static", filepath.Join(config.AppConfig.StorageBasePath, "static"))

	ServiceRoutes(r, vc)
	return r
}
