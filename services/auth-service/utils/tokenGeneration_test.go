package utils_test

import (
	"ANB-WebApp/services/auth-service/utils"
	"testing"
)

func TestGenerateJWT(t *testing.T) {
	userID := 1
	email := "test-jwt@gmail.com"

	//Proceso para validar el funcionamiento de generación de JWT
	_, _, err := utils.GenerateJWT(uint(userID), email)
	if err != nil {
		t.Fatalf("No se pudo generar el token: %v", err)
	}

}
