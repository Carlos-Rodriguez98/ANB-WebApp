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
	localStore := storage.NewLocalStorage()
	s3Store := storage.NewS3Storage(config.AppConfig.S3BucketName, config.AppConfig.S3Prefix)
	multiStore := storage.NewMultiStorage(localStore, s3Store, true) // Usar S3
	svc := services.NewVideoService(repo, multiStore)
	vc := controllers.NewVideoController(svc)

	r := gin.Default()

	// Servir archivos estáticos (para URLs públicas locales)
	// Mapea /static/* a STORAGE_BASE_PATH/static
	r.Static("/static", filepath.Join(config.AppConfig.StorageBasePath, "static"))

	ServiceRoutes(r, vc)
	return r
}
