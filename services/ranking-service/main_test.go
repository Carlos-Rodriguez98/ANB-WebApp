package main

import (
	"database/sql"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestGetRanking(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		mockDB, mock, err := sqlmock.New()
		if err != nil {
			t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
		}
		defer mockDB.Close()

		db = mockDB

		rows := sqlmock.NewRows([]string{"user_id", "VotosAcumulados"}).
			AddRow(1, 100).
			AddRow(2, 95)

		mock.ExpectQuery(`
		SELECT v.user_id, COUNT(vo.vote_id) AS VotosAcumulados
		FROM "Videos" v
		JOIN "Votes" vo ON v.video_id = vo.video_id
		WHERE v.published = TRUE
		GROUP BY v.user_id
		ORDER BY VotosAcumulados DESC
	`).WillReturnRows(rows)

		r := gin.Default()
		r.GET("/api/public/ranking", getRanking)

		req, _ := http.NewRequest(http.MethodGet, "/api/public/ranking", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.JSONEq(t, `[{"jugador":1,"votos_acumulados":100},{"jugador":2,"votos_acumulados":95}]`, w.Body.String())
	})

	t.Run("db_error", func(t *testing.T) {
		mockDB, mock, err := sqlmock.New()
		if err != nil {
			t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
		}
		defer mockDB.Close()

		db = mockDB

		mock.ExpectQuery(`
		SELECT v.user_id, COUNT(vo.vote_id) AS VotosAcumulados
		FROM "Videos" v
		JOIN "Votes" vo ON v.video_id = vo.video_id
		WHERE v.published = TRUE
		GROUP BY v.user_id
		ORDER BY VotosAcumulados DESC
	`).WillReturnError(sql.ErrConnDone)

		r := gin.Default()
		r.GET("/api/public/ranking", getRanking)

		req, _ := http.NewRequest(http.MethodGet, "/api/public/ranking", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		assert.JSONEq(t, `{"error":"Error al buscar ranking"}`, w.Body.String())
	})
}
