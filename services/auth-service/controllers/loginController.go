package controllers

import (
	"ANB-WebApp/services/auth-service/dto"
	"ANB-WebApp/services/auth-service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// LoginController maneja el endpoint de login
type LoginController struct {
	AuthenticationService *services.AuthenticationService
}

// Constructor
func NewLoginController(AuthService *services.AuthenticationService) *LoginController {
	return &LoginController{AuthenticationService: AuthService}
}

// Manejo POST /api/auth/login
func (ctrl *LoginController) Login(c *gin.Context) {
	var request dto.LoginRequest

	//Se valida el JSON de la solicitud
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	res, err := ctrl.AuthenticationService.Login(request)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, res)
}
