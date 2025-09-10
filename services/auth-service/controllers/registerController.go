package controllers

import (
	"ANB-WebApp/services/auth-service/dto"
	"ANB-WebApp/services/auth-service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// RegisterController maneja el endpoint de registro
type RegisterController struct {
	RegistrationService *services.RegistrationService
}

// Constructor: recibe el RegistrationService
func NewRegisterController(registrationService *services.RegistrationService) *RegisterController {
	return &RegisterController{RegistrationService: registrationService}
}

// Manejo de POST /api/auth/signup
func (ctrl *RegisterController) Register(c *gin.Context) {
	var request dto.UserRegisterRequest

	//Se valida el JSON de entrada
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	//Llamado al servicio de registro de usuarios
	if err := ctrl.RegistrationService.RegisterUser(request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	//Responde al cliente
	c.JSON(http.StatusCreated, gin.H{"message": "Usuario creado exitosamente."})

}
