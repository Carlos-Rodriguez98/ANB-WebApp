//go:build integration

package integration_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"ANB-WebApp/services/auth-service/routes"

	"github.com/stretchr/testify/assert"
)

func TestSingupAndLogin(t *testing.T) {
	router := routes.SetupRouter() //Expone las rutas en gin

	//Signup
	signupBody := map[string]string{
		"first_name": "Test",
		"last_name":  "Signup",
		"email":      "testSignup@gmail.com",
		"password1":  "dummy_password_for_tests",
		"password2":  "dummy_password_for_tests",
		"city":       "Bogotá",
		"country":    "Colombia",
	}
	body, _ := json.Marshal(signupBody)

	request, _ := http.NewRequest("POST", "/api/auth/signup", bytes.NewBuffer(body))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	assert.Equal(t, 201, response.Code)

	//Login
	loginBody := map[string]string{
		"email":    "testSignup@gmail.com",
		"password": "ContraSegur@123*",
	}
	body, _ = json.Marshal(loginBody)

	request, _ = http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(body))
	request.Header.Set("Content-Type", "application/json")
	response = httptest.NewRecorder()
	router.ServeHTTP(response, request)

	assert.Equal(t, 200, response.Code)
}
