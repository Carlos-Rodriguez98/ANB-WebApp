package utils_test

import (
	"ANB-WebApp/services/auth-service/utils"
	"testing"
)

func TestHashAndCheckPassword(t *testing.T) {
	password := "ContraSegur@12*"

	//Proceso para validar el funcionamiento del hash de contraseña
	hash, err := utils.HashPassword(password)
	if err != nil {
		t.Fatalf("No se pudo realizar el Hash de la contraseña: %v", err)
	}

	//Proceso para validar la verificación (match) de hash vs password
	if !utils.CheckPasswordHash(password, hash) {
		t.Fatalf("La contraseña no coincide con el Hash")
	}
}
