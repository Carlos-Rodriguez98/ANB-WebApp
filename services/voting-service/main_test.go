package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
)

func setupRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.Default()
	public := r.Group("/api/public")
	{
		public.GET("/videos", getPublicVideos)
		public.POST("/login", generateToken)
	}

	private := r.Group("/api/private")
	private.Use(authMiddleware())
	{
		private.POST("/videos/:video_id/vote", voteForVideo)
	}
	return r
}

func TestGetPublicVideos(t *testing.T) {
	mockDB, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	defer mockDB.Close()
	db = mockDB

	t.Run("success", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"video_id", "user_id", "title", "published", "votes"}).
			AddRow("550e8400-e29b-41d4-a716-446655440001", 1, "Test Video 1", true, 10).
			AddRow("550e8400-e29b-41d4-a716-446655440002", 2, "Test Video 2", true, 5)

		mock.ExpectQuery(`SELECT v.video_id, v.user_id, v.title, v.published, COUNT(vo.vote_id) as votes FROM "Videos" v LEFT JOIN "Votes" vo ON v.video_id = vo.video_id WHERE v.published = TRUE GROUP BY v.video_id ORDER BY votes DESC`).WillReturnRows(rows)

		r := setupRouter()

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/public/videos", nil)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.JSONEq(t, `[{"id":"550e8400-e29b-41d4-a716-446655440001","jugador_id":1,"titulo":"Test Video 1","votos":10,"published":true},{"id":"550e8400-e29b-41d4-a716-446655440002","jugador_id":2,"titulo":"Test Video 2","votos":5,"published":true}]`, w.Body.String())
	})

	t.Run("db_error", func(t *testing.T) {
		mock.ExpectQuery(".*").WillReturnError(sql.ErrConnDone)

		r := setupRouter()

		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/public/videos", nil)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
	})
}

func TestGenerateToken(t *testing.T) {
	mockDB, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	jwtKey = []byte("test_secret")
	defer mockDB.Close()
	db = mockDB

	t.Run("success", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"rol"}).AddRow("votante")
		mock.ExpectQuery(`SELECT "rol" FROM "User" WHERE user_id = \$1`).WithArgs(1).WillReturnRows(rows)

		r := setupRouter()

		w := httptest.NewRecorder()
		body := `{"user_id":1}`
		req, _ := http.NewRequest("POST", "/api/public/login", bytes.NewBufferString(body))
		req.Header.Set("Content-Type", "application/json")
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		var response map[string]string
		json.Unmarshal(w.Body.Bytes(), &response)
		assert.NotEmpty(t, response["token"])
	})

	t.Run("user_not_found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "rol" FROM "User" WHERE user_id = \$1`).WithArgs(1).WillReturnError(sql.ErrNoRows)

		r := setupRouter()

		w := httptest.NewRecorder()
		body := `{"user_id":1}`
		req, _ := http.NewRequest("POST", "/api/public/login", bytes.NewBufferString(body))
		req.Header.Set("Content-Type", "application/json")
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

func TestVoteForVideo(t *testing.T) {
	mockDB, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	jwtKey = []byte("test_secret")
	defer mockDB.Close()
	db = mockDB

	// Helper to generate a token
	generateTestToken := func(userID int, rol string) string {
		expirationTime := time.Now().Add(24 * time.Hour)
		claims := &Claims{
			UserID: userID,
			Rol:    rol,
			RegisteredClaims: jwt.RegisteredClaims{
				ExpiresAt: jwt.NewNumericDate(expirationTime),
			},
		}
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
		tokenString, _ := token.SignedString(jwtKey)
		return tokenString
	}

	t.Run("success", func(t *testing.T) {
		mock.ExpectQuery(`SELECT published FROM "Videos" WHERE video_id = \$1`).WithArgs("550e8400-e29b-41d4-a716-446655440001").WillReturnRows(sqlmock.NewRows([]string{"published"}).AddRow(true))
		mock.ExpectQuery(`SELECT COUNT(\*\) FROM "Votes" WHERE video_id = \$1 AND user_id = \$2`).WithArgs("550e8400-e29b-41d4-a716-446655440001", 1).WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
		mock.ExpectExec(`INSERT INTO "Votes" (video_id, user_id) VALUES (\$1, \$2)`).WithArgs("550e8400-e29b-41d4-a716-446655440001", 1).WillReturnResult(sqlmock.NewResult(1, 1))

		r := setupRouter()

		w := httptest.NewRecorder()
		token := generateTestToken(1, "votante")
		req, _ := http.NewRequest("POST", "/api/private/videos/550e8400-e29b-41d4-a716-446655440001/vote", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
	})

	t.Run("invalid_role", func(t *testing.T) {
		r := setupRouter()

		w := httptest.NewRecorder()
		token := generateTestToken(1, "not_a_voter")
		req, _ := http.NewRequest("POST", "/api/private/videos/550e8400-e29b-41d4-a716-446655440001/vote", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusForbidden, w.Code)
	})

	t.Run("already_voted", func(t *testing.T) {
		mock.ExpectQuery(`SELECT published FROM "Videos" WHERE video_id = \$1`).WithArgs("550e8400-e29b-41d4-a716-446655440001").WillReturnRows(sqlmock.NewRows([]string{"published"}).AddRow(true))
		mock.ExpectQuery(`SELECT COUNT(\*\) FROM "Votes" WHERE video_id = \$1 AND user_id = \$2`).WithArgs("550e8400-e29b-41d4-a716-446655440001", 1).WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

		r := setupRouter()

		w := httptest.NewRecorder()
		token := generateTestToken(1, "votante")
		req, _ := http.NewRequest("POST", "/api/private/videos/550e8400-e29b-41d4-a716-446655440001/vote", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusConflict, w.Code)
	})
}
