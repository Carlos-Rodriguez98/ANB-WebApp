package repository

import (
	"ANB-WebApp/services/auth-service/models"
	"strings"

	"gorm.io/gorm"
)

// UserRepository maneja las consultas SQL relacionadas a los usuarios
type UserRepository struct {
	DB *gorm.DB
}

// Constructor
func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{DB: db}
}

// Create - Guarda un nuevo usuario en la BD
func (r *UserRepository) Create(user *models.User) error {
	user.Email = strings.ToLower(strings.TrimSpace(user.Email))
	return r.DB.Create(user).Error
}

// Busca el usuario por su email
func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	var user models.User
	clean := strings.ToLower(strings.TrimSpace(email))

	if err := r.DB.Where("Lower(email) = ?", clean).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}
