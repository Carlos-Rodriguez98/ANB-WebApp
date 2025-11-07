package main

import (
	"ANB-WebApp/services/video-service/controllers"
	"ANB-WebApp/services/video-service/repository"
	"ANB-WebApp/services/video-service/services"
	"ANB-WebApp/services/video-service/storage"
	"ANB-WebApp/services/video-service/tasks"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	tasks.InitClient()
	defer tasks.CloseClient()

	route := SetupServer()
	log.Fatal(route.Run(fmt.Sprintf(":%s", os.Getenv("SERVER_PORT"))))
}

func SetupServer() *gin.Engine {

	database, err := ConnectDatabase()
	if err != nil {
		log.Fatal(err)
	}

	store := storage.NewLocalStorage()
	repository := repository.NewVideoRepository(database)
	services := services.NewVideoService(repository, store)
	controllers := controllers.NewVideoController(services)

	route := gin.Default()
	route.MaxMultipartMemory = 32 << 20
	route.Use(MaxBodySizeMiddleware(100 << 20))

	route.Static("/static", os.Getenv("STORAGE_BASE_PATH"))

	api := route.Group("/api/videos")
	api.Use(AuthenticationMiddleware())
	{
		api.POST("/upload", controllers.Upload)
		api.GET("", controllers.ListMine)
		api.GET("/:video_id", controllers.GetDetail)
		api.DELETE("/:video_id", controllers.Delete)
		api.POST("/:video_id/publish", controllers.Publish)
	}

	return route
}

func ConnectDatabase() (*gorm.DB, error) {
	DSN := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=America/Bogota search_path=app",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"), os.Getenv("DB_NAME"), os.Getenv("DB_PORT"),
	)

	var database *gorm.DB
	var err error

	for i := 1; i <= 5; i++ {
		database, err = gorm.Open(postgres.Open(DSN), &gorm.Config{})
		if err == nil {
			return database, nil
		}
		time.Sleep(3 * time.Second)
	}

	return nil, fmt.Errorf("no se pudo conectar a la base de datos: %v", err)
}

func AuthenticationMiddleware() gin.HandlerFunc {
	return func(context *gin.Context) {
		auth := context.GetHeader("Authorization")
		if !strings.HasPrefix(strings.ToLower(auth), "bearer ") {
			context.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing bearer token"})
			return
		}

		tokenStr := strings.TrimSpace(auth[7:])
		token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
			return []byte(os.Getenv("JWT_SECRET")), nil
		})

		if err != nil || !token.Valid {
			context.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			context.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid claims"})
			return
		}

		userIdFloat, ok := claims["user_id"].(float64)
		if !ok {
			context.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "user_id claim missing"})
			return
		}
		context.Set("user_id", uint(userIdFloat))
		context.Next()
	}
}

func MaxBodySizeMiddleware(maxBytes int64) gin.HandlerFunc {
	return func(context *gin.Context) {

		if context.Request.ContentLength > maxBytes {
			context.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "Archivo muy grande (max 100MB)"})
			return
		}

		context.Request.Body = http.MaxBytesReader(context.Writer, context.Request.Body, maxBytes)

		context.Next()
	}
}
