package services

import (
	"ANB-WebApp/services/auth-service/dto"
	"ANB-WebApp/services/auth-service/repository"
	"ANB-WebApp/services/auth-service/utils"
	"errors"
	"log"
)

// AuthenticationService maneja la lógica de negocio de inicio de sesión
type AuthenticationService struct {
	UserRepo *repository.UserRepository
}

func NewUserAutheticator(userRepo *repository.UserRepository) *AuthenticationService {
	return &AuthenticationService{UserRepo: userRepo}
}

// login de usuario
func (s *AuthenticationService) Login(input dto.LoginRequest) (*dto.LoginResponse, error) {
	log.Printf("DEBUG - Email recibido: '%q", input.Email)
	log.Printf("DEBUG - Password recibido: '%q", input.Password)

	//Se valida si el correo del usuario existe
	user, err := s.UserRepo.FindByEmail(input.Email)
	if err != nil {
		return nil, errors.New("credenciales inválidas - email")
	}

	//Se valida la contraseña
	if !utils.CheckPasswordHash(input.Password, user.Password) {
		return nil, errors.New("credenciales inválidas - password")
	}

	//Se realiza generación de JWT
	token, exp, err := utils.GenerateJWT(user.ID, user.Email)
	if err != nil {
		return nil, err
	}

	return &dto.LoginResponse{
		AccessToken: token,
		TokenType:   "Bearer",
		ExpiresIn:   exp,
	}, nil
}
