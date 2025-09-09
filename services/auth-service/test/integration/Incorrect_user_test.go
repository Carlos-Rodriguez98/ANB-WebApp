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

func TestLoginIncorrectUser(t *testing.T) {
	router := routes.SetupRouter() //Expone las rutas en gin
	//Login
	loginBody := map[string]string{
		"email":    "testIncorrectUser@gmail.com",
		"password": "dummy_password_for_tests",
	}
	body, _ := json.Marshal(loginBody)

	request, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(body))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	assert.Equal(t, 401, response.Code)

}
