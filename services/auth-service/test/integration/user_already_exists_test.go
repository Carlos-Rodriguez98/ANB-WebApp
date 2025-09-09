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

func TestUserAlreadyExists(t *testing.T) {
	router := routes.SetupRouter() //Expone las rutas en gin

	//Signup
	signupBody := map[string]string{
		"first_name": "Test",
		"last_name":  "Signup",
		"email":      "testUserAlreadyExist@gmail.com",
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

	//Signup user again
	signupBody2 := map[string]string{
		"first_name": "Test",
		"last_name":  "Signup",
		"email":      "testUserAlreadyExist@gmail.com",
		"password1":  "dummy_password_for_tests_User_Already_Exists",
		"password2":  "dummy_password_for_tests_User_Already_Exists",
		"city":       "Bogotá",
		"country":    "Colombia",
	}
	body2, _ := json.Marshal(signupBody2)

	request2, _ := http.NewRequest("POST", "/api/auth/signup", bytes.NewBuffer(body2))
	request2.Header.Set("Content-Type", "application/json")
	response2 := httptest.NewRecorder()
	router.ServeHTTP(response2, request2)

	assert.Equal(t, 400, response2.Code)
}
