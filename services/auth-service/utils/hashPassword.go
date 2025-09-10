package utils

import (
	"golang.org/x/crypto/bcrypt"
)

// Hashear la contraseña para proteger la información
func HashPassword(password string) (string, error) {
	const cost = 12 //El costo recomendado es 10 pero se utilizará 12 para mayor seguridad
	bytes, error := bcrypt.GenerateFromPassword([]byte(password), cost)
	if error != nil {
		return "", error
	}
	return string(bytes), nil
}

// Valida la contraseña ingresada mediante la comparación con el Hash de BD
func CheckPasswordHash(password, hash string) bool {
	error := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return error == nil
}
