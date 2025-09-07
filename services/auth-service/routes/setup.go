package routes

import (
	"ANB-WebApp/services/auth-service/config"
	"ANB-WebApp/services/auth-service/controllers"
	"ANB-WebApp/services/auth-service/repository"
	"ANB-WebApp/services/auth-service/services"
	"log"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	//Inicializar configuraciones
	//Variables de entorno
	config.LoadEnv()

	//Conectar a la base de datos usando dbConnection
	db, err := config.ConnectDatabase()
	//Valida si se presentó un error
	if err != nil {
		log.Fatal(err)
	}

	//El repositorio usa la conexión global
	userRepo := repository.NewUserRepository(db)

	//Servicios
	registrationService := services.NewRegistrationService(userRepo)
	authenticationService := services.NewUserAutheticator(userRepo)

	//Controladores
	registerController := controllers.NewRegisterController(registrationService)
	loginController := controllers.NewLoginController(authenticationService)

	//Inicializar Gin - Registrar rutas
	r := gin.Default()
	ServiceRoutes(r, registerController, loginController)

	return r
}
