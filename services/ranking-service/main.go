package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

// Estructura de PlayerRanking para respuesta JSON
type PlayerRanking struct {
	Jugador         int `json:"jugador"`
	VotosAcumulados int `json:"votos_acumulados"`
}

var db *sql.DB

func main() {
	// TODO: Verificar string de conexión al momento de integrar
	connStr := "user=user dbname=anb_db sslmode=disable"
	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Println(err)
	}
	defer db.Close()

	// Verificación de conexión
	err = db.Ping()
	if err != nil {
		log.Println(err)
	}

	r := gin.Default()
	r.GET("/api/public/ranking", getRanking)
	r.Run(":8081")
}

// Handler para ranking de jugadores
func getRanking(c *gin.Context) {
	rows, err := db.Query(`
		SELECT v.user_id, COUNT(vo.vote_id) AS VotosAcumulados
		FROM "Videos" v
		JOIN "Votes" vo ON v.video_id = vo.video_id
		WHERE v.published = TRUE
		GROUP BY v.user_id
		ORDER BY VotosAcumulados DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al buscar ranking"})
		return
	}
	defer rows.Close()

	ranking := []PlayerRanking{}
	for rows.Next() {
		var pr PlayerRanking
		if err := rows.Scan(&pr.Jugador, &pr.VotosAcumulados); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al escanear ranking"})
			return
		}
		ranking = append(ranking, pr)
	}

	c.JSON(http.StatusOK, ranking)
}