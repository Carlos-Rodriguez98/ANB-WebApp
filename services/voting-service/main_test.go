package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"anb-app/voting-service/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	public := r.Group("/api/public")
	{
		public.GET("/videos", getPublicVideos)
		public.GET("/videos/:video_id", getPublicVideoByID)
		public.POST("/videos/:video_id/vote", voteForVideo)
	}
	return r
}

// setupTestDB inicializa una base de datos SQLite en memoria para tests
func setupTestDB(t *testing.T) *gorm.DB {
	testDB, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("Error al abrir base de datos de prueba: %v", err)
	}

	// Crear tablas necesarias
	testDB.Exec(`
		CREATE TABLE users (
			user_id INTEGER PRIMARY KEY AUTOINCREMENT,
			first_name TEXT NOT NULL,
			last_name TEXT NOT NULL,
			email TEXT NOT NULL UNIQUE,
			password TEXT NOT NULL,
			city TEXT NOT NULL,
			country TEXT NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	`)

	testDB.Exec(`
		CREATE TABLE videos (
			video_id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			title TEXT NOT NULL,
			original_path TEXT,
			processed_path TEXT,
			status TEXT NOT NULL,
			uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			processed_at DATETIME,
			published BOOLEAN DEFAULT FALSE,
			published_at DATETIME,
			FOREIGN KEY (user_id) REFERENCES users(user_id)
		)
	`)

	// AutoMigrate para tabla de votos
	if err := testDB.AutoMigrate(&models.Vote{}); err != nil {
		t.Fatalf("Error en AutoMigrate: %v", err)
	}

	return testDB
}

func TestGetPublicVideos(t *testing.T) {
	// Configurar base de datos de prueba
	testDB := setupTestDB(t)
	db = testDB

	t.Run("success", func(t *testing.T) {
		// Insertar datos de prueba
		testDB.Exec(`
			INSERT INTO users (user_id, first_name, last_name, email, password, city, country) 
			VALUES (1, 'Juan', 'Perez', 'juan@test.com', 'hash', 'Bogotá', 'Colombia'),
			       (2, 'Maria', 'Lopez', 'maria@test.com', 'hash', 'Medellín', 'Colombia')
		`)

		testDB.Exec(`
			INSERT INTO videos (video_id, user_id, title, status, published) 
			VALUES (101, 1, 'Test Video 1', 'processed', 1),
			       (102, 2, 'Test Video 2', 'processed', 1)
		`)

		// Insertar votos
		testDB.Create(&models.Vote{VideoID: 101, UserID: 2})
		testDB.Create(&models.Vote{VideoID: 101, UserID: 1})

		r := setupRouter()
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/public/videos", nil)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		
		// Verificar que la respuesta contiene los videos
		var videos []map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &videos)
		assert.Equal(t, 2, len(videos))
		assert.Equal(t, "Test Video 1", videos[0]["title"])
		assert.Equal(t, float64(2), videos[0]["votes"]) // JSON unmarshals numbers as float64

		// Limpiar
		testDB.Exec("DELETE FROM votes")
		testDB.Exec("DELETE FROM videos")
		testDB.Exec("DELETE FROM users")
	})

	t.Run("empty_list", func(t *testing.T) {
		r := setupRouter()
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/public/videos", nil)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		var videos []map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &videos)
		assert.Equal(t, 0, len(videos))
	})
}

func TestGenerateToken(t *testing.T) {
	t.Skip("El voting-service no genera tokens JWT, esto lo hace el auth-service")
}

func TestVoteForVideo(t *testing.T) {
	testDB := setupTestDB(t)
	db = testDB

	// Configurar JWT_SECRET para los tests
	jwtSecret := "test_secret_key_12345"
	os.Setenv("JWT_SECRET", jwtSecret)

	// Helper to generate a token compatible with auth-service
	generateTestToken := func(userID int64) string {
		expirationTime := time.Now().Add(24 * time.Hour)
		claims := jwt.MapClaims{
			"user_id":    userID,
			"expiration": expirationTime.Unix(),
		}
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
		tokenString, _ := token.SignedString([]byte(jwtSecret))
		return tokenString
	}

	t.Run("success", func(t *testing.T) {
		// Insertar datos de prueba
		testDB.Exec(`
			INSERT INTO users (user_id, first_name, last_name, email, password, city, country) 
			VALUES (1, 'Test', 'User', 'test@test.com', 'hash', 'City', 'Country')
		`)
		testDB.Exec(`
			INSERT INTO videos (video_id, user_id, title, status, published) 
			VALUES (101, 1, 'Test Video', 'processed', 1)
		`)

		r := setupRouter()
		w := httptest.NewRecorder()
		token := generateTestToken(1)
		req, _ := http.NewRequest("POST", "/api/public/videos/101/vote", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		var response map[string]string
		json.Unmarshal(w.Body.Bytes(), &response)
		assert.Equal(t, "Voto exitoso.", response["message"])

		// Limpiar
		testDB.Exec("DELETE FROM votes")
		testDB.Exec("DELETE FROM videos")
		testDB.Exec("DELETE FROM users")
	})

	t.Run("missing_auth", func(t *testing.T) {
		r := setupRouter()
		w := httptest.NewRecorder()
		// No enviar token de autenticación
		req, _ := http.NewRequest("POST", "/api/public/videos/101/vote", nil)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		var response map[string]string
		json.Unmarshal(w.Body.Bytes(), &response)
		assert.Equal(t, "Falta de autenticación.", response["error"])
	})

	t.Run("already_voted", func(t *testing.T) {
		// Insertar datos de prueba
		testDB.Exec(`
			INSERT INTO users (user_id, first_name, last_name, email, password, city, country) 
			VALUES (1, 'Test', 'User', 'test@test.com', 'hash', 'City', 'Country')
		`)
		testDB.Exec(`
			INSERT INTO videos (video_id, user_id, title, status, published) 
			VALUES (101, 1, 'Test Video', 'processed', 1)
		`)
		// Insertar voto previo
		testDB.Create(&models.Vote{VideoID: 101, UserID: 1})

		r := setupRouter()
		w := httptest.NewRecorder()
		token := generateTestToken(1)
		req, _ := http.NewRequest("POST", "/api/public/videos/101/vote", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		var response map[string]string
		json.Unmarshal(w.Body.Bytes(), &response)
		assert.Equal(t, "Ya has votado por este video.", response["error"])

		// Limpiar
		testDB.Exec("DELETE FROM votes")
		testDB.Exec("DELETE FROM videos")
		testDB.Exec("DELETE FROM users")
	})

	t.Run("video_not_found", func(t *testing.T) {
		r := setupRouter()
		w := httptest.NewRecorder()
		token := generateTestToken(1)
		req, _ := http.NewRequest("POST", "/api/public/videos/999/vote", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}
