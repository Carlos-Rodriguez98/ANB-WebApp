package services

import (
	"ANB-WebApp/services/auth-service/dto"
	"ANB-WebApp/services/auth-service/models"
	"ANB-WebApp/services/auth-service/repository"
	"ANB-WebApp/services/auth-service/utils"
	"errors"
)

// RegistrationService maneja la lógica de negocio de registro de usuarios
type RegistrationService struct {
	UserRepo *repository.UserRepository
}

func NewRegistrationService(userRepo *repository.UserRepository) *RegistrationService {
	return &RegistrationService{UserRepo: userRepo}
}

// Registro de usuario
func (s *RegistrationService) RegisterUser(input dto.UserRegisterRequest) error {
	if input.Password1 != input.Password2 {
		return errors.New("las contraseñas ingresadas no coinciden")
	}

	//Se valida si el email ya existe
	_, err := s.UserRepo.FindByEmail(input.Email)
	if err == nil {
		return errors.New("el email ya se encuentra registrado")
	}

	//Hashear la contraseña
	hashedPassword, _ := utils.HashPassword(input.Password1)

	user := models.User{
		FirstName: input.FirstName,
		LastName:  input.LastName,
		Email:     input.Email,
		Password:  hashedPassword,
		City:      input.City,
		Country:   input.Country,
	}

	return s.UserRepo.Create(&user)

}
