package routes

import (
	"ANB-WebApp/services/auth-service/controllers"

	"github.com/gin-gonic/gin"
)

func ServiceRoutes(route *gin.Engine, registerController *controllers.RegisterController, loginController *controllers.LoginController) {
	// Health check endpoint (no requiere autenticación)
	route.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "auth"})
	})

	api := route.Group("/api/auth")
	{
		//Endpoint para registro de usuario
		api.POST("/signup", registerController.Register)
		//Endpoint para inicio de sesión
		api.POST("/login", loginController.Login)
	}

}
