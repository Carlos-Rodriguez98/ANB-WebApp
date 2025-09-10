package routes

import (
	"ANB-WebApp/services/video-service/controllers"
	"ANB-WebApp/services/video-service/middleware"

	"github.com/gin-gonic/gin"
)

func ServiceRoutes(r *gin.Engine, vc *controllers.VideoController) {
	api := r.Group("/api")
	{
		protected := api.Group("/videos")
		protected.Use(middleware.AuthRequired())
		{
			protected.POST("/upload", vc.Upload)      // (3)
			protected.GET("", vc.ListMine)            // (4)
			protected.GET("/:video_id", vc.GetDetail) // (5)
			protected.DELETE("/:video_id", vc.Delete) // (6)
		}
	}
}
