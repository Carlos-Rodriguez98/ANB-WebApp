package routes

import (
	"ANB-WebApp/services/auth-service/controllers"

	"github.com/gin-gonic/gin"
)

func ServiceRoutes(route *gin.Engine, registerController *controllers.RegisterController, loginController *controllers.LoginController) {
	api := route.Group("/api/auth")
	{
		//Endpoint para registro de usuario
		api.POST("/signup", registerController.Register)
		//Endpoint para inicio de sesión
		api.POST("/login", loginController.Login)
	}

}
